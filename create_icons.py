#!/usr/bin/env python3
"""
Script pour générer les icônes de l'application MLX for All
Ce script utilise PIL (Pillow) pour créer des icônes de différentes tailles
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

# Configuration
APP_NAME = "MLX for All"
OUTPUT_DIR = "Resources/Images"
APP_ICON_DIR = "Assets.xcassets/AppIcon.appiconset"

# Couleurs
PRIMARY_COLOR = (44, 140, 220)  # Bleu
SECONDARY_COLOR = (255, 255, 255)  # Blanc
BACKGROUND_COLOR = (30, 30, 30)  # Noir foncé

# Tailles d'icônes
ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

def create_icon(size: int, output_path: str):
    """Crée une icône de taille donnée"""
    # Créer une image carrée
    img = Image.new('RGBA', (size, size), BACKGROUND_COLOR)
    draw = ImageDraw.Draw(img)
    
    # Dessiner un cercle ou un carré selon la taille
    padding = size // 10
    shape_size = size - 2 * padding
    
    # Dessiner la forme principale (cercle pour les petites tailles, carré arrondi pour les grandes)
    if size <= 64:
        # Cercle pour les petites icônes
        draw.ellipse(
            [(padding, padding), (size - padding, size - padding)],
            fill=PRIMARY_COLOR
        )
    else:
        # Carré arrondi pour les grandes icônes
        radius = size // 8
        draw.rounded_rectangle(
            [(padding, padding), (size - padding, size - padding)],
            radius=radius,
            fill=PRIMARY_COLOR
        )
    
    # Ajouter le texte pour les grandes icônes
    if size >= 128:
        try:
            # Trouver une police adaptée
            font_size = size // 8
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
            
            # Texte à afficher
            text = "MLX"
            
            # Calculer la position
            text_width, text_height = draw.textsize(text, font=font)
            x = (size - text_width) / 2
            y = (size - text_height) / 2
            
            # Dessiner le texte
            draw.text((x, y), text, fill=SECONDARY_COLOR, font=font)
        except:
            pass  # Si la police n'est pas disponible, on passe
    
    # Sauvegarder l'image
    img.save(output_path, 'PNG')
    print(f"Créée: {output_path}")

def main():
    print("Génération des icônes pour MLX for All...")
    
    # Créer les répertoires si nécessaire
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(APP_ICON_DIR, exist_ok=True)
    
    # Générer toutes les tailles d'icônes
    for size in ICON_SIZES:
        # Nom du fichier
        filename = f"app_icon_{size}.png"
        
        # Chemin de sortie
        output_path = os.path.join(OUTPUT_DIR, filename)
        
        # Créer l'icône
        create_icon(size, output_path)
        
        # Copier aussi dans le dossier AppIcon.appiconset
        app_icon_path = os.path.join(APP_ICON_DIR, filename)
        if os.path.exists(output_path):
            with open(output_path, 'rb') as src, open(app_icon_path, 'wb') as dst:
                dst.write(src.read())
    
    print("\n✅ Toutes les icônes ont été générées avec succès!")
    print(f"   - Dans: {OUTPUT_DIR}")
    print(f"   - Dans: {APP_ICON_DIR}")

if __name__ == "__main__":
    main()
