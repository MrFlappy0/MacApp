#!/bin/bash

# =============================================================================
# Script pour créer une icône .icns unique pour MLX for All
# =============================================================================
# Ce script utilise sips (inclus avec macOS) pour convertir une image source
# en fichier .icns contenant toutes les tailles nécessaires.
# =============================================================================

set -e

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
    echo -e "${color}[Icon Builder] ${message}${NC}"
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

# Vérifier que sips est disponible
if ! command -v sips &> /dev/null; then
    print_error "sips non trouvé. Cet outil est normalement inclus avec macOS."
    exit 1
fi

# Vérifier que iconutil est disponible
if ! command -v iconutil &> /dev/null; then
    print_error "iconutil non trouvé. Cet outil est normalement inclus avec macOS."
    exit 1
fi

# Chemin de l'image source (on utilise la plus grande disponible)
SOURCE_IMAGE="$PROJECT_DIR/Resources/Images/app_icon_1024.png"

# Si l'image source n'existe pas, essayer de la créer
if [ ! -f "$SOURCE_IMAGE" ]; then
    print_info "Création d'une image source par défaut..."
    mkdir -p "$PROJECT_DIR/Resources/Images"
    
    # Créer une image PNG simple avec Python (si disponible)
    if command -v python3 &> /dev/null; then
        python3 << 'EOF'
import numpy as np
from PIL import Image, ImageDraw, ImageFont

# Créer une image 1024x1024
size = 1024
img = Image.new('RGBA', (size, size), (30, 30, 30, 255))
draw = ImageDraw.Draw(img)

# Dessiner un carré arrondi bleu
padding = size // 10
shape_size = size - 2 * padding
radius = size // 8
draw.rounded_rectangle(
    [(padding, padding), (size - padding, size - padding)],
    radius=radius,
    fill=(44, 140, 220, 255)
)

# Ajouter le texte "MLX"
try:
    font_size = size // 8
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    text = "MLX"
    text_width, text_height = draw.textsize(text, font=font)
    x = (size - text_width) / 2
    y = (size - text_height) / 2
    draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)
except:
    pass

img.save("$PROJECT_DIR/Resources/Images/app_icon_1024.png", 'PNG')
print("Image source créée: $PROJECT_DIR/Resources/Images/app_icon_1024.png")
EOF
    else
        print_error "Python3 non disponible pour créer l'image source."
        exit 1
    fi
fi

# Créer un dossier temporaire pour les icônes
TEMP_ICONSET="$PROJECT_DIR/Resources/AppIcon.iconset"
rm -rf "$TEMP_ICONSET"
mkdir -p "$TEMP_ICONSET"

print_info "Création des différentes tailles d'icônes..."

# Créer toutes les tailles nécessaires pour .icns
# Format: icon_<size>x<size>[@2x].png

# Tailles standard
sizes=("16" "32" "64" "128" "256" "512" "1024")

for size in "${sizes[@]}"; do
    # Simple
    sips -z 0 0 -s format png "$SOURCE_IMAGE" --out "$TEMP_ICONSET/icon_${size}x${size}.png" --setProperty formatOptions "${size}"
    
    # @2x (pour Retina)
    double_size=$((size * 2))
    if [ $double_size -le 1024 ]; then
        sips -z 0 0 -s format png "$SOURCE_IMAGE" --out "$TEMP_ICONSET/icon_${size}x${size}@2x.png" --setProperty formatOptions "${double_size}"
    fi
done

# Tailles spécifiques pour macOS
# 16x16@2x -> 32x32
if [ ! -f "$TEMP_ICONSET/icon_16x16@2x.png" ]; then
    cp "$TEMP_ICONSET/icon_32x32.png" "$TEMP_ICONSET/icon_16x16@2x.png"
fi

# 32x32@2x -> 64x64
if [ ! -f "$TEMP_ICONSET/icon_32x32@2x.png" ]; then
    cp "$TEMP_ICONSET/icon_64x64.png" "$TEMP_ICONSET/icon_32x32@2x.png"
fi

# 128x128@2x -> 256x256
if [ ! -f "$TEMP_ICONSET/icon_128x128@2x.png" ]; then
    cp "$TEMP_ICONSET/icon_256x256.png" "$TEMP_ICONSET/icon_128x128@2x.png"
fi

# 256x256@2x -> 512x512
if [ ! -f "$TEMP_ICONSET/icon_256x256@2x.png" ]; then
    cp "$TEMP_ICONSET/icon_512x512.png" "$TEMP_ICONSET/icon_256x256@2x.png"
fi

# 512x512@2x -> 1024x1024
if [ ! -f "$TEMP_ICONSET/icon_512x512@2x.png" ]; then
    cp "$TEMP_ICONSET/icon_1024x1024.png" "$TEMP_ICONSET/icon_512x512@2x.png"
fi

print_info "Conversion en .icns..."

# Convertir en .icns
iconutil -c icns -o "$PROJECT_DIR/Resources/AppIcon.icns" "$TEMP_ICONSET"

# Nettoyer
rm -rf "$TEMP_ICONSET"

print_success "Icône .icns créée avec succès: $PROJECT_DIR/Resources/AppIcon.icns"

# Copier aussi dans Assets.xcassets si le dossier existe
if [ -d "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset/"
    print_info "Icône copiée dans Assets.xcassets"
fi

print_success "✅ Toutes les opérations terminées!"
