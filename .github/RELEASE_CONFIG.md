# Configuration pour le Release Automatique

## 🎯 Configuration Actuelle

### Workflow
- **Fichier** : `.github/workflows/build_dmg.yml`
- **Déclencheurs** :
  - Push de tag `v*` (ex: `v2.0.0`)
  - Exécution manuelle via GitHub UI
  - Push vers la branche `main`

### Version
- **Dernière version** : `2.0.0`
- **Tag** : `v2.0.0`

### Fichiers Générés
- **DMG** : `MLXForAll-2.0.0.dmg`
- **Checksum** : `MLXForAll-2.0.0.dmg.sha256`
- **Emplacement** : `build/dmg/`

---

## 🚀 Comment Faire un Release

### 1. Mettre à jour la version

Dans ces fichiers :
- `Package.swift` : `name: "MLXForAll"`
- `Resources/Info.plist` : `CFBundleShortVersionString` et `CFBundleVersion`
- `build_release.sh` : Variable `VERSION` (optionnel)

### 2. Créer un commit

```bash
git add .
git commit -m "Prépare release v2.0.0"
```

### 3. Créer un tag et pousser

```bash
# Créer un tag annoté
git tag -a v2.0.0 -m "Release v2.0.0: Description des changements"

# Pousser le tag
git push origin v2.0.0
```

### 4. Le workflow s'exécute automatiquement

Le workflow **build_dmg.yml** va :
1. ✅ Checkout le code
2. ✅ Installer les dépendances (Xcode, create-dmg, Pillow)
3. ✅ Générer l'icône
4. ✅ Construire l'application
5. ✅ Créer le DMG
6. ✅ Vérifier le DMG
7. ✅ Créer un release GitHub avec le DMG

---

## 📦 Contenu du Release

Chaque release contiendra :

### Fichiers
| Fichier | Description |
|--------|-------------|
| `MLXForAll-2.0.0.dmg` | Le disque image pour macOS |
| `MLXForAll-2.0.0.dmg.sha256` | Checksum SHA256 pour vérification |

### Notes du Release
Le workflow génère automatiquement une description complète avec :
- Changements de la version
- Configuration requise
- Instructions d'installation
- Fonctionnalités principales
- Licence

---

## ⚙️ Personnalisation

### Changer le nom de l'application
Modifiez dans :
- `Package.swift` : `name: "MLXForAll"`
- `Resources/Info.plist` : `CFBundleName`, `CFBundleDisplayName`
- `build_release.sh` : `PROJECT_NAME="MLXForAll"`

### Changer l'icône
- Modifiez `create_icon_simple.py` pour changer le design
- Ou remplacez `Resources/Images/app_icon_1024.png`

### Changer la mise en page du DMG
Modifiez dans `build_release.sh` les paramètres de `create-dmg` :
```bash
--window-size 600 400
--icon-size 100
--icon "$PROJECT_NAME.app" 150 190
--icon "Applications" 450 190
```

---

## 🔧 Dépannage

### Le workflow ne se déclenche pas
- Vérifiez que le tag suit le format `v*` (ex: `v2.0.0`)
- Vérifiez que le workflow a les permissions dans `.github/workflows/build_dmg.yml`
- Vérifiez que le dépôt est public ou que le token a les bonnes permissions

### Le build échoue
- Vérifiez les logs dans GitHub Actions
- Vérifiez que `swift build` fonctionne localement
- Vérifiez que toutes les dépendances sont installées

### Le DMG n'est pas dans le release
- Vérifiez que le workflow a terminé avec succès
- Vérifiez que le fichier `build/dmg/MLXForAll-2.0.0.dmg` existe
- Vérifiez les permissions du token GitHub

---

## 📊 Statut Actuel

| Élément | Statut | Détails |
|---------|--------|---------|
| ✅ Workflow | Configuré | `build_dmg.yml` |
| ✅ Scripts | Prêts | `build_release.sh`, `create_icon_simple.py` |
| ✅ Configuration | Complète | `Package.swift`, `Info.plist` |
| ✅ Tag | Créé | `v2.0.0` |
| ⏳ Release GitHub | En attente | À créer via workflow |

---

## 🎉 Prochaines Étapes

1. **Pousser le tag** : `git push origin v2.0.0`
2. **Attendre le workflow** : Il s'exécutera automatiquement
3. **Vérifier le release** : Sur https://github.com/MrFlappy0/MacApp/releases
4. **Télécharger le DMG** : Depuis le release

---

## 📞 Aide

- **Workflow** : [.github/workflows/build_dmg.yml](.github/workflows/build_dmg.yml)
- **Documentation** : [DMG_INFO.md](DMG_INFO.md)
- **Build** : [BUILD.md](BUILD.md)
- **Issues** : [MrFlappy0/MacApp/issues](https://github.com/MrFlappy0/MacApp/issues)
