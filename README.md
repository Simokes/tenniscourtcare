# CourtCare 🎾

**CourtCare** est une application mobile Flutter conçue pour simplifier la gestion et le suivi de la maintenance des courts de tennis. Elle permet aux responsables de clubs de suivre précisément l'utilisation des matériaux (manto, sottomanto, silice) et d'anticiper les besoins de maintenance en fonction de la météo.

## 🏗️ Architecture
L'application suit une architecture en couches stricte pour garantir la maintenabilité et la testabilité :
- **Domain** : Entités métiers immutables et logique pure.
- **Data** : Persistance locale avec **Drift (SQLite)** et mappers pour la conversion Domaine/DB.
- **Infrastructure** : Services externes (API Météo).
- **Presentation** : État géré par **Riverpod (v2)** et interface utilisateur réactive.

## 🚀 Fonctionnalités Actuelles

### 📊 Tableau de Bord (Home)
- Vue d'ensemble des terrains du club.
- Résumé des consommations de matériaux pour le mois en cours.
- Navigation centralisée via un menu latéral (Drawer).

### 🛠️ Gestion des Maintenances
- Enregistrement des opérations (Arrosage, Brossage, Recharge, etc.).
- **Règles métier intelligentes** : Validation automatique des matériaux selon le type de surface (Terre battue, Synthétique, Dur).
- Historique complet par terrain.

### 📦 Gestion du Stock
- Suivi du matériel fixe et des consommables personnalisés.
- Ajustement rapide des quantités (±1 / ±5).
- **Alertes Stock Bas** : Indicateurs visuels basés sur des seuils minimums configurables.
- Recherche et filtrage dynamique.

### 🌦️ Intégration Météo
- Récupération en temps réel des conditions météo (température, humidité, précipitations).
- Heuristiques métier pour déterminer si un terrain est gelé ou impraticable.
- Enregistrement d'un "snapshot" météo lors de chaque maintenance.

### ⚙️ Configuration & Export
- Paramétrage des coordonnées GPS du club pour une météo précise.
- Gestion complète du parc de terrains (Ajout/Modification/Suppression).
- **Export CSV** : Exportation des données de maintenance pour analyse externe.

## 🛠️ Stack Technique
- **Framework** : Flutter
- **Gestion d'état** : Riverpod
- **Base de données** : Drift (SQLite)
- **Localisation** : Intl
- **API Météo** : Open-Meteo

## 📅 Roadmap & Futures Implémentations

### 🟢 Court Terme (Prochaines étapes)
- [ ] **Historique des Stocks** : Journal des entrées/sorties pour une traçabilité totale.
- [ ] **Photos de maintenance** : Possibilité de joindre des photos avant/après chaque opération.
- [ ] **Rapports PDF** : Génération de rapports mensuels formatés pour les réunions de comité.

### 🟡 Moyen Terme
- [ ] **Notifications Push** : Rappels automatiques pour les tâches récurrentes (ex: brossage hebdomadaire).
- [ ] **Mode Multi-Clubs** : Gestion de plusieurs sites pour les groupements de clubs.
- [ ] **Calcul des coûts** : Estimation financière des maintenances basée sur le prix unitaire des consommables.

### 🔴 Long Terme
- [ ] **Synchronisation Cloud** : Sauvegarde et partage des données entre plusieurs membres de l'équipe.
- [ ] **Analyses prédictives** : Suggestion de maintenance basée sur les prévisions météo à 7 jours.

## 📥 Installation

1. Assurez-vous d'avoir Flutter installé sur votre machine.
2. Clonez le dépôt.
3. Exécutez `flutter pub get`.
4. Lancez le générateur de code : `flutter pub run build_runner build`.
5. Lancez l'application : `flutter run`.

---
*Développé avec ❤️ pour les passionnés de tennis.*
