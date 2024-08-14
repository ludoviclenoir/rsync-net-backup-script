#!/bin/bash

# Script pour sauvegarder les bases de données MySQL

DB_USER="root"  # Nom d'utilisateur MySQL
DB_PASSWORD="password"  # Mot de passe MySQL
BACKUP_DIR="/var/backup/db"  # Répertoire de sauvegarde
SPECIFIC_DB=""  # Nom d'une base de données spécifique à sauvegarder (laissez vide pour sauvegarder toutes les BDD)

log_info() {
  local msg=$1
  [[ -z $msg ]] && return
  local cur_date=$(date "+%c")
  echo "$msg"
  echo -e "$cur_date\tINFO\t$msg" >> "$LOG_FILE"
}

log_error() {
  local msg=$1
  local cur_date=$(date "+%c")
  echo "Error - $msg"
  echo -e "$cur_date\tERROR\t$msg" >> "$LOG_FILE"
}

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p "$BACKUP_DIR"
if [[ $? -ne 0 ]]; then
  log_error "Could not create backup directory $BACKUP_DIR"
  exit 1
fi

# Sauvegarder une base de données spécifique ou toutes les bases de données
if [[ -n "$SPECIFIC_DB" ]]; then
  log_info "Backing up specific database: $SPECIFIC_DB"
  mysqldump -u"$DB_USER" -p"$DB_PASSWORD" --databases "$SPECIFIC_DB" > "$BACKUP_DIR/$SPECIFIC_DB.sql"
  if [[ $? -ne 0 ]]; then
    log_error "Erreur de sauvegarde pour la base de données $SPECIFIC_DB"
    exit 1
  fi
else
  # Lister toutes les bases de données
  databases=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")
  
  # Sauvegarder chaque base de données
  for db in $databases; do
    log_info "Backing up $db"
    mysqldump -u"$DB_USER" -p"$DB_PASSWORD" --databases "$db" > "$BACKUP_DIR/$db.sql"
    if [[ $? -ne 0 ]]; then
      log_error "Erreur de sauvegarde pour la base de données $db"
      exit 1
    fi
  done
fi

log_info "Backup des bases de données terminé avec succès"
