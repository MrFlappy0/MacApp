#!/usr/bin/env python3
"""
Script simple pour créer une icône .icns pour MLX for All
Utilise PIL pour créer une image source si elle n'existe pas
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

def create_source_icon(output_path: str = "Resources/Images/app_icon_1024.png"):
    """Crée une image source 1024x1024 pour l'icône"""
    size = 1024
    
    # Créer une image avec fond noir foncé
    img = Image.new('RGBA', (size, size), (30, 30, 30, 255))
    draw = ImageDraw.Draw(img)
    
    # Dessiner un carré arrondi bleu (style MLX)
    padding = size // 10
    shape_size = size - 2 * padding
    radius = size // 8
    
    # Couleur principale (bleu MLX)
    primary_color = (44, 140, 220, 255)
    
    draw.rounded_rectangle(
        [(padding, padding), (size - padding, size - padding)],
        radius=radius,
        fill=primary_color
    )
    
    # Ajouter le texte "MLX"
    try:
        font_size = size // 8
        # Essayer différentes polices
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/Library/Fonts/Arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            None  # Police par défaut
        ]
        
        font = None
        for path in font_paths:
            try:
                if path:
                    font = ImageFont.truetype(path, font_size)
                else:
                    font = ImageFont.load_default()
                break
            except:
                continue
        
        if font is None:
            font = ImageFont.load_default()
        
        text = "MLX"
        
        # Calculer la position
        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
        
        x = (size - text_width) / 2
        y = (size - text_height) / 2
        
        # Dessiner le texte en blanc
        draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)
        
    except Exception as e:
        print(f"⚠️  Impossible d'ajouter le texte: {e}")
    
    # Sauvegarder l'image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"✅ Image source créée: {output_path}")
    return output_path

def create_icns_from_png(png_path: str, icns_path: str = "Resources/AppIcon.icns"):
    """
    Crée un fichier .icns à partir d'une image PNG
    Note: Sur macOS, on utiliserait 'iconutil' mais ici on crée une version simplifiée
    """
    print("ℹ️  Création du fichier .icns...")
    
    # Sur macOS, on pourrait utiliser:
    # iconutil -c icns -o output.icns input.iconset
    
    # Mais comme nous ne sommes pas sur macOS, nous allons créer un fichier .icns
    # en utilisant une structure binaire simplifiée
    
    # Pour l'instant, on va juste copier le PNG comme .icns (ce n'est pas correct
    # mais ça permettra au moins d'avoir un fichier)
    # En production, il faudrait utiliser iconutil sur macOS
    
    try:
        img = Image.open(png_path)
        os.makedirs(os.path.dirname(icns_path), exist_ok=True)
        
        # Sauvegarder comme .icns (en réalité, c'est juste un PNG renommé)
        # Sur macOS, utilisez: iconutil -c icns -o Resources/AppIcon.icns Resources/AppIcon.iconset
        img.save(icns_path, 'PNG')
        print(f"✅ Fichier .icns créé (simplifié): {icns_path}")
        print("⚠️  Note: Pour un vrai .icns, exécutez sur macOS: iconutil -c icns -o Resources/AppIcon.icns Resources/AppIcon.iconset")
        
    except Exception as e:
        print(f"❌ Erreur lors de la création du .icns: {e}")

def main():
    print("🎨 Création de l'icône pour MLX for All...")
    print()
    
    project_dir = os.getcwd()
    
    # Créer l'image source
    source_path = os.path.join(project_dir, "Resources/Images/app_icon_1024.png")
    
    if not os.path.exists(source_path):
        create_source_icon(source_path)
    else:
        print(f"✅ Image source existante: {source_path}")
    
    # Créer le .icns
    icns_path = os.path.join(project_dir, "Resources/AppIcon.icns")
    create_icns_from_png(source_path, icns_path)
    
    # Copier aussi dans Assets.xcassets si le dossier existe
    assets_dir = os.path.join(project_dir, "Assets.xcassets/AppIcon.appiconset")
    if os.path.exists(assets_dir):
        assets_icns = os.path.join(assets_dir, "AppIcon.icns")
        try:
            img = Image.open(source_path)
            img.save(assets_icns, 'PNG')
            print(f"✅ Icône copiée dans Assets.xcassets")
        except Exception as e:
            print(f"⚠️  Impossible de copier dans Assets.xcassets: {e}")
    
    print()
    print("✅ Toutes les opérations terminées!")
    print()
    print("Pour une icône .icns complète sur macOS:")
    print("1. Créez un dossier Resources/AppIcon.iconset")
    print("2. Placez toutes les tailles d'icônes dans ce dossier")
    print("3. Exécutez: iconutil -c icns -o Resources/AppIcon.icns Resources/AppIcon.iconset")

if __name__ == "__main__":
    main()
