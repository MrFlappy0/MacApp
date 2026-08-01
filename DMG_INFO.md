# Information sur la Génération du DMG

## 📦 Génération Automatique du DMG

Le DMG de **MLX for All** est **généré automatiquement** par GitHub Actions à chaque :
- **Push de tag** (ex: `v2.0.0`)
- **Exécution manuelle** du workflow

---

## 🚀 Comment Déclencher la Génération

### Méthode 1: Créer un Tag (Recommandé)

```bash
# Créer un tag pour déclencher le build
 git tag -a v2.0.0 -m "Release v2.0.0"
 git push origin v2.0.0
```

Le workflow va :
1. ✅ Construire l'application
2. ✅ Créer l'icône
3. ✅ Générer le DMG
4. ✅ Créer un release GitHub avec le DMG

### Méthode 2: Déclencher Manuellement via GitHub

1. Allez sur : https://github.com/MrFlappy0/MacApp/actions
2. Sélectionnez le workflow **"Build DMG and Release"**
3. Cliquez sur **"Run workflow"**
4. Entrez la version (ex: `2.0.0`)
5. Cliquez sur **"Run workflow"**

---

## 📁 Fichiers Générés

| Fichier | Description | Emplacement |
|--------|-------------|-------------|
| `MLXForAll-2.0.0.dmg` | Le disque image | `build/dmg/` |
| `MLXForAll-2.0.0.dmg.sha256` | Checksum SHA256 | `build/dmg/` |

---

## 🏗️ Processus de Build

### Étape 1: Checkout du Code
- Récupère la dernière version du dépôt

### Étape 2: Installation des Dépendances
- **Xcode 15.3**
- **create-dmg** (via Homebrew)
- **Pillow** (pour la génération d'icônes)

### Étape 3: Génération de l'Icône
- Exécute `create_icon_simple.py`
- Crée `Resources/AppIcon.icns`
- Crée `Resources/Images/app_icon_1024.png`

### Étape 4: Build de l'Application
- Exécute `swift build -c release --arch arm64`
- Crée l'application dans `.build/arm64-apple-macosx/release/`

### Étape 5: Création du DMG
- Utilise `create-dmg` pour une mise en page professionnelle
- Inclut l'icône de l'application
- Inclut un fond personnalisé
- Positionne correctement les icônes

### Étape 6: Vérification
- Vérifie que le DMG est valide avec `hdiutil verify`
- Génère un checksum SHA256

### Étape 7: Publication
- Upload le DMG comme artifact
- Crée un release GitHub avec le DMG et le checksum

---

## 📊 Configuration du Workflow

### Fichier: `.github/workflows/build_dmg.yml`

```yaml
name: Build DMG and Release

on:
  push:
    tags:
      - 'v*'
    branches:
      - main
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release'
        required: true
        default: '2.0.0'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-xcode@v1
        with:
          xcode-version: '15.3'
      - run: brew install create-dmg
      - run: pip3 install Pillow
      - run: python3 create_icon_simple.py
      - run: chmod +x build_release.sh && ./build_release.sh ${{ version }}
      - run: shasum -a 256 *.dmg > *.dmg.sha256
      - uses: actions/upload-artifact@v4
        with:
          name: MLXForAll-${{ version }}.dmg
          path: build/dmg/MLXForAll-${{ version }}.dmg
      - uses: softprops/action-gh-release@v1
        with:
          files: build/dmg/MLXForAll-${{ version }}.dmg
          tag_name: v${{ version }}
```

---

## 🎯 Prérequis pour le Build Local

Si vous voulez tester localement :

### macOS
- **macOS 14.0+** (Sonoma)
- **Xcode 15.3+**
- **Homebrew**

### Installation
```bash
# Installer les dépendances
brew install create-dmg
pip3 install Pillow

# Donner les permissions
chmod +x *.sh

# Exécuter le build
./build_release.sh 2.0.0
```

---

## ⚙️ Personnalisation

### Changer la Version
Modifiez dans :
- `Package.swift` : Version du package
- `Resources/Info.plist` : `CFBundleShortVersionString`
- `build_release.sh` : Variable `VERSION`

### Changer l'Icône
- Modifiez `create_icon_simple.py` pour changer le design
- Ou placez votre propre image dans `Resources/Images/app_icon_1024.png`

### Changer la Mise en Page du DMG
Modifiez dans `build_release.sh` :
```bash
create-dmg \
    --volname "MLXForAll" \
    --volicon "$ICON_PATH" \
    --background "$BACKGROUND_IMAGE" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$PROJECT_NAME.app" 150 190 \
    --icon "Applications" 450 190 \
    --app-drop-link 450 190
```

---

## 🔍 Dépannage

### Le workflow échoue
- Vérifiez que le tag suit le format `v*` (ex: `v2.0.0`)
- Vérifiez que le workflow a les permissions nécessaires
- Consultez les logs dans GitHub Actions

### Le DMG n'est pas généré
- Vérifiez que `swift build` fonctionne localement
- Vérifiez que `create-dmg` est installé
- Vérifiez que l'application est construite dans `.build/arm64-apple-macosx/release/`

### Le DMG est corrompu
- Vérifiez avec : `hdiutil verify MLXForAll-2.0.0.dmg`
- Essayez de recréer le DMG

---

## 📞 Support

Pour toute question :
- **Issues** : [MrFlappy0/MacApp/issues](https://github.com/MrFlappy0/MacApp/issues)
- **Discussions** : [MrFlappy0/MacApp/discussions](https://github.com/MrFlappy0/MacApp/discussions)

---

## ✅ Résumé

| Élément | Statut | Emplacement |
|---------|--------|-------------|
| ✅ Workflow GitHub Actions | Actif | `.github/workflows/build_dmg.yml` |
| ✅ Script de build | Prêt | `build_release.sh` |
| ✅ Génération d'icône | Automatique | `create_icon_simple.py` |
| ✅ Création du DMG | Automatique | `create-dmg` |
| ✅ Release GitHub | Automatique | Via workflow |
| ✅ Checksum | Généré | `.dmg.sha256` |

**Le DMG sera automatiquement généré et publié sur GitHub à chaque tag !** 🎉
