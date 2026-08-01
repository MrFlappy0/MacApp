# Guide de Build pour MLX for All

Ce document explique comment construire et publier MLX for All.

## 📋 Prérequis

### macOS
- **macOS 14.0+** (Sonoma ou ultérieur)
- **Xcode 15.3+** avec les outils en ligne de commande
- **Apple Silicon** (M1/M2/M3/M5) **recommandé**

### Outils nécessaires
```bash
# Installer les dépendances avec Homebrew
brew install create-dmg
```

### Python (optionnel)
Pour la génération d'icônes :
```bash
pip install Pillow
```

---

## 🚀 Build Rapide

### 1. Cloner le dépôt
```bash
git clone https://github.com/MrFlappy0/MacApp.git
cd MacApp
```

### 2. Donner les permissions aux scripts
```bash
chmod +x *.sh
chmod +x create_icon_simple.py
```

### 3. Créer l'icône (si nécessaire)
```bash
python3 create_icon_simple.py
```

### 4. Construire l'application et créer le DMG
```bash
./build_release.sh 2.0.0
```

Le DMG sera généré dans `build/dmg/MLXForAll-2.0.0.dmg`

---

## 📦 Scripts Disponibles

### `build_release.sh`
Script principal pour construire l'application et créer le DMG.

**Usage:**
```bash
./build_release.sh [version]
```

**Exemple:**
```bash
./build_release.sh 2.0.0
```

**Ce que fait le script:**
1. Vérifie les dépendances (Xcode, Swift, hdiutil, create-dmg)
2. Nettoie les anciens builds
3. Crée l'icône .icns
4. Construit l'application en mode Release
5. Configure l'application (icône, version)
6. Crée le fichier .dmg
7. Vérifie le .dmg
8. Prépare les artifacts pour le release

### `make_release.sh`
Script complet pour créer un release avec tag Git.

**Usage:**
```bash
./make_release.sh [version] [message]
```

**Exemple:**
```bash
./make_release.sh 2.0.0 "Initial release with MLX 2.0 support"
```

**Ce que fait le script:**
1. Nettoie les images multiples
2. Crée l'icône
3. Exécute build_release.sh
4. Crée un tag Git
5. Pousse le tag vers origin
6. Affiche les instructions pour créer le release GitHub

### `cleanup_images.sh`
Nettoie les images multiples et garde seulement l'image source.

**Usage:**
```bash
./cleanup_images.sh
```

**Ce que fait le script:**
- Supprime toutes les images PNG dans `Resources/Images/` sauf `app_icon_1024.png`
- Supprime les images dans `Assets.xcassets/AppIcon.appiconset/`

### `create_icon_simple.py`
Crée une icône source et un fichier .icns simplifié.

**Usage:**
```bash
python3 create_icon_simple.py
```

**Note:** Pour un vrai fichier .icns sur macOS, utilisez :
```bash
# 1. Créez un dossier pour les icônes
mkdir -p Resources/AppIcon.iconset

# 2. Placez toutes les tailles d'icônes (16x16, 32x32, ..., 1024x1024)
#    dans Resources/AppIcon.iconset/

# 3. Convertissez en .icns
iconutil -c icns -o Resources/AppIcon.icns Resources/AppIcon.iconset
```

---

## 🎯 Build pour la Distribution

### Build locale
```bash
# Construire en mode Release
./build_release.sh 2.0.0

# Le DMG sera dans build/dmg/
ls -lh build/dmg/
```

### Build avec GitHub Actions
Le workflow `.github/workflows/build_and_release.yml` est configuré pour :

1. **Sur push vers main** : Construire et créer le DMG
2. **Sur création de tag** : Construire, créer le DMG et publier un release
3. **Workflow manuel** : Peut être déclenché via l'interface GitHub

**Pour déclencher manuellement :**
1. Allez sur GitHub > Actions
2. Sélectionnez le workflow "Build and Release MLX for All"
3. Cliquez sur "Run workflow"
4. Entrez la version (ex: 2.0.0)

---

## 🏷️ Créer un Release

### Méthode 1: Utiliser make_release.sh
```bash
./make_release.sh 2.0.0 "Nouvelle version avec support MLX 2.0"
```

### Méthode 2: Manuellement

1. **Créer le DMG**
```bash
./build_release.sh 2.0.0
```

2. **Créer un tag Git**
```bash
git tag -a v2.0.0 -m "Release v2.0.0: Nouvelle version avec support MLX 2.0"
git push origin v2.0.0
```

