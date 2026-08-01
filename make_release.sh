#!/bin/bash

# =============================================================================
# MLX for All - Make Release Script
# =============================================================================
# Script principal pour créer un release complet avec DMG
# Usage: ./make_release.sh [version] [message]
# Exemple: ./make_release.sh 2.0.0 "Initial release"
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[Make Release] ${message}${NC}"
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

print_header() {
    print_status "$PURPLE" "=== $1 ==="
}

# Récupérer la version
VERSION="${1:-2.0.0}"
RELEASE_MESSAGE="${2:-Automatic release}"

print_header "Début du processus de release"
print_info "Version: $VERSION"
print_info "Message: $RELEASE_MESSAGE"
print_info "Date: $(date)"
echo ""

# Étape 1: Nettoyer les anciens builds
print_header "Étape 1: Nettoyage"
if [ -f "$PROJECT_DIR/cleanup_images.sh" ]; then
    cd "$PROJECT_DIR"
    ./cleanup_images.sh
    cd "$SCRIPT_DIR"
fi
print_success "Nettoyage terminé"
echo ""

# Étape 2: Créer l'icône
print_header "Étape 2: Création de l'icône"
if [ -f "$PROJECT_DIR/create_icon_simple.py" ]; then
    cd "$PROJECT_DIR"
    python3 create_icon_simple.py
    cd "$SCRIPT_DIR"
fi
print_success "Icône créée"
echo ""

# Étape 3: Construire l'application et créer le DMG
print_header "Étape 3: Build de l'application et création du DMG"
if [ -f "$PROJECT_DIR/build_release.sh" ]; then
    cd "$PROJECT_DIR"
    ./build_release.sh "$VERSION"
    cd "$SCRIPT_DIR"
else
    print_error "Script build_release.sh non trouvé"
    exit 1
fi
print_success "DMG créé"
echo ""

# Étape 4: Vérifier que le DMG existe
print_header "Étape 4: Vérification"
DMG_PATH="$PROJECT_DIR/build/dmg/MLXForAll-$VERSION.dmg"

if [ ! -f "$DMG_PATH" ]; then
    print_error "Le fichier DMG n'a pas été créé: $DMG_PATH"
    
    # Lister ce qui existe dans le dossier build/dmg
    if [ -d "$PROJECT_DIR/build/dmg" ]; then
        print_info "Contenu de build/dmg:"
        ls -la "$PROJECT_DIR/build/dmg/"
    fi
    
    exit 1
fi

print_success "DMG vérifié: $DMG_PATH"
print_info "Taille: $(du -sh "$DMG_PATH" 2>/dev/null | cut -f1)"
echo ""

# Étape 5: Créer un tag Git et pousser
print_header "Étape 5: Création du tag Git"

# Vérifier que git est disponible
if ! command -v git &> /dev/null; then
    print_warning "Git non disponible. Le tag ne sera pas créé."
else
    cd "$PROJECT_DIR"
    
    # Vérifier que nous sommes dans un dépôt git
    if [ -d ".git" ]; then
        # Créer le tag
        git tag -a "v$VERSION" -m "Release v$VERSION: $RELEASE_MESSAGE"
        print_success "Tag créé: v$VERSION"
        
        # Pousser le tag
        if git push origin "v$VERSION" 2>/dev/null; then
            print_success "Tag poussé vers origin"
        else
            print_warning "Impossible de pousser le tag. Faites-le manuellement: git push origin v$VERSION"
        fi
    else
        print_warning "Pas dans un dépôt git. Le tag ne sera pas créé."
    fi
fi
echo ""

# Étape 6: Instructions pour le release GitHub
print_header "Étape 6: Release GitHub"
print_info "Pour créer un release GitHub:"
print_info "1. Allez sur: https://github.com/MrFlappy0/MacApp/releases/new"
print_info "2. Sélectionnez le tag: v$VERSION"
print_info "3. Titre: MLX for All v$VERSION"
print_info "4. Joignez le fichier: $DMG_PATH"
print_info "5. Description: Utilisez le template du workflow"
echo ""

# Étape 7: Résumé
print_header "Résumé"
print_success "✅ Version: $VERSION"
print_success "✅ DMG: $DMG_PATH"
print_success "✅ Tag: v$VERSION"
print_success "✅ Message: $RELEASE_MESSAGE"
echo ""

print_header "Fichiers générés"
print_info "- Application: $PROJECT_DIR/build/Release/MLXForAll.app"
print_info "- DMG: $DMG_PATH"
print_info "- Checksum: $PROJECT_DIR/build/dmg/MLXForAll-$VERSION.dmg.sha256"
echo ""

print_success "✅ Processus de release terminé avec succès!"
print_info "Le DMG est prêt pour la distribution."
