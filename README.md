# <img src="Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png" alt="MLX Mac App" width="128" align="left"> MLX Mac App

**Une application macOS ultra-optimisée pour exécuter des modèles MLX (Machine Learning eXploration) avec des performances maximales sur Apple Silicon.**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1/M2/M3-green.svg)](https://www.apple.com/m1/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MLX Framework](https://img.shields.io/badge/MLX-Framework-purple.svg)](https://github.com/ml-explore/mlx)

---,

## 🌟 **Pourquoi MLX Mac App ?**

MLX Mac App est conçue pour **simplifier et optimiser** l'exécution de modèles de *Machine Learning* sur macOS. Que vous soyez un chercheur, un développeur ou un passionné d'IA, cette application vous permet de :

✅ **Charger et gérer** plusieurs modèles MLX en parallèle
✅ **Exécuter des inférences** sur des modèles de vision, NLP, audio et diffusion
✅ **Surveiller les performances** en temps réel (temps d'inférence, mémoire, GPU)
✅ **Traiter des lots de données** (*batch processing*) avec une optimisation maximale
✅ **Profiter de l'accélération matérielle** via Metal (MPS) sur Apple Silicon

---

## 🚀 **Fonctionnalités Principales**

### 🧠 **Gestion des Modèles**
| Fonctionnalité | Description |
|---------------|-------------|
| **Chargement dynamique** | Chargez et déchargez des modèles à la volée pour économiser la mémoire |
| **Cache intelligent** | Les modèles téléchargés sont mis en cache pour un accès rapide |
| **Support multi-modèles** | Exécutez plusieurs modèles simultanément |
| **Téléchargement automatique** | Téléchargez des modèles depuis Hugging Face ou des dépôts personnalisés |
| **Configuration flexible** | Ajustez les paramètres des modèles (précision, batch size, etc.) |

### ⚡ **Moteur d'Inférence**
- **Types de modèles supportés** :
  - 🖼️ **Vision** : ResNet, ViT, ConvNeXt, EfficientNet, etc.
  - 📝 **NLP** : BERT, Llama, Mistral, GPT, etc.
  - 🎙️ **Audio** : Whisper, Wav2Vec, etc.
  - 🎨 **Diffusion** : Stable Diffusion, Flux, etc.
  - 🔧 **Custom** : Chargez vos propres modèles MLX

- **Optimisations** :
  - Accélération **Metal (MPS)** pour Apple Silicon
  - Précision configurable (**Float32**, **Float16**, **Int8**)
  - *Batch processing* avec taille de lot ajustable
  - Gestion automatique de la mémoire

### 📊 **Surveillance des Performances**
- **Métriques en temps réel** :
  - Temps d'inférence (ms)
  - Utilisation de la mémoire (RAM/GPU)
  - Charge CPU/GPU
  - Débit (inferences/sec)
- **Historique des performances** :
  - Graphiques interactifs
  - Export des données en CSV/JSON
  - Identification des goulots d'étranglement
- **Profilage par couche** :
  - Analyse fine des temps d'exécution
  - Détection des couches les plus lentes

### 🎨 **Interface Utilisateur (SwiftUI)**
- **Design moderne** : Interface épurée et intuitive, optimisée pour macOS Sonoma+
- **Mode sombre/clair** : Prise en charge native des thèmes macOS
- **Fenêtres redimensionnables** : Adapté aux écrans Retina et aux configurations multi-écrans
- **Notifications** : Alertes pour les erreurs, les téléchargements terminés, etc.

#### **Onglets principaux** :
| Onglet | Description |
|--------|-------------|
| 🏠 **Accueil** | Vue d'ensemble avec modèles récents et statistiques |
| 🤖 **Modèles** | Parcourir, télécharger et gérer les modèles |
| ⚡ **Inférence** | Interface interactive pour tester les modèles |
| 📊 **Performances** | Tableau de bord avec graphiques et métriques |
| ⚙️ **Paramètres** | Configuration de l'application et des modèles |

---

## 📋 **Configuration Requise**

| Élément | Exigence |
|---------|----------|
| **Système d'exploitation** | macOS 14.0+ (Sonoma ou ultérieur) |
| **Architecture** | Apple Silicon (M1, M2, M3 ou ultérieur) **recommandé** |
| **RAM** | 8 Go minimum (16 Go recommandé pour les grands modèles) |
| **Stockage** | 10 Go d'espace libre (pour les modèles et caches) |
| **GPU** | Metal-compatible (intégré sur Apple Silicon) |
| **Xcode** | 15.0+ (uniquement pour le développement) |

> ⚠️ **Note** : L'application fonctionne sur les Mac Intel avec macOS 14+, mais les performances seront **beaucoup moins bonnes** qu'avec Apple Silicon.

---

## 🛠️ **Installation**

### 📥 **Méthode 1 : Télécharger le .dmg (Recommandé)**

1. **Télécharger** le dernier `.dmg` depuis les [Releases GitHub](https://github.com/MrFlappy0/MacApp/releases)
2. **Ouvrir** le fichier `.dmg`
3. **Glisser-déposer** `MLX Mac App` dans le dossier `/Applications`
4. **Lancer** l'application depuis `/Applications`

> ⚠️ **Sécurité macOS** : Si l'application ne s'ouvre pas, faites un **clic droit > Ouvrir** ou autorisez-la dans **Préférences Système > Sécurité et confidentialité**.

---

### 💻 **Méthode 2 : Compiler depuis les sources**

#### **Prérequis**
- [Xcode 15.0+](https://developer.apple.com/xcode/) (avec les outils en ligne de commande)
- [Git](https://git-scm.com/)
- [Swift 5.9+](https://swift.org/)

#### **Étapes**

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/MrFlappy0/MacApp.git
   cd MacApp
   ```

2. **Compiler l'application** :
   ```bash
   # Méthode 1 : Utiliser le script de build
   ./build.sh release
   
   # Méthode 2 : Utiliser Swift Package Manager
   swift build -c release --arch arm64
   ```

3. **Lancer l'application** :
   ```bash
   # Depuis le dossier de build
   open .build/arm64-apple-macosx/release/MLXMacApp.app
   
   # Ou utiliser le script
   ./build.sh run
   ```

---

### 📦 **Méthode 3 : Créer un .dmg pour la distribution**

Pour créer un `.dmg` prêt à être distribué, utilisez le script dédié :

```bash
# Donner les permissions d'exécution (si ce n'est pas déjà fait)
chmod +x create_dmg.sh

# Exécuter le script
./create_dmg.sh
```

> ✅ **Résultat** : Le fichier `MLXMacApp-1.0.0.dmg` sera généré dans `build/dmg/`.

> 💡 **Pour une meilleure mise en page** : Installez [`create-dmg`](https://github.com/create-dmg/create-dmg) via Homebrew :
> ```bash
> brew install create-dmg
> ```

---

## 🎯 **Utilisation**

### **Premier lancement**
1. **Autoriser les permissions** :
   - Accès au réseau (pour télécharger les modèles)
   - Accès au dossier de téléchargements (si vous souhaitez sauvegarder les résultats)
2. **Configurer les paramètres** :
   - Sélectionnez le **périphérique** (Auto, CPU, GPU, MPS)
   - Choisissez la **précision** (Float32, Float16, Int8)
   - Ajustez la **taille du batch** en fonction de votre RAM

---

### **📥 Télécharger et charger un modèle**

1. Allez dans l'onglet **🤖 Modèles**
2. Parcourez la liste des modèles disponibles (ou ajoutez un dépôt personnalisé)
3. Cliquez sur **⬇️ Télécharger** pour télécharger le modèle
4. Une fois téléchargé, cliquez sur **▶️ Charger** pour le charger en mémoire
5. Le modèle est maintenant prêt pour l'inférence !

> 💡 **Astuce** : Les modèles sont stockés dans `~/Library/Application Support/MLXMacApp/models/`.

---

### **⚡ Exécuter une inférence**

1. Allez dans l'onglet **⚡ Inférence**
2. Sélectionnez un **modèle chargé** dans la liste déroulante
3. **Entrez votre input** :
   - Pour les modèles **NLP** : Saisissez du texte
   - Pour les modèles **Vision** : Glissez-déposez une image ou utilisez la webcam
   - Pour les modèles **Audio** : Enregistrez ou importez un fichier audio
4. Cliquez sur **▶️ Exécuter l'inférence**
5. Les résultats s'afficheront dans le panneau de droite

---

### **📊 Surveiller les performances**

1. Allez dans l'onglet **📊 Performances**
2. Lancez une ou plusieurs inférences
3. Observez les métriques en temps réel :
   - **Temps d'inférence** (en ms)
   - **Utilisation mémoire** (RAM/GPU)
   - **Charge CPU/GPU**
   - **Débit** (inferences/sec)
4. Utilisez les graphiques pour identifier les goulots d'étranglement

---

### **🔄 Batch Processing (Traitement par lots)**

1. Préparez un **fichier CSV/JSON** avec vos inputs (ex: liste d'images ou de textes)
2. Allez dans l'onglet **⚡ Inférence**
3. Activez le **mode batch**
4. Sélectionnez votre fichier d'input
5. Configurez la **taille du batch** (nombre d'inputs traités simultanément)
6. Cliquez sur **▶️ Exécuter le batch**
7. Les résultats seront sauvegardés dans un fichier (CSV/JSON)

---

## ⚙️ **Configuration Avancée**

### **Paramètres Généraux**

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| **Périphérique** | Choix du périphérique d'exécution | Auto |
| **Précision** | Précision des calculs | Float16 |
| **Taille du batch** | Nombre d'inputs traités en parallèle | 1 |
| **Mémoire max** | Limite d'utilisation mémoire (Go) | 8 |
| **Accélération Metal** | Activer/désactiver MPS | ✅ Activé |
| **Mode sombre** | Suivre le thème macOS | ✅ Activé |

### **Présélections de Modèles**

| Présélection | Description | Cas d'usage |
|--------------|-------------|-------------|
| **Haute Performance** | Optimisé pour la vitesse | Benchmark, production |
| **Économique en Mémoire** | Optimisé pour la RAM | Grands modèles, peu de RAM |
| **Équilibré** | Compromis vitesse/mémoire | Usage général |
| **Haute Précision** | Précision maximale | Résultats critiques |

---

## 🔧 **Personnalisation**

### **Ajouter un modèle personnalisé**

1. Placez votre modèle dans le dossier :
   ```
   ~/Library/Application Support/MLXMacApp/models/custom/
   ```
2. Créez un fichier `model.json` avec la configuration :
   ```json
   {
     "name": "Mon Modèle Custom",
     "type": "nlp",
     "path": "chemin/vers/le/modèle",
     "input_shape": [1, 512],
     "output_shape": [1, 10],
     "description": "Description de mon modèle"
   }
   ```
3. Redémarrez l'application : votre modèle apparaîtra dans la liste.

---

### **Modifier les paramètres par défaut**

Les paramètres par défaut peuvent être modifiés dans le fichier :
```
~/Library/Application Support/MLXMacApp/config.json
```

Exemple :
```json
{
  "default_device": "mps",
  "default_precision": "float16",
  "batch_size": 4,
  "max_memory_gb": 12,
  "enable_metal": true
}
```

---

## 🚀 **Bonnes Pratiques**

### **Optimiser les Performances**

| Problème | Solution |
|----------|----------|
| **Lenteur** | Activez **Metal (MPS)** et utilisez **Float16** |
| **Manque de mémoire** | Réduisez la **taille du batch** ou utilisez **Int8** |
| **Modèle non supporté** | Vérifiez que le modèle est compatible avec MLX |
| **Temps de chargement long** | Utilisez le **cache** pour éviter de recharger le modèle |

### **Recommandations par Modèle**

| Type de Modèle | Précision Recommandée | Taille de Batch | Périphérique |
|----------------|------------------------|-----------------|-------------|
| **Vision (ResNet, ViT)** | Float16 | 4-8 | MPS |
| **NLP (Llama, Mistral)** | Float16 | 1-2 | MPS |
| **Audio (Whisper)** | Float32 | 1 | MPS |
| **Diffusion (Stable Diffusion)** | Float16 | 1 | MPS |

---

## 🐛 **Dépannage**

### **Problèmes Courants**

#### ❌ **L'application ne s'ouvre pas**
- **Cause** : macOS bloque les applications non signées.
- **Solution** :
  1. Faites un **clic droit** sur l'application > **Ouvrir**
  2. Allez dans **Préférences Système > Sécurité et confidentialité** et autorisez l'application.

#### ❌ **Erreur : "Model not found"**
- **Cause** : Le modèle n'est pas téléchargé ou le chemin est incorrect.
- **Solution** :
  1. Vérifiez que le modèle est dans le dossier `~/Library/Application Support/MLXMacApp/models/`
  2. Re-téléchargez le modèle depuis l'onglet **Modèles**

#### ❌ **Erreur : "Out of Memory"**
- **Cause** : La taille du batch ou la précision est trop élevée pour votre RAM.
- **Solution** :
  1. Réduisez la **taille du batch** (ex: passez de 8 à 2)
  2. Utilisez une **précision plus faible** (ex: Float16 au lieu de Float32)
  3. Fermez d'autres applications gourmandes en mémoire

#### ❌ **Performances médiocres**
- **Cause** : Le périphérique n'est pas optimisé ou Metal n'est pas activé.
- **Solution** :
  1. Sélectionnez **MPS** comme périphérique dans les paramètres
  2. Activez **Metal Acceleration**
  3. Vérifiez que votre Mac est compatible avec Metal (Apple Silicon ou Mac Intel récent)

#### ❌ **Le .dmg ne se monte pas**
- **Cause** : Le fichier est corrompu ou incomplet.
- **Solution** :
  1. Supprimez le fichier `.dmg` et relancez `./create_dmg.sh`
  2. Vérifiez que vous avez assez d'espace disque
  3. Utilisez `hdiutil verify MLXMacApp-1.0.0.dmg` pour vérifier l'intégrité

---

### **Mode Debug**

Pour activer le **mode debug** (logs détaillés) :

1. **Depuis l'interface** :
   - Allez dans **⚙️ Paramètres > Avancé**
   - Activez **Mode Debug**

2. **Depuis la ligne de commande** :
   ```bash
   # Lancer l'application avec des logs étendus
   MLXMACAPP_DEBUG=1 open MLXMacApp.app
   ```

Les logs seront sauvegardés dans :
```
~/Library/Logs/MLXMacApp/debug.log
```

---

## 📚 **Architecture Technique**

### **Structure du Projet**

```
MLXMacApp/
├── Sources/
│   ├── Main/
│   │   └── main.swift                 # Point d'entrée de l'application
│   ├── App/
│   │   └── MLXMacAppApp.swift         # Configuration de l'app SwiftUI
│   ├── Models/
│   │   ├── MLXModel.swift             # Définition des modèles MLX
│   │   ├── ModelLoader.swift          # Chargement et gestion des modèles
│   │   └── InferenceEngine.swift      # Moteur d'inférence
│   ├── Utilities/
│   │   ├── PerformanceMonitor.swift   # Surveillance des performances
│   │   ├── MemoryManager.swift        # Gestion de la mémoire
│   │   └── BatchProcessor.swift       # Traitement par lots
│   ├── ViewModels/
│   │   ├── AppState.swift             # État global de l'application
│   │   ├── ModelViewModel.swift       # Logique pour les modèles
│   │   └── InferenceViewModel.swift   # Logique pour l'inférence
│   └── Views/
│       ├── ContentView.swift          # Vue principale
│       ├── ModelSelectionView.swift   # Sélection des modèles
│       ├── InferenceView.swift        # Interface d'inférence
│       ├── PerformanceView.swift      # Tableau de bord des performances
│       └── SettingsView.swift          # Paramètres
├── Resources/
│   ├── Info.plist                     # Configuration de l'app
│   └── Assets.xcassets/               # Ressources (icônes, images)
├── Config/
│   ├── Debug.xcconfig                 # Configuration Debug
│   └── Release.xcconfig               # Configuration Release
├── Package.swift                      # Dépendances Swift Package Manager
├── build.sh                           # Script de build
└── create_dmg.sh                      # Script de création du .dmg
```

### **Composants Clés**

| Composant | Rôle |
|-----------|------|
| **`ModelLoader`** | Charge, décharge et met en cache les modèles MLX |
| **`InferenceEngine`** | Exécute les inférences avec optimisations (MPS, batch, etc.) |
| **`PerformanceMonitor`** | Mesure et rapporte les métriques de performance |
| **`MemoryManager`** | Gère l'allocation et la libération de la mémoire |
| **`BatchProcessor`** | Traite plusieurs inputs simultanément |

---

## 🤝 **Contribuer**

Les contributions sont les bienvenues ! Voici comment contribuer :

### **Signaler un Bug**
1. Vérifiez que le bug n'a pas déjà été signalé dans les [Issues](https://github.com/MrFlappy0/MacApp/issues)
2. Créez une nouvelle **Issue** avec :
   - Une **description claire** du problème
   - Les **étapes pour reproduire**
   - Votre **configuration** (macOS, modèle de Mac, version de l'app)
   - Les **logs** (si disponibles)

### **Proposer une Fonctionnalité**
1. Créez une **Issue** avec le label `enhancement`
2. Décrivez la fonctionnalité et son utilité
3. Discutez-en avec la communauté

### **Soumettre une Pull Request**
1. **Forkez** le dépôt
2. Créez une **branche** pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. **Commitez** vos changements (`git commit -m "Ajout de ma fonctionnalité"`)
4. **Poussez** vers votre fork (`git push origin feature/ma-fonctionnalite`)
5. Ouvrez une **Pull Request** vers la branche `main`

### **Règles de Contribution**
- Respectez le **style de code** existant (Swift, conventions Apple)
- Ajoutez des **tests** pour les nouvelles fonctionnalités
- Mettez à jour la **documentation** si nécessaire
- Utilisez des **messages de commit clairs**

---

## 📜 **Licence**

Ce projet est sous **Licence MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

```
MIT License

Copyright (c) 2024 MrFlappy0

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 **Remerciements**

Un grand merci à :

- **[MLX Framework](https://github.com/ml-explore/mlx)** : Le framework de Machine Learning qui rend tout cela possible.
- **[Apple](https://developer.apple.com/)** : Pour Swift, SwiftUI, Metal et macOS.
- **[Hugging Face](https://huggingface.co/)** : Pour l'hébergement des modèles.
- **La communauté Open Source** : Pour les contributions et le support.

---

## 📞 **Contact**

Pour toute question, suggestion ou rapport de bug :

- **GitHub Issues** : [Ouvrir une Issue](https://github.com/MrFlappy0/MacApp/issues)
- **GitHub Discussions** : [Discuter](https://github.com/MrFlappy0/MacApp/discussions)
- **Email** : contact@mrflappy0.com (si disponible)

---

## 📅 **Journal des Versions**

| Version | Date | Changements |
|---------|------|-------------|
| **1.0.0** | Juillet 2024 | Version initiale : Support de base pour MLX, SwiftUI, Metal |

---

**✨ MLX Mac App - L'IA sur macOS, simplifiée et optimisée ✨**

*Conçu avec ❤️ pour la communauté du Machine Learning*
