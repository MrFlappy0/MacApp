#!/bin/bash

# =============================================================================
# Script pour nettoyer les images multiples et garder une seule icône
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[Cleanup] ${message}${NC}"
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

# Supprimer les images multiples dans Resources/Images
print_info "Nettoyage des images multiples..."

IMAGES_DIR="$PROJECT_DIR/Resources/Images"

if [ -d "$IMAGES_DIR" ]; then
    # Lister les fichiers PNG
    png_files=$(find "$IMAGES_DIR" -name "*.png" -type f)
    
    if [ -n "$png_files" ]; then
        print_info "Fichiers PNG trouvés dans Resources/Images:"
        echo "$png_files" | while read -r file; do
            print_info "  - $file"
        done
        
        # Garder seulement app_icon_1024.png (source) et supprimer les autres
        for file in $png_files; do
            filename=$(basename "$file")
            if [ "$filename" != "app_icon_1024.png" ]; then
                print_info "Suppression de $file"
                rm "$file"
            fi
        done
        
        print_success "Images nettoyées. Seule app_icon_1024.png est conservée comme source."
    fi
else
    print_info "Le dossier Resources/Images n'existe pas."
fi

# Nettoyer aussi dans Assets.xcassets si nécessaire
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset"

if [ -d "$ASSETS_DIR" ]; then
    print_info "Nettoyage de Assets.xcassets/AppIcon.appiconset..."
    
    # Supprimer les images individuelles, on utilisera le .icns
    png_files=$(find "$ASSETS_DIR" -name "*.png" -type f)
    
    if [ -n "$png_files" ]; then
        for file in $png_files; do
            print_info "Suppression de $file"
            rm "$file"
        done
        print_success "Images supprimées de Assets.xcassets."
    fi
fi

# Vérifier que l'icône .icns existe
ICON_PATH="$PROJECT_DIR/Resources/AppIcon.icns"

if [ -f "$ICON_PATH" ]; then
    print_success "Icône .icns existante: $ICON_PATH"
else
    print_warning "L'icône .icns n'existe pas. Exécutez create_icon.icns.sh pour la créer."
fi

print_success "✅ Nettoyage terminé!"
