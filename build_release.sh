#!/bin/bash

# =============================================================================
# MLX for All - Release Build Script
# =============================================================================
# Script unifié pour :
# 1. Nettoyer les anciens builds
# 2. Créer l'icône .icns
# 3. Construire l'application en mode Release
# 4. Créer un disque image (.dmg) professionnel
# 5. Préparer pour le release GitHub
# =============================================================================

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT_NAME="MLXForAll"
APP_NAME="MLX for All"
BUNDLE_ID="com.mrflappy0.MLXForAll"

# Version - peut être écrasée par argument ou variable d'environnement
VERSION="${1:-${MLX_VERSION:-2.0.0}}"

# Chemins
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/Release"
APP_PATH="$RELEASE_DIR/$PROJECT_NAME.app"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$DMG_DIR/$PROJECT_NAME-$VERSION.dmg"
TEMP_DMG="$DMG_DIR/temp.dmg"

# Ressources
ICON_PATH="$PROJECT_DIR/Resources/AppIcon.icns"
BACKGROUND_IMAGE="$PROJECT_DIR/Resources/DMGBackground.png"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Fonctions utilitaires ---
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[MLX Release] ${message}${NC}"
}

print_error() {
    print_status "$RED" "❌ $1"
}

print_success() {
    print_status "$GREEN" "✅ $1"
}

print_info() {
    print_status "$BLUE" "ℹ️ $1"
}

print_warning() {
    print_status "$YELLOW" "⚠️ $1"
}

print_header() {
    print_status "$PURPLE" "=== $1 ==="
}

print_subheader() {
    print_status "$CYAN" "--- $1 ---"
}

# --- Vérification des dépendances ---
check_dependencies() {
    print_header "Vérification des dépendances"
    
    local missing_deps=0
    
    # Vérifier Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools non trouvé."
        missing_deps=$((missing_deps + 1))
    else
        print_success "Xcode command line tools: OK"
    fi
    
    # Vérifier swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift non trouvé."
        missing_deps=$((missing_deps + 1))
    else
        local swift_version=$(swift --version | head -n1)
        print_success "Swift: $swift_version"
    fi
    
    # Vérifier hdiutil
    if ! command -v hdiutil &> /dev/null; then
        print_error "hdiutil non trouvé."
        missing_deps=$((missing_deps + 1))
    else
        print_success "hdiutil: OK"
    fi
    
    # Vérifier create-dmg (optionnel mais recommandé)
    if ! command -v create-dmg &> /dev/null; then
        print_warning "create-dmg non installé. Installation recommandée pour une meilleure mise en page."
        print_info "Pour l'installer: brew install create-dmg"
        USE_CREATE_DMG=false
    else
        print_success "create-dmg: OK"
        USE_CREATE_DMG=true
    fi
    
    # Vérifier iconutil
    if ! command -v iconutil &> /dev/null; then
        print_warning "iconutil non trouvé. Les icônes ne pourront pas être générées."
        USE_ICONUTIL=false
    else
        print_success "iconutil: OK"
        USE_ICONUTIL=true
    fi
    
    if [ $missing_deps -gt 0 ]; then
        print_error "$missing_deps dépendance(s) manquante(s)."
        exit 1
    fi
    
    print_success "Toutes les dépendances nécessaires sont disponibles."
}

# --- Nettoyage ---
clean_build() {
    print_header "Nettoyage des anciens builds"
    
    rm -rf "$BUILD_DIR"
    mkdir -p "$RELEASE_DIR"
    mkdir -p "$DMG_DIR"
    
    print_success "Nettoyage terminé."
}

# --- Création de l'icône ---
create_icon() {
    print_header "Création de l'icône .icns"
    
    if [ ! -f "$ICON_PATH" ]; then
        print_info "Création de l'icône à partir des ressources..."
        
        # Vérifier si on a une image source
        SOURCE_IMAGE="$PROJECT_DIR/Resources/Images/app_icon_1024.png"
        
        if [ -f "$SOURCE_IMAGE" ]; then
            print_info "Utilisation de l'image source: $SOURCE_IMAGE"
        else
            # Créer une image par défaut
            print_info "Création d'une image source par défaut..."
            mkdir -p "$PROJECT_DIR/Resources/Images"
            
            # Utiliser le script de création d'icône
            if [ -f "$PROJECT_DIR/create_icon.icns.sh" ]; then
                cd "$PROJECT_DIR"
                ./create_icon.icns.sh
                cd "$SCRIPT_DIR"
            else
                print_warning "Impossible de créer l'icône automatiquement."
                print_info "Veuillez placer une image 1024x1024 dans Resources/Images/app_icon_1024.png"
                return
            fi
        fi
        
        if [ -f "$ICON_PATH" ]; then
            print_success "Icône créée: $ICON_PATH"
        else
            print_warning "L'icône n'a pas pu être créée. Utilisation de l'icône par défaut du système."
        fi
    else
        print_success "Icône existante trouvée: $ICON_PATH"
    fi
}

