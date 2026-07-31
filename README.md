# <img src="Resources/Images/app_icon_1024.png" alt="MLX for All" width="128" align="left"> MLX for All

**L'application IA ultime pour macOS - Optimisée pour Apple Silicon (M1/M2/M3/M5)**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M1/M2/M3/M5-green.svg)](https://www.apple.com/m1/)
[![Swift 5.10+](https://img.shields.io/badge/Swift-5.10%2B-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MLX 2.0](https://img.shields.io/badge/MLX-2.0-purple.svg)](https://github.com/ml-explore/mlx)

---

## 🌟 **Pourquoi MLX for All ?**

MLX for All est une **application IA complète** conçue pour **simplifier et optimiser** l'utilisation des modèles de langage sur macOS. Que vous soyez un développeur, un chercheur ou simplement un passionné d'IA, cette application vous offre :

✅ **Une interface de chat moderne** similaire à ChatGPT
✅ **La gestion complète des modèles** (téléchargement, chargement, configuration)
✅ **L'intégration MCP** pour étendre les capacités de l'IA
✅ **L'optimisation pour Apple Silicon** avec accélération Metal
✅ **TOUT centralisé dans les paramètres** pour une configuration facile

---

## 🚀 **Fonctionnalités Principales**

### 💬 **Chat Avancé**
- **Interface moderne** : Design épuré et intuitif inspiré de ChatGPT
- **Historique des conversations** : Gestion des sessions avec persistance
- **Streaming des réponses** : Affichage progressif des réponses
- **Pièces jointes** : Support pour les fichiers (PDF, texte, images, etc.)
- **Messages système personnalisables** : Configurez le comportement de l'IA

### 🧠 **Gestion des Modèles 2026**
| Fonctionnalité | Description |
|---------------|-------------|
| **Modèles intégrés** | Mistral Large 2026, Apple M5 LLM, MLX Hermes 2, Phi-3, Tiny Llama, Gemma 2 |
| **Téléchargement automatique** | Téléchargez les modèles depuis Hugging Face |
| **Chargement/déchargement** | Gérez la mémoire efficacement |
| **Configuration avancée** | Températures, Top P/K, Beam Search, etc. |
| **Support MLX 2.0** | Intégration native avec le framework MLX |
| **Optimisation M5** | Support complet pour les nouveaux Mac Apple Silicon |

### 🔧 **MCP (Model Context Protocol)**
**TOUS les outils sont configurables dans l'application** :

#### **🌐 Outils Web**
- `web_search` : Recherche sur le web
- `web_fetch` : Récupération de contenu d'URL

#### **📁 Outils de Fichiers**
- `file_read` : Lecture de fichiers
- `file_write` : Écriture dans des fichiers
- `file_list` : Liste des fichiers dans un répertoire

#### **⚙️ Outils Système**
- `datetime` : Date et heure actuelles
- `calculator` : Calculs mathématiques

#### **💻 Outils de Code**
- `python_execute` : Exécution de code Python
- `swift_execute` : Exécution de code Swift

### ⚡ **Performances Optimisées**
- **Accélération Metal (MPS)** : Utilisation de Metal Performance Shaders
- **Gestion mémoire intelligente** : Déchargement automatique des modèles inutilisés
- **Précision configurable** : Float32, Float16, Int8
- **Batch processing** : Traitement par lots pour une meilleure efficacité
- **Streaming optimisé** : Génération token par token

---

## 📋 **Configuration Requise**

| Élément | Exigence |
|---------|----------|
| **Système d'exploitation** | macOS 14.0+ (Sonoma ou ultérieur) |
| **Architecture** | Apple Silicon (M1, M2, M3, M5) **recommandé** |
| **RAM** | 8 Go minimum (16 Go recommandé pour les grands modèles) |
| **Stockage** | 10 Go d'espace libre (pour les modèles) |
| **GPU** | Metal-compatible (intégré sur Apple Silicon) |

> ⚠️ **Note** : L'application fonctionne sur les Mac Intel avec macOS 14+, mais les performances seront **beaucoup moins bonnes** qu'avec Apple Silicon.

---

## 🛠️ **Installation**

### 📥 **Méthode 1 : Télécharger le .dmg (Recommandé)**

1. **Télécharger** le dernier `.dmg` depuis les [Releases GitHub](https://github.com/MrFlappy0/MacApp/releases)
2. **Ouvrir** le fichier `.dmg`
3. **Glisser-déposer** `MLX for All` dans le dossier `/Applications`
4. **Lancer** l'application depuis `/Applications`

> ⚠️ **Sécurité macOS** : Si l'application ne s'ouvre pas, faites un **clic droit > Ouvrir** ou autorisez-la dans **Préférences Système > Sécurité et confidentialité**.

---

### 💻 **Méthode 2 : Compiler depuis les sources**

#### **Prérequis**
- [Xcode 15.3+](https://developer.apple.com/xcode/) (avec les outils en ligne de commande)
- [Git](https://git-scm.com/)
- [Swift 5.10+](https://swift.org/)

#### **Étapes**

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/MrFlappy0/MacApp.git
   cd MacApp
   ```

2. **Compiler l'application** :
   ```bash
   # Méthode 1 : Utiliser le script de build
   chmod +x build_dmg.sh
   ./build_dmg.sh
   
   # Méthode 2 : Utiliser Swift Package Manager
   swift build -c release --arch arm64
   ```

3. **Lancer l'application** :
   ```bash
   open .build/arm64-apple-macosx/release/MLXForAll.app
   ```

---

## 🎯 **Utilisation**

### **Premier lancement**
1. **Créer une nouvelle conversation** : Cliquez sur le bouton **+** dans la barre latérale
2. **Sélectionner un modèle** : Allez dans **Paramètres > Gestion des Modèles** pour télécharger un modèle
3. **Configurer l'application** : Tous les paramètres sont dans **Paramètres**

---

### **💬 Utiliser le Chat**

1. **Envoyer un message** : Tapez votre message et appuyez sur **Entrée** ou cliquez sur le bouton d'envoi
2. **Joindre des fichiers** : Cliquez sur l'icône **📎** pour ajouter des fichiers à votre message
3. **Recevoir des réponses** : Les réponses s'affichent en temps réel (streaming)
4. **Utiliser des outils MCP** : L'application utilise automatiquement les outils configurés

---

### **⚙️ Configurer l'Application**

**TOUT est centralisé dans les paramètres** :

#### **1. Apparence**
- **Thème** : Système, Clair, Sombre
- **Langue** : Français, Anglais (selon les préférences système)

#### **2. Modèle et Inférence**
- **Sélection du modèle** : Choisissez parmi les modèles téléchargés
- **Configuration du modèle** :
  - Température (0-2)
  - Top P (0-1)
  - Top K (1-100)
  - Tokens maximum (16-4096)
  - Pénalités (présence, fréquence, répétition)
  - Recherche par faisceau

#### **3. Performances**
- **Accélération Metal** : Activez/désactivez MPS
- **Périphérique** : Auto, CPU, GPU, MPS
- **Précision** : Float32, Float16, Int8
- **Taille du batch** : 1-16
- **Mémoire max** : Pourcentage de mémoire à utiliser

#### **4. MCP (Model Context Protocol)**
- **Activer/désactiver MCP**
- **Configurer les outils** : Activez/désactivez chaque outil individuellement
- **Ajouter des serveurs MCP** : Connectez des serveurs externes

#### **5. Chat**
- **Message système** : Personnalisez le comportement de l'IA
- **Historique** : Gestion des conversations

#### **6. Fichiers**
- **Fichiers récents** : Accès rapide aux fichiers utilisés
- **Gestion des fichiers** : Ouvrir, supprimer, organiser

---

### **🤖 Gérer les Modèles**

1. Allez dans **Paramètres > Gestion des Modèles**
2. **Télécharger un modèle** : Sélectionnez un modèle et cliquez sur **Télécharger**
3. **Charger un modèle** : Sélectionnez un modèle téléchargé et cliquez sur **Charger**
4. **Supprimer un modèle** : Supprimez les modèles que vous n'utilisez plus

**Modèles disponibles (2026)** :
| Modèle | Paramètres | Taille | Auteur |
|--------|------------|-------|--------|
| Mistral Large 2026 | 123B | ~240 Go | Mistral AI |
| Apple M5 LLM | 40B | ~75 Go | Apple |
| Apple M5 Vision | 22B | ~40 Go | Apple |
| MLX Hermes 2 | 30B | ~60 Go | NousResearch |
| MLX Phi-3 | 14B | ~25 Go | Microsoft |
| Tiny Llama 1.1B | 1.1B | ~2 Go | Community |
| Gemma 2 2B | 2B | ~3.5 Go | Google |

---

### **🔧 Configurer MCP**

1. Allez dans **Paramètres > MCP**
2. **Activer MCP** : Activez le protocole
3. **Configurer les outils** : Activez/désactivez les outils selon vos besoins
4. **Ajouter des serveurs** : Connectez des serveurs MCP externes

**Outils intégrés** :
- Recherche web
- Récupération de contenu
- Lecture/écriture de fichiers
- Calculs mathématiques
- Exécution de code (Python, Swift)

---

## 🚀 **Bonnes Pratiques**

### **Optimiser les Performances**

| Problème | Solution |
|----------|----------|
| **Lenteur** | Activez **Metal (MPS)** et utilisez **Float16** |
| **Manque de mémoire** | Réduisez la **taille du batch** ou utilisez **Int8** |
| **Modèle non supporté** | Vérifiez que le modèle est compatible avec MLX 2.0 |
| **Temps de chargement long** | Utilisez le **cache** pour éviter de recharger le modèle |

### **Recommandations par Modèle**

| Modèle | Précision Recommandée | Taille de Batch | Périphérique |
|--------|------------------------|-----------------|-------------|
| **Mistral Large 2026** | Float16 | 1 | MPS |
| **Apple M5 LLM** | Float16 | 1-2 | MPS |
| **MLX Hermes 2** | Float16 | 1-2 | MPS |
| **MLX Phi-3** | Float16 | 1-2 | MPS |
| **Tiny Llama 1.1B** | Float16/Int8 | 2-4 | MPS/CPU |
| **Gemma 2 2B** | Float16/Int8 | 2-4 | MPS/CPU |

---

## 🐛 **Dépannage**

### **Problèmes Courants**

#### ❌ **L'application ne s'ouvre pas**
- **Cause** : macOS bloque les applications non signées.
- **Solution** :
  1. Faites un **clic droit** sur l'application > **Ouvrir**
  2. Allez dans **Préférences Système > Sécurité et confidentialité** et autorisez l'application.

#### ❌ **Erreur : "Model not found"**
- **Cause** : Le modèle n'est pas téléchargé.
- **Solution** :
  1. Allez dans **Paramètres > Gestion des Modèles**
  2. Téléchargez le modèle souhaité

#### ❌ **Erreur : "Out of Memory"**
- **Cause** : La taille du batch ou la précision est trop élevée pour votre RAM.
- **Solution** :
  1. Réduisez la **taille du batch** (ex: passez de 4 à 1)
  2. Utilisez une **précision plus faible** (ex: Int8 au lieu de Float16)
  3. Fermez d'autres applications gourmandes en mémoire

#### ❌ **Performances médiocres**
- **Cause** : Le périphérique n'est pas optimisé ou Metal n'est pas activé.
- **Solution** :
  1. Sélectionnez **MPS** comme périphérique dans les paramètres
  2. Activez **Accélération Metal**
  3. Vérifiez que votre Mac est compatible avec Metal

---

## 📚 **Architecture Technique**

### **Structure du Projet**

```
MLXForAll/
├── Sources/
│   ├── App/
│   │   └── MLXForAllApp.swift          # Point d'entrée
│   ├── Chat/
│   │   └── ChatView.swift               # Interface de chat
│   ├── Settings/
│   │   ├── AppSettings.swift            # Configuration centralisée
│   │   ├── SettingsView.swift           # Vue des paramètres
│   │   ├── ModelsView.swift             # Gestion des modèles
│   │   ├── MCPView.swift                # Configuration MCP
│   │   └── FilesView.swift              # Gestion des fichiers
│   ├── Network/
│   │   ├── HuggingFaceClient.swift      # Client Hugging Face
│   │   └── MLXIntegration.swift         # Intégration MLX
│   └── MCP/
│       └── MCPClient.swift              # Client MCP
├── Resources/
│   ├── Images/                          # Icônes de l'application
│   └── Info.plist                       # Configuration
├── Assets.xcassets/
│   └── AppIcon.appiconset/             # Icônes pour toutes les tailles
├── Package.swift                       # Dépendances
├── build_dmg.sh                        # Script de création du .dmg
└── .github/
    └── workflows/
        └── build_and_release.yml         # Workflow CI/CD
```

### **Technologies Utilisées**

| Technologie | Version | Utilisation |
|-------------|---------|-------------|
| **Swift** | 5.10+ | Langage principal |
| **SwiftUI** | - | Interface utilisateur |
| **MLX** | 2.0 | Framework d'IA |
| **Metal** | - | Accélération matérielle |
| **Hugging Face** | - | Téléchargement des modèles |

---

## 🤝 **Contribuer**

Les contributions sont les bienvenues ! Voici comment contribuer :

### **Signaler un Bug**
1. Vérifiez que le bug n'a pas déjà été signalé dans les [Issues](https://github.com/MrFlappy0/MacApp/issues)
2. Créez une nouvelle **Issue** avec :
   - Une **description claire** du problème
   - Les **étapes pour reproduire**
   - Votre **configuration** (macOS, modèle de Mac, version de l'app)

### **Proposer une Fonctionnalité**
1. Créez une **Issue** avec le label `enhancement`
2. Décrivez la fonctionnalité et son utilité

### **Soumettre une Pull Request**
1. **Forkez** le dépôt
2. Créez une **branche** pour votre fonctionnalité
3. **Commitez** vos changements
4. **Poussez** vers votre fork
5. Ouvrez une **Pull Request** vers la branche `main`

---

## 📜 **Licence**

Ce projet est sous **Licence MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🙏 **Remerciements**

Un grand merci à :
- **[MLX Framework](https://github.com/ml-explore/mlx)** : Le framework de Machine Learning qui rend tout cela possible
- **[Apple](https://developer.apple.com/)** : Pour Swift, SwiftUI, Metal et macOS
- **[Hugging Face](https://huggingface.co/)** : Pour l'hébergement des modèles
- **[Mistral AI](https://mistral.ai/)** : Pour les modèles de langage avancés
- **La communauté Open Source** : Pour les contributions et le support

---

## 📞 **Contact**

Pour toute question, suggestion ou rapport de bug :
- **GitHub Issues** : [Ouvrir une Issue](https://github.com/MrFlappy0/MacApp/issues)
- **GitHub Discussions** : [Discuter](https://github.com/MrFlappy0/MacApp/discussions)

---

## 📅 **Journal des Versions**

| Version | Date | Changements |
|---------|------|-------------|
| **2.0.0** | 2026 | Refonte complète : MLX for All, support 2026, MCP, interface centralisée |
| **1.0.0** | 2024 | Version initiale : Support de base pour MLX |

---

**✨ MLX for All - L'IA sur macOS, simplifiée et optimisée pour Apple Silicon ✨**

*Conçu avec ❤️ pour la communauté du Machine Learning*
