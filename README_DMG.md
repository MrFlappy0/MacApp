# 📦 Comment Obtenir le DMG de MLX for All

## ✅ Le DMG est Généré Automatiquement !

**Pas besoin d'exécuter de scripts manuellement.** Le DMG est **créé automatiquement** par GitHub Actions et publié dans les **releases GitHub**.

---

## 🎯 3 Méthodes pour Obtenir le DMG

### 🏆 Méthode 1: Télécharger depuis les Releases GitHub (Recommandé)

1. **Aller sur la page des releases** :
   🔗 [https://github.com/MrFlappy0/MacApp/releases](https://github.com/MrFlappy0/MacApp/releases)

2. **Trouver la dernière version** :
   - Cherchez le release avec le tag le plus récent (ex: `v2.0.0`)

3. **Télécharger le DMG** :
   - Cliquez sur `MLXForAll-2.0.0.dmg` pour le télécharger

4. **Installer** :
   ```bash
   # Ouvrir le DMG
   open ~/Downloads/MLXForAll-2.0.0.dmg
   
   # Glisser-déposer dans Applications
   # Lancer depuis /Applications
   ```

---

### 🔄 Méthode 2: Déclencher un Build Manuel (Pour les Développeurs)

Si vous voulez **reconstruire le DMG** avec les dernières modifications :

1. **Aller sur GitHub Actions** :
   🔗 [https://github.com/MrFlappy0/MacApp/actions](https://github.com/MrFlappy0/MacApp/actions)

2. **Sélectionner le workflow** :
   - Cliquez sur **"Build DMG and Release"**

3. **Exécuter le workflow** :
   - Cliquez sur **"Run workflow"**
   - Entrez la version (ex: `2.0.1`)
   - Cliquez sur **"Run workflow"**

4. **Attendre la fin du build** (environ 10-15 minutes)

5. **Télécharger le DMG** :
   - Dans l'onglet **"Artifacts"** du workflow
   - Ou dans le **release automatique** créé

---

### 🏗️ Méthode 3: Construire Localement (Pour le Développement)

Si vous voulez **tester localement** avant de pousser :

#### Prérequis
- **macOS 14.0+** (Sonoma)
- **Xcode 15.3+**
- **Homebrew**

#### Installation des dépendances
```bash
# Installer create-dmg
brew install create-dmg

# Installer Pillow pour la génération d'icônes
pip3 install Pillow
```

#### Construire le DMG
```bash
# Cloner le dépôt
git clone https://github.com/MrFlappy0/MacApp.git
cd MacApp

# Donner les permissions aux scripts
chmod +x *.sh

# Générer l'icône
python3 create_icon_simple.py

# Construire l'application et créer le DMG
./build_release.sh 2.0.0

# Le DMG sera dans build/dmg/
ls -lh build/dmg/
```

---

## 📁 Où Trouver le DMG

| Emplacement | Description | Quand |
|-------------|-------------|-------|
| **Releases GitHub** | Version officielle | Après un tag `v*` |
| **Artifacts GitHub Actions** | Build temporaire | Après exécution manuelle |
| **Local: `build/dmg/`** | Build local | Après `./build_release.sh` |

---

## 🔍 Vérification du DMG

### Vérifier l'intégrité
```bash
# Vérifier le checksum SHA256
shasum -a 256 MLXForAll-2.0.0.dmg

# Comparer avec le fichier .sha256
cat MLXForAll-2.0.0.dmg.sha256
```

### Vérifier que le DMG est valide
```bash
# Monter le DMG
hdiutil verify MLXForAll-2.0.0.dmg

# Monter et ouvrir
hdiutil attach MLXForAll-2.0.0.dmg
open /Volumes/MLXForAll/
```

---

## ⚙️ Configuration du Workflow

Le workflow **`.github/workflows/build_dmg.yml`** est configuré pour :

### Déclencheurs Automatiques
- ✅ **Push de tag** : `v*` (ex: `v2.0.0`, `v2.0.1`)
- ✅ **Push vers main** : Build automatique
- ✅ **Exécution manuelle** : Via l'interface GitHub

### Étapes du Workflow
1. **Checkout** du code
2. **Installation** de Xcode, create-dmg, Pillow
3. **Génération** de l'icône
4. **Build** de l'application avec Swift
5. **Création** du DMG avec create-dmg
6. **Vérification** du DMG
7. **Génération** du checksum SHA256
8. **Upload** comme artifact
9. **Création** d'un release GitHub

---

## 📊 Dernière Version Disponible

| Version | Tag | Statut | DMG |
|---------|-----|--------|-----|
| **2.0.0** | `v2.0.0` | ✅ Prêt | [Télécharger](https://github.com/MrFlappy0/MacApp/releases/tag/v2.0.0) |

---

## 🎉 Résumé

| Action | Commande | Résultat |
|--------|----------|----------|
| **Télécharger le DMG** | Aller sur [Releases](https://github.com/MrFlappy0/MacApp/releases) | ✅ DMG prêt à l'emploi |
| **Déclencher un build** | Exécuter workflow manuellement | ⏳ DMG généré en 10-15 min |
| **Construire localement** | `./build_release.sh 2.0.0` | ✅ DMG dans `build/dmg/` |

---

## 🚨 Problèmes Courants

### "Le workflow ne se déclenche pas"
- **Solution** : Vérifiez que le tag suit le format `v*` (ex: `v2.0.0`)
- **Solution** : Vérifiez que le workflow a les permissions dans les settings GitHub

### "Le DMG n'est pas dans le release"
- **Solution** : Attendez la fin du workflow (10-15 min)
- **Solution** : Vérifiez les logs dans GitHub Actions
- **Solution** : Vérifiez que le build a réussi

### "Le DMG ne s'ouvre pas"
- **Solution** : Faites un **clic droit > Ouvrir**
- **Solution** : Autorisez dans **Préférences Système > Sécurité et confidentialité**

---

## 📞 Support

- **Documentation** : [DMG_INFO.md](DMG_INFO.md)
- **Configuration** : [.github/RELEASE_CONFIG.md](.github/RELEASE_CONFIG.md)
- **Build** : [BUILD.md](BUILD.md)
- **Issues** : [MrFlappy0/MacApp/issues](https://github.com/MrFlappy0/MacApp/issues)

---

## ✨ C'est Tout !

**Le DMG est généré automatiquement et disponible dans les releases GitHub.**

🔗 **Téléchargez-le maintenant :** [https://github.com/MrFlappy0/MacApp/releases](https://github.com/MrFlappy0/MacApp/releases)