# --- Construction de l'application ---
build_app() {
    print_header "Construction de l'application"
    
    cd "$PROJECT_DIR"
    
    print_info "Configuration: Release, Architecture: arm64"
    
    # Utiliser swift build pour construire le projet
    swift build -c release --arch arm64 \
        --static-swift-stdlib \
        -Xlinker -rpath -Xlinker @executable_path/../lib \
        -Xswiftc -cross-module-optimization \
        -Xswiftc -O
    
    # Vérifier que l'application a été construite
    SOURCE_APP="$PROJECT_DIR/.build/arm64-apple-macosx/release/$PROJECT_NAME.app"
    
    if [ ! -d "$SOURCE_APP" ]; then
        print_error "Échec de la construction de l'application."
        print_info "Vérifiez que le projet compile correctement avec: swift build -c release --arch arm64"
        exit 1
    fi
    
    # Copier l'application dans le dossier de build
    cp -R "$SOURCE_APP" "$APP_PATH"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "Échec de la copie de l'application."
        exit 1
    fi
    
    print_success "Application construite: $APP_PATH"
}

# --- Configuration de l'application ---
configure_app() {
    print_header "Configuration de l'application"
    
    # Copier l'icône dans le bundle
    if [ -f "$ICON_PATH" ]; then
        ICONS_DIR="$APP_PATH/Contents/Resources"
        mkdir -p "$ICONS_DIR"
        cp "$ICON_PATH" "$ICONS_DIR/AppIcon.icns"
        print_success "Icône copiée dans le bundle"
    fi
    
    # Mettre à jour Info.plist si nécessaire
    INFO_PLIST="$APP_PATH/Contents/Info.plist"
    if [ -f "$INFO_PLIST" ]; then
        # Mettre à jour la version
        defaults write "$INFO_PLIST" CFBundleShortVersionString "$VERSION"
        defaults write "$INFO_PLIST" CFBundleVersion "$VERSION"
        print_success "Version mise à jour dans Info.plist: $VERSION"
    fi
    
    # Vérifier la structure du bundle
    if [ -d "$APP_PATH/Contents/MacOS" ]; then
        print_success "Structure du bundle vérifiée"
    else
        print_warning "Structure du bundle inhabituelle"
    fi
}

# --- Création du .dmg ---
create_dmg() {
    print_header "Création du .dmg"
    
    # Créer un dossier temporaire pour le contenu
    TEMP_CONTENT="$DMG_DIR/dmg_content"
    rm -rf "$TEMP_CONTENT"
    mkdir -p "$TEMP_CONTENT"
    
    # Copier l'application
    cp -R "$APP_PATH" "$TEMP_CONTENT/"
    
    # Créer un raccourci vers /Applications
    ln -s /Applications "$TEMP_CONTENT/Applications"
    
    if [ "$USE_CREATE_DMG" = true ]; then
        print_info "Utilisation de create-dmg pour une mise en page optimisée..."
        
        # Créer un fond pour le DMG si nécessaire
        if [ ! -f "$BACKGROUND_IMAGE" ]; then
            # Créer un fond simple
            mkdir -p "$PROJECT_DIR/Resources"
            python3 << 'EOF'
from PIL import Image, ImageDraw

# Créer une image 600x400
img = Image.new('RGB', (600, 400), (240, 240, 240))
draw = ImageDraw.Draw(img)

# Ajouter un léger dégradé
for y in range(400):
    color = int(240 - (y / 400) * 20)
    draw.line([(0, y), (600, y)], fill=(color, color, color))

img.save("$PROJECT_DIR/Resources/DMGBackground.png", 'PNG')
EOF
            BACKGROUND_IMAGE="$PROJECT_DIR/Resources/DMGBackground.png"
        fi
        
        create-dmg \
            --volname "$PROJECT_NAME" \
            --volicon "$ICON_PATH" \
            --background "$BACKGROUND_IMAGE" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "$PROJECT_NAME.app" 150 190 \
            --icon "Applications" 450 190 \
            --app-drop-link 450 190 \
            --no-internet-enable \
            "$DMG_PATH" \
            "$TEMP_CONTENT"
    else
        print_info "Utilisation de hdiutil..."
        
        hdiutil create -volname "$PROJECT_NAME" \
            -srcfolder "$TEMP_CONTENT" \
            -ov -format UDZO \
            -fs HFS+ \
            "$DMG_PATH"
    fi
    
    # Nettoyer
    rm -rf "$TEMP_CONTENT"
    
    if [ ! -f "$DMG_PATH" ]; then
        print_error "Le fichier .dmg n'a pas été créé."
        exit 1
    fi
    
    print_success "DMG créé: $DMG_PATH"
}

