# Court Care 🎾

**Court Care** est une application Flutter moderne conçue pour simplifier la gestion et le suivi de la maintenance des courts de tennis. Elle permet aux responsables de clubs de suivre précisément l'utilisation des matériaux, d'analyser les statistiques de maintenance et d'anticiper les besoins en fonction de la météo.

## 🏗️ Architecture
L'application suit une architecture en couches (Clean Architecture simplifiée) pour garantir la maintenabilité et la testabilité :
- **Domain** : Entités métier (Terrain, Maintenance, StockItem) et logique pure.
- **Data** : Persistance locale avec **Drift (SQLite)**, mappers et implémentations de repositories.
- **Infrastructure** : Services externes (API Météo via Open-Meteo).
- **Presentation** : Interface utilisateur réactive avec **Riverpod** pour la gestion d'état et **GoRouter** pour la navigation.
- **Utils** : Utilitaires pour les dates, l'export CSV, etc.

## 🚀 Fonctionnalités Clés

### 📊 Tableau de Bord & Statistiques
- Vue d'ensemble de l'activité du club.
- Graphiques détaillés (via `fl_chart`) sur l'utilisation des sacs (Manto, Sottomanto, Silice) et les types de maintenance.
- Filtres par période (jour, semaine, mois) et par terrain.

### 🛠️ Gestion des Maintenances
- Enregistrement précis des opérations (Arrosage, Brossage, Recharge, etc.).
- **Liaison intelligente avec le Stock** : L'ajout d'une "Recharge" déduit automatiquement les sacs du stock avec validation de disponibilité.
- Historique complet et filtrable par court.

### 📦 Gestion du Stock
- Suivi en temps réel des consommables (Manto, Sottomanto, Silice) et du matériel.
- Alertes visuelles de stock bas basées sur des seuils configurables.
- Ajustements rapides (+1/-1, +5/-5).

### 🌦️ Météo & Heuristiques
- Intégration de la météo locale pour chaque club (coordonnées GPS configurables).
- Indicateurs métier : terrain gelé ou impraticable basés sur les précipitations et la température.
- Snapshot météo enregistré avec chaque maintenance.

### 🔐 Sécurité & Paramètres
- Système d'authentification sécurisé.
- Configuration des coordonnées du club.
- Gestion du parc de terrains (ajout, modification, suppression).

## 🛠️ Stack Technique
- **Framework** : Flutter
- **État** : Riverpod (StateNotifier, Stream/FutureProvider)
- **Base de données** : Drift (SQLite)
- **Navigation** : GoRouter
- **Graphiques** : fl_chart
- **Design** : Material 3, Google Fonts (Inter)

## 📅 Roadmap & Évolutions

### 🟢 En cours / Finalisé
- [x] Refonte de l'interface avec Material 3 et Drawer.
- [x] Liaison atomique Maintenance ↔ Stock.
- [x] Statistiques avancées et graphiques.
- [x] Gestion multicritère des terrains.

### 🟡 Prochainement
- [ ] **Historique des mouvements de stock** : Journal détaillé des entrées/sorties.
- [ ] **Rapports PDF** : Génération de bilans mensuels pour le comité.
- [ ] **Photos** : Possibilité d'attacher des photos aux maintenances.

### 🔴 Futur
- [ ] **Sync Cloud** : Sauvegarde et synchronisation multi-appareils.
- [ ] **IA Prédictive** : Suggestions de maintenance basées sur les prévisions météo.

## 📥 Installation

1. Cloner le projet : `git clone https://github.com/Simokes/tenniscourtcare.git`
2. Installer les dépendances : `flutter pub get`
3. Générer le code Drift/Riverpod : `flutter pub run build_runner build --delete-conflicting-outputs`
4. Lancer l'application : `flutter run`

---
*Développé avec passion pour l'entretien des terrains de tennis.*
