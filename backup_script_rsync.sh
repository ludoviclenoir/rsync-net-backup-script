#!/bin/bash

# Ce script sauvegarde des fichiers locaux vers un serveur rsync.net.

ALERT_EMAIL=""  # adresse e-mail pour les alertes
TMP_DIR="/tmp"
LOG_FILE="/var/log/backup.log"
BACKUP_DIR="/var/www/html/"  # répertoire local à sauvegarder
LOCK_FILE="$TMP_DIR/backup_lock"
MAXTIME=3600
DB_BACKUP_SCRIPT="databases_backups.sh"  # script pour sauvegarder les bases de données
DB_BACKUP_DIR="/var/backup/db"  # Répertoire de sauvegarde local pour les bases de données
RSYNC_USER=""  #  nom d'utilisateur rsync.net
RSYNC_SERVER=""  # serveur rsync.net
HOSTNAME=$(hostname) # nom de l'hôte
REMOTE_BASE_DIR="$HOSTNAME/var/www/html"  # Répertoire de base distant

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

email_alert() {
  local msg=${1:-"No details provided"}
  local subject="Rsync.net backup failure"
  mail -s "$subject" "$ALERT_EMAIL" << _f_limiter
Error attempting to rsync files to remote backup on $RSYNC_SERVER
$msg
_f_limiter
}

check_create_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    exit_backup_error "Lock file $LOCK_FILE found, a backup may be already in progress"
  fi
  log_info "Creating lock file"
  date > "$LOCK_FILE"
  if [[ $? -eq 1 ]]; then
    exit_backup_error "Cannot create lock file $LOCK_FILE, backup operations aborted"
  fi
}

remove_lock() {
  log_info "Removing lock file"
  rm "$LOCK_FILE"
}

exit_backup_error() {
  local msg=${1:-"No details provided"}
  log_error "$msg"
  email_alert "$msg"
  exit 2
}

exit_backup_error_remove_lock() {
  remove_lock
  local msg=${1:-"No details provided"}
  exit_backup_error "$msg"
}

# Needs the "start time" timestamp as first argument.
# Will exit script with error code 2 if script has 
# been running for at least $MAXTIME.
exit_when_past_maxtime() {
  [[ -z $1 ]] && return
  local START_TIME="$1"
  local CUR_TIME=$(date +"%s")
  DIFF=$((CUR_TIME-START_TIME))
  if [[ $DIFF -gt $MAXTIME ]]; then
    log_info "Backup exited due to reaching configured MAXTIME of $MAXTIME seconds"
    remove_lock
    exit 2
  fi
}

if [[ "$EUID" -ne 0 ]]; then
  echo "Permission denied: run this script as root."
  exit 1
fi

log_info "Starting backup process"
check_create_lock

START_TIME=$(date +"%s")

# Liste des répertoires à sauvegarder :
TO_PROCESS=$(find -L "$BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d | sort)

if [[ -z $TO_PROCESS ]]; then
  exit_backup_error_remove_lock "The backup directory $BACKUP_DIR appears to be empty;"
fi

TO_PROCESS=$(shuf <<< "$TO_PROCESS")

# Créer le répertoire distant de base
ssh $RSYNC_USER@$RSYNC_SERVER mkdir -p "$REMOTE_BASE_DIR"
if [[ $? -gt 0 ]]; then
  exit_backup_error_remove_lock "Could not connect to remote rsync server $RSYNC_SERVER"
fi

LF_IGNORE=$(tr " " "\n" <<< $TO_IGNORE)

for dir in $TO_PROCESS; do
  if grep -Fx "$dir" <<< "$LF_IGNORE"; then
    log_info "$dir ignored"
    continue
  fi
  log_info "Syncing $dir"
  OUTPUT=$(rsync -aL --delete "$dir"/ $RSYNC_USER@$RSYNC_SERVER:"$REMOTE_BASE_DIR"/"$(basename "$dir")"/)
  if [[ $? -gt 0 && $? -ne 24 ]]; then
    exit_backup_error_remove_lock "Error code from rsync trying to copy $dir - $OUTPUT"
  fi
  exit_when_past_maxtime "$START_TIME"
done

log_info "Backing up databases"
if ! "$DB_BACKUP_SCRIPT"; then
  exit_backup_error_remove_lock "Database backup script failed - Check manually"
else
  ssh $RSYNC_USER@$RSYNC_SERVER mkdir -p "$REMOTE_BASE_DIR/databases"
  OUTPUT=$(rsync -aL --delete "$DB_BACKUP_DIR"/ $RSYNC_USER@$RSYNC_SERVER:"$REMOTE_BASE_DIR/databases")
  if [[ $? -gt 0 ]]; then
    exit_backup_error_remove_lock "Error code from rsync trying to copy $DB_BACKUP_DIR - $OUTPUT"
  fi
fi

remove_lock
log_info "Backup successful"
