# La Rhônelle

Site vitrine pour la boulangerie artisanale La Rhônelle, réalisé en Node.js avec Express et EJS.

Le projet présente une landing page one-page avec :
- une présentation de la boulangerie
- une galerie photo avec carrousel
- un espace Facebook intégré
- un bloc contact / emplacement
- une interface de gestion simple côté serveur

## Stack technique

- Node.js
- Express
- EJS
- SQLite
- bcryptjs
- express-session

## Prérequis

- Node.js 18+
- npm
- Windows ou Linux

## Déploiement rapide

### Windows

Depuis PowerShell :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

Pour démarrer sans lancer automatiquement le serveur :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1 -SkipStart
```

### Linux / Ubuntu / Debian

Depuis le terminal :

```bash
chmod +x deploy.sh
./deploy.sh
```

Pour ne pas démarrer le serveur automatiquement :

```bash
chmod +x deploy.sh
./deploy.sh --skip-start
```

## Installation manuelle

1. Clone le projet
2. Ouvrir le dossier du projet
3. Installer les dépendances :

```bash
npm install
```

## Lancer le site

Mode local standard :

```bash
npm start
```

Mode développement avec rechargement automatique :

```bash
npm run dev
```

Le site sera ensuite disponible sur :

```text
http://localhost:3000
```

## Structure du projet

```text
.
├── deploy.ps1
├── deploy.sh
├── public/
│   ├── css/
│   ├── images/
│   └── js/
├── views/
│   ├── pages/
│   └── partials/
├── data/
│   └── app.db
├── .env.example
├── package.json
├── README.md
├── server.js
└──
```

## Base de données

Le site utilise SQLite pour stocker les données locales.

Une base est créée automatiquement au démarrage dans :

```text
data/app.db
```

## Comptes inclus

Un compte gestionnaire est créé automatiquement au démarrage :

- username : `manager`
- password : `admin123`

## Personnalisation

Les éléments principaux à modifier sont :
- le texte marketing dans [views/pages/index.ejs](views/pages/index.ejs)
- le style dans [public/css/main.css](public/css/main.css)
- les images dans [public/images](public/images)
- le lien Facebook dans les vues et le footer

## Notes

Ce projet est conçu comme un site vitrine local et léger, facile à faire évoluer pour un usage réel avec ajout de CMS, paiement, ou back-office plus complet.