# --- Vérification du .dmg ---
verify_dmg() {
    print_header "Vérification du .dmg"
    
    # Vérifier la taille du fichier
    DMG_SIZE=$(stat -f "%z" "$DMG_PATH" 2>/dev/null || stat -c "%s" "$DMG_PATH")
    
    if [ -n "$DMG_SIZE" ]; then
        # Convertir en format lisible
        if command -v numfmt &> /dev/null; then
            SIZE_HUMAN=$(numfmt --to=iec --suffix=B $DMG_SIZE)
        else
            # Calcul manuel
            if [ $DMG_SIZE -ge 1073741824 ]; then
                SIZE_HUMAN=$(echo "scale=2; $DMG_SIZE / 1073741824" | bc)G"
            elif [ $DMG_SIZE -ge 1048576 ]; then
                SIZE_HUMAN=$(echo "scale=2; $DMG_SIZE / 1048576" | bc)M"
            elif [ $DMG_SIZE -ge 1024 ]; then
                SIZE_HUMAN=$(echo "scale=2; $DMG_SIZE / 1024" | bc)K"
            else
                SIZE_HUMAN="${DMG_SIZE}B"
            fi
        fi
        print_info "Taille du .dmg: $SIZE_HUMAN"
    fi
    
    # Vérifier que le .dmg est montable
    print_info "Vérification de l'intégrité du .dmg..."
    if hdiutil verify "$DMG_PATH" &> /dev/null; then
        print_success "Le .dmg est valide et prêt à être distribué."
    else
        print_warning "Le .dmg semble corrompu. Essayez de le recréer."
    fi
}

# --- Préparation du release ---
prepare_release() {
    print_header "Préparation du release"
    
    # Créer un dossier pour les artifacts
    ARTIFACTS_DIR="$BUILD_DIR/artifacts"
    mkdir -p "$ARTIFACTS_DIR"
    
    # Copier le DMG
    cp "$DMG_PATH" "$ARTIFACTS_DIR/"
    
    # Créer un fichier de checksum
    if command -v shasum &> /dev/null; then
        cd "$ARTIFACTS_DIR"
        shasum -a 256 "$PROJECT_NAME-$VERSION.dmg" > "$PROJECT_NAME-$VERSION.dmg.sha256"
        cd "$SCRIPT_DIR"
        print_success "Checksum SHA256 créé"
    fi
    
    print_success "Artifacts prêts dans: $ARTIFACTS_DIR"
    ls -la "$ARTIFACTS_DIR"
}

# --- Affichage du résumé ---
print_summary() {
    print_header "Résumé de la build"
    
    echo ""
    print_info "Projet: $APP_NAME"
    print_info "Version: $VERSION"
    print_info "Architecture: arm64"
    print_info "Configuration: Release"
    echo ""
    print_info "Fichiers générés:"
    print_info "  - Application: $APP_PATH"
    print_info "  - DMG: $DMG_PATH"
    echo ""
    
    if [ -f "$DMG_PATH" ]; then
        print_success "✅ Build terminée avec succès!"
        print_success "Le DMG est prêt pour le release: $DMG_PATH"
    else
        print_error "❌ La build a échoué"
        exit 1
    fi
}

# --- Point d'entrée principal ---
main() {
    print_header "Début de la build de release pour $APP_NAME"
    print_info "Version: $VERSION"
    print_info "Date: $(date)"
    echo ""
    
    # Vérifier les dépendances
    check_dependencies
    echo ""
    
    # Nettoyer
    clean_build
    echo ""
    
    # Créer l'icône
    create_icon
    echo ""
    
    # Construire l'application
    build_app
    echo ""
    
    # Configurer l'application
    configure_app
    echo ""
    
    # Créer le .dmg
    create_dmg
    echo ""
    
    # Vérifier le .dmg
    verify_dmg
    echo ""
    
    # Préparer le release
    prepare_release
    echo ""
    
    # Afficher le résumé
    print_summary
}

# Exécuter le script
main "$@"