3. **Créer le release sur GitHub**
   - Allez sur: https://github.com/MrFlappy0/MacApp/releases/new
   - Sélectionnez le tag `v2.0.0`
   - Titre: `MLX for All v2.0.0`
   - Joignez le fichier: `build/dmg/MLXForAll-2.0.0.dmg`
   - Description: Utilisez le template du workflow

---

## 📊 Vérification

### Vérifier le DMG
```bash
# Vérifier que le DMG est valide
hdiutil verify build/dmg/MLXForAll-2.0.0.dmg

# Vérifier la taille
du -sh build/dmg/MLXForAll-2.0.0.dmg

# Monter le DMG pour tester
hdiutil attach build/dmg/MLXForAll-2.0.0.dmg
open /Volumes/MLXForAll/
```

### Vérifier l'application
```bash
# Vérifier la structure du bundle
ls -la build/Release/MLXForAll.app/Contents/

# Vérifier Info.plist
defaults read build/Release/MLXForAll.app/Contents/Info.plist
```

---

## ⚙️ Configuration

### Fichiers de Configuration

| Fichier | Description |
|--------|-------------|
| `Package.swift` | Dépendances et configuration du projet Swift |
| `ExportOptions.plist` | Options d'export pour Xcode |
| `Resources/Info.plist` | Configuration de l'application |
| `Config/build_config.json` | Configuration de build (optionnel) |

### Mettre à jour la version

1. **Dans Package.swift** : Mettre à jour la version
2. **Dans Resources/Info.plist** : Mettre à jour `CFBundleShortVersionString` et `CFBundleVersion`
3. **Dans ExportOptions.plist** : Vérifier la configuration de signature

---

## 🔧 Dépannage

### Problème: Xcode non trouvé
**Solution:** Installez Xcode depuis le Mac App Store et acceptez la licence :
```bash
xcode-select --install
sudo xcodebuild -license accept
```

### Problème: Swift non trouvé
**Solution:** Installez Xcode qui inclut Swift.

### Problème: create-dmg non trouvé
**Solution:** Installez avec Homebrew :
```bash
brew install create-dmg
```

### Problème: Le DMG n'est pas créé
**Solution:** Vérifiez les erreurs dans la sortie du script. Assurez-vous que :
- L'application a été construite avec succès
- Le dossier `build/Release/MLXForAll.app` existe
- Vous avez les permissions d'écriture

### Problème: L'application ne s'ouvre pas
**Solution:**
1. Faites un clic droit sur l'application > Ouvrir
2. Ou autorisez-la dans Préférences Système > Sécurité et confidentialité

### Problème: Erreur de signature
**Solution:** Configurez ExportOptions.plist avec votre Team ID Apple Developer.

---

## 📚 Structure du Projet

```
MLXForAll/
├── Sources/
│   ├── App/
│   │   └── MLXForAllApp.swift          # Point d'entrée
│   ├── Chat/
│   ├── MCP/
│   ├── Network/
│   └── Settings/
├── Resources/
│   ├── AppIcon.icns                    # Icône de l'application
│   ├── Images/
│   │   └── app_icon_1024.png           # Image source pour l'icône
│   └── Info.plist                      # Configuration
├── Assets.xcassets/
│   └── AppIcon.appiconset/
│       └── Contents.json
├── Config/
│   └── build_config.json               # Configuration de build
├── .github/
│   └── workflows/
│       └── build_and_release.yml       # Workflow CI/CD
├── Package.swift                       # Dépendances
├── ExportOptions.plist                 # Options d'export
├── build_release.sh                    # Script de build principal
├── make_release.sh                     # Script de release complet
├── cleanup_images.sh                   # Nettoyage des images
├── create_icon.icns.sh                 # Création de l'icône (macOS)
├── create_icon_simple.py               # Création de l'icône (Python)
├── BUILD.md                            # Ce document
└── README.md                           # Documentation principale
```

---

## 🎉 Fait !

Votre application MLX for All est prête à être construite et distribuée !

**Résumé des commandes importantes :**
```bash
# Build rapide
./build_release.sh 2.0.0

# Release complet
./make_release.sh 2.0.0 "Message de release"

# Nettoyage
./cleanup_images.sh
```

**Fichiers générés :**
- `build/Release/MLXForAll.app` - L'application
- `build/dmg/MLXForAll-2.0.0.dmg` - Le disque image
- `build/dmg/MLXForAll-2.0.0.dmg.sha256` - Checksum SHA256

---

## 📞 Support

Pour toute question ou problème :
- Ouvrez une **Issue** sur GitHub: [MrFlappy0/MacApp/issues](https://github.com/MrFlappy0/MacApp/issues)
- Consultez la **Documentation**: [DOCUMENTATION.md](DOCUMENTATION.md)
- Lisez le **README**: [README.md](README.md)
