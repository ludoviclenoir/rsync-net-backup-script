# Rsync.net Backup Script

## Introduction

Ce dépôt contient un script Bash conçu pour automatiser la sauvegarde de fichiers locaux vers un serveur distant via `rsync` en utilisant les services de `rsync.net`. Ce script est idéal pour ceux qui souhaitent utiliser `rsync.net` comme solution de sauvegarde sécurisée. Il inclut également un script pour sauvegarder vos bases de données MySQL.

## Fonctionnalités

- **Sauvegarde avec `rsync`** : Utilisation de `rsync` pour effectuer des sauvegardes incrémentielles vers `rsync.net`.
- **Sauvegarde de bases de données** : Sauvegarde toutes les bases de données MySQL ou une base de données spécifique, puis synchronise les fichiers de sauvegarde avec le serveur `rsync.net`.
- **Gestion des verrous** : Empêche l'exécution simultanée de plusieurs instances du script de sauvegarde.
- **Notifications par e-mail** : Envoi d'un e-mail en cas d'erreur durant le processus de sauvegarde.

## Prérequis

- Un compte `rsync.net`.
- Serveur avec accès SSH.
- Utilisateur avec des permissions `sudo`.
- `rsync` et `mysqldump` installés sur le système local.

## Installation

1. Clonez ce dépôt sur votre serveur local :

   ```bash
   git clone https://github.com/ludoviclenoir/rsync-net-backup-script.git
   cd rsync-net-backup-script
   ```

2. Modifiez les variables dans le script `backup_script.sh` pour qu'elles correspondent à votre configuration :

   - `ALERT_EMAIL` : Adresse e-mail pour les notifications d'erreur.
   - `BACKUP_DIR` : Chemin vers le répertoire que vous souhaitez sauvegarder.
   - `RSYNC_USER` et `RSYNC_SERVER` : Informations de connexion à votre compte `rsync.net`.
   - `REMOTE_BASE_DIR` : Chemin distant sur le serveur `rsync.net` où les fichiers seront sauvegardés.

3. Modifiez les variables dans le script `databases_backups.sh` pour qu'elles correspondent à votre configuration :

   - `DB_USER` et `DB_PASSWORD` : Informations de connexion à votre serveur MySQL.
   - `BACKUP_DIR` : Chemin local où les fichiers de sauvegarde des bases de données seront stockés.
   - `SPECIFIC_DB` : (Optionnel) Nom d'une base de données spécifique à sauvegarder. Laissez vide pour sauvegarder toutes les bases de données.

4. Assurez-vous que les scripts ont les permissions d'exécution :
   ```bash
   chmod +x backup_script.sh
   chmod +x databases_backups.sh
   ```

## Utilisation

Exécutez le script principal en tant que root pour lancer le processus de sauvegarde :

```bash
sudo ./backup_script.sh
```

Utilisation possible avec une tâche CRON

## Contribuer

Les contributions sont les bienvenues !
