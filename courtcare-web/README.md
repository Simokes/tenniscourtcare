# CourtCare Web

Application web de gestion de club de tennis. Migration Next.js depuis Flutter.

## Stack technique

- Next.js 16 + React 19 + TypeScript
- Firebase (Firestore, Auth)
- Zustand (UI state)
- TanStack Query v5
- Tailwind CSS v4
- Recharts (statistiques)
- FullCalendar (calendrier evenements)
- Zod + React Hook Form (validation)

## Setup local

### 1. Cloner le repo

git clone https://github.com/Simokes/tenniscourtcare.git
cd tenniscourtcare/courtcare-web

### 2. Variables d'environnement

cp .env.example .env.local
# Remplir les valeurs Firebase dans .env.local

### 3. Installer les dependances

npm install

### 4. Lancer en developpement

npm run dev
# Ouvrir http://localhost:3000

## Structure des dossiers

src/
  app/          Pages Next.js (App Router)
  components/   Composants partagés (AppLayout, AppSidebar)
  core/
    firebase/   Config client + admin
    hooks/      Hooks React (useAuth, usePermission, feature hooks)
    selectors/  Fonctions pures de selection/filtrage
    stores/     Zustand stores (auth, ui, stats)
    utils/      Logger, helpers
  data/         Repositories Firestore + mappers
  domain/       Entites TypeScript, enums, logique metier pure
  features/     Hooks par feature (home, terrain, maintenance, stock...)
  middleware.ts Verification JWT session

## Commandes

npm run dev      Serveur developpement
npm run build    Build production
npm run lint     Linter ESLint
npm test         Tests unitaires (Vitest)

## Variables d'environnement

Voir .env.example pour la liste complete des variables requises.

Les variables NEXT_PUBLIC_* sont exposees au navigateur.
Les variables FIREBASE_ADMIN_* ne doivent JAMAIS etre exposees cote client.

## Deploy

Le projet est configure pour Vercel (region cdg1 -- Paris).
Ajouter toutes les variables de .env.example dans les settings Vercel.

Deployer: git push sur master declenche un deploiement automatique via Vercel GitHub integration.

## Firebase Security Rules

Les regles Firestore sont dans firestore.rules a la racine du repo.
Deployer avec: firebase deploy --only firestore:rules