#!/bin/bash

# =============================================================================
# MLX for All - DMG Build Script
# =============================================================================
# Ce script permet de :
# 1. Nettoyer les anciens builds
# 2. Construire l'application en mode Release
# 3. Créer un disque image (.dmg) avec une mise en page professionnelle
# 4. Inclure toutes les ressources nécessaires
# =============================================================================

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT_NAME="MLXForAll"
APP_NAME="MLX for All"
BUNDLE_ID="com.mrflappy0.MLXForAll"
VERSION="2.0.0"

# Chemins
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/Release"
APP_PATH="$RELEASE_DIR/$PROJECT_NAME.app"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$DMG_DIR/$PROJECT_NAME-$VERSION.dmg"
TEMP_DMG="$DMG_DIR/temp.dmg"
TEMP_MOUNT="/Volumes/$PROJECT_NAME"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Fonctions utilitaires ---
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[DMG Builder] ${message}${NC}"
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

# --- Vérification des dépendances ---
check_dependencies() {
    print_info "Vérification des dépendances..."
    
    # Vérifier Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools non trouvé. Veuillez installer Xcode."
        exit 1
    fi
    
    # Vérifier swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift non trouvé. Veuillez installer Xcode."
        exit 1
    fi
    
    # Vérifier hdiutil
    if ! command -v hdiutil &> /dev/null; then
        print_error "hdiutil non trouvé. Cet outil est normalement inclus avec macOS."
        exit 1
    fi
    
    # Vérifier create-dmg (optionnel)
    if ! command -v create-dmg &> /dev/null; then
        print_warning "create-dmg non installé. Installation recommandée pour une meilleure mise en page."
        print_info "Pour l'installer : brew install create-dmg"
        USE_CREATE_DMG=false
    else
        USE_CREATE_DMG=true
    fi
    
    print_success "Toutes les dépendances sont disponibles."
}

# --- Nettoyage ---
clean_build() {
    print_info "Nettoyage des anciens builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$RELEASE_DIR"
    mkdir -p "$DMG_DIR"
    print_success "Nettoyage terminé."
}

# --- Construction de l'application ---
build_app() {
    print_info "Construction de l'application en mode Release..."
    
    cd "$PROJECT_DIR"
    
    # Utiliser swift build pour construire le projet
    swift build -c release --arch arm64 \
        --static-swift-stdlib \
        -Xlinker -rpath -Xlinker @executable_path/../lib
    
    # Copier l'application dans le dossier de build
    cp -R "$PROJECT_DIR/.build/arm64-apple-macosx/release/$PROJECT_NAME.app" "$APP_PATH"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "Échec de la construction de l'application."
        exit 1
    fi
    
    print_success "Application construite avec succès : $APP_PATH"
}

# --- Création du .dmg ---
create_dmg() {
    print_info "Création du .dmg..."
    
    # Créer un dossier temporaire pour le contenu
    TEMP_CONTENT="$DMG_DIR/dmg_content"
    rm -rf "$TEMP_CONTENT"
    mkdir -p "$TEMP_CONTENT"
    
    # Copier l'application
    cp -R "$APP_PATH" "$TEMP_CONTENT/"
    
    # Créer un raccourci vers /Applications
    ln -s /Applications "$TEMP_CONTENT/Applications"
    
    if [ "$USE_CREATE_DMG" = true ]; then
        # Utiliser create-dmg pour une meilleure mise en page
        print_info "Utilisation de create-dmg pour une mise en page optimisée..."
        
        create-dmg \
            --volname "$PROJECT_NAME" \
            --volicon "$PROJECT_DIR/Resources/Images/app_icon_1024.png" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "$PROJECT_NAME.app" 150 190 \
            --icon "Applications" 450 190 \
            --app-drop-link 450 190 \
            "$DMG_PATH" \
            "$TEMP_CONTENT"
    else
        # Utiliser hdiutil
        print_info "Utilisation de hdiutil..."
        
        hdiutil create -volname "$PROJECT_NAME" \
            -srcfolder "$TEMP_CONTENT" \
            -ov -format UDZO \
            "$DMG_PATH"
    fi
    
    # Nettoyer
    rm -rf "$TEMP_CONTENT"
    
    print_success "DMG créé avec succès : $DMG_PATH"
}

# --- Vérification du .dmg ---
verify_dmg() {
    print_info "Vérification du .dmg..."
    
    if [ ! -f "$DMG_PATH" ]; then
        print_error "Le fichier .dmg n'a pas été créé."
        exit 1
    fi
    
    # Vérifier la taille du fichier
    DMG_SIZE=$(stat -f "%z" "$DMG_PATH")
    print_info "Taille du .dmg : $(numfmt --to=iec --suffix=B $DMG_SIZE)"
    
    # Vérifier que le .dmg est montable
    if ! hdiutil verify "$DMG_PATH" &> /dev/null; then
        print_warning "Le .dmg semble corrompu."
    else
        print_success "Le .dmg est valide et prêt à être distribué."
    fi
}

# --- Point d'entrée principal ---
main() {
    print_info "=========================================="
    print_info "  Début de la création du .dmg pour $APP_NAME"
    print_info "  Version : $VERSION"
    print_info "=========================================="
    
    # Vérifier les dépendances
    check_dependencies
    
    # Nettoyer
    clean_build
    
    # Construire l'application
    build_app
    
    # Créer le .dmg
    create_dmg
    
    # Vérifier le .dmg
    verify_dmg
    
    print_success "=========================================="
    print_success "  ✅ Processus terminé avec succès !"
    print_success "  📁 Fichier généré : $DMG_PATH"
    print_success "=========================================="
}

# Exécuter le script
main "$@"
