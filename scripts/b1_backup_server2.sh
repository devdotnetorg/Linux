#!/bin/bash
# Backup files, volumes, databases
# Script version: 1.1
# Arguments:
# 1) MIN_FREE_SPACE: checks the minimum free disk space in MiB. If the value is less, the script is not executed.
# 2) -n|--name: archive name.
# 3) -v|--vars: path to the configuration file, file b1_backup_server2_vars.sh.
# 4) -s|--source_volumes: path to the folder with volumes.
# 5) -d|--destination: path to the backup save folder.
#=================================================================
# Run:	chmod +x b1_backup_server2.sh
# 		sudo MIN_FREE_SPACE=1500 ./b1_backup_server2.sh --name srv1-dc-spb1-timeweb_ --vars b1_backup_server2_vars.sh --source_volumes /var/lib/docker/volumes/ --destination /var/backup/
#=================================================================
# DevDotNet.ORG <anton@devdotnet.org> MIT License
#
# Dependent packages:
# sudo apt update && sudo apt install tar rar mariadb-client
# PostgreSQL client 17
# sudo apt update && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
# sudo apt update  && sudo apt install postgresql-client-17

set -e #Exit immediately if a comman returns a non-zero status
# set -x #Debug

# reading arguments from CLI
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name)
      ARCHIVE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -v|--vars)
      SOURCE_VARS="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--source_volumes)
      SOURCE_VOLUMES="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--destination)
      BACKUP_DESTINATION="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# check
if [ -z "${ARCHIVE_NAME}" ]; then
	echo "Error: --name not specified"
	exit 2;
fi

if [ -z "${SOURCE_VARS}" ]; then
	echo "Error: --vars not specified"
	exit 2;
fi

if [ -z "${SOURCE_VOLUMES}" ]; then
	echo "Error: --source_volumes not specified"
	exit 2;
fi

if [ -z "${BACKUP_DESTINATION}" ]; then
	echo "Error: --destination not specified"
	exit 2;
fi

if [ -z "${MIN_FREE_SPACE}" ]; then
	echo "Error: environment variable 'MIN_FREE_SPACE' not set"
	echo "Example: MIN_FREE_SPACE=1500 sudo ./b1_backup_server2.sh ..."
	exit 2;
fi

# backup resources
source ${SOURCE_VARS}

# rar
# rr[N] - Add data recovery record
# m<0..5> Set compression level (0-store...3-default...5-maximal)
# v.. volume size
declare RAR_COMMAND="-rr5 -m3 -v307200k"

# checking free space in MiB
declare minAvailableFreeSpacep=${MIN_FREE_SPACE}
declare availableFreeSpace=$(($(stat -f --format="%a*%S" .))) # bytes
availableFreeSpace=`echo "scale=0; ${availableFreeSpace}/1024/1024"| bc` # MiB

echo "Checking free space ..."
echo "Minimum required free disk space = ${minAvailableFreeSpacep} MiB"
echo "Current free disk space = ${availableFreeSpace} MiB"

if [ "${minAvailableFreeSpacep}" -ge "${availableFreeSpace}" ]; then # greater than or equal
    echo "Need to free up disk space!"
    exit 3
fi

declare NOWDATE=$(date +"%d_%m_%Y_%H-%M")
declare NAME_FOLDER_BACKUP_DESTINATION="${ARCHIVE_NAME}${NOWDATE}"
declare FULL_PATH_BACKUP_DESTINATION="${BACKUP_DESTINATION}${NAME_FOLDER_BACKUP_DESTINATION}"

# create folders
mkdir -p "${FULL_PATH_BACKUP_DESTINATION}"
mkdir -p "${FULL_PATH_BACKUP_DESTINATION}/volumes"
mkdir -p "${FULL_PATH_BACKUP_DESTINATION}/databases"
#

# ************************** func *************************
funcBackupFiles() {
    echo "----------------------------------------------"
    echo "Backup files"
    echo "----------------------------------------------"
    declare FULL_PATH_FILES_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/files"
    # tar
    # declare FIRST_FILE=$(echo ${listfilestobackup} | awk '{print $1}')
    # tar --verbose --create --file=${FULL_PATH_FILES_ARCHIVE}.tar ${FIRST_FILE} 
    for sourcepathfile in $listfilestobackup
    do
        echo "File added: '${sourcepathfile}'"
        sudo tar --verbose --append --file=${FULL_PATH_FILES_ARCHIVE}.tar ${sourcepathfile}
    done
    # rar
    sudo rar a ${RAR_COMMAND} ${FULL_PATH_FILES_ARCHIVE}.tar.rar ${FULL_PATH_FILES_ARCHIVE}.tar
    sudo rm ${FULL_PATH_FILES_ARCHIVE}.tar
    echo "Done"
}

funcBackupFolders() {
    echo "----------------------------------------------"
    echo "Backup folders"
    echo "----------------------------------------------"
    declare FULL_PATH_FOLDERS_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/folders"
    # tar
    for sourcepathfolder in $listfolderstobackup
    do
        echo "Folder added: '${sourcepathfolder}'"
        sudo tar --verbose --append --file=${FULL_PATH_FOLDERS_ARCHIVE}.tar ${sourcepathfolder}
    done
    # rar
    sudo rar a ${RAR_COMMAND} ${FULL_PATH_FOLDERS_ARCHIVE}.tar.rar ${FULL_PATH_FOLDERS_ARCHIVE}.tar
    sudo rm ${FULL_PATH_FOLDERS_ARCHIVE}.tar
    echo "Done"
}

funcBackupVolumes() {
    echo "----------------------------------------------"
    echo "Backup volumes"
    echo "----------------------------------------------"
    declare FULL_PATH_VOLUMES_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/volumes/"
    for sourcepathvolume in $listvolumestobackup
    do
        # tar
        echo "Volume added: '${sourcepathvolume}'"
        # pipe
        sudo tar --verbose --create ${SOURCE_VOLUMES}${sourcepathvolume}/_data |  sudo rar a ${RAR_COMMAND} -si${sourcepathvolume}.tar ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar.rar
        # via file *.tar
        # sudo tar --verbose --create --file=${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar ${SOURCE_VOLUMES}${sourcepathvolume}/_data
        # rar
        # sudo rar a ${RAR_COMMAND} ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar.rar ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar
        # sudo rm ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar
    done
    echo "Done"
}

funcBackupDatabasesMariaDB() {
    echo "----------------------------------------------"
    echo "Backup databases: MariaDB"
    echo "----------------------------------------------"
    
    # db backup
    declare FULL_PATH_DB_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/databases/"
    
    # MariaDB
    for sourcenamedb in $listnamesmariadb
    do
        # dump
        echo "MariaDB dump: '${sourcenamedb}'"
        mariadb-dump --host=${mariadb_host} --user=${mariadb_user} --password=${mariadb_password} --lock-tables --databases ${sourcenamedb} > ${FULL_PATH_DB_ARCHIVE}mariadb-dump_${sourcenamedb}.sql
    done
    # global
    mysqldump --host=${mariadb_host} --user=${mariadb_user} --password=${mariadb_password} --system=users > ${FULL_PATH_DB_ARCHIVE}mysqldump_grants.sql

    echo "Done"
}

funcBackupDatabasesPostgreSQL() {
    echo "----------------------------------------------"
    echo "Backup databases: PostgreSQL"
    echo "----------------------------------------------"
    
    # db backup
    declare FULL_PATH_DB_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/databases/"
    
    # PostgreSQL
    for sourcenamedb in $listnamespostgres
    do
        # dump
        echo "PostgreSQL dump: '${sourcenamedb}'"
        PGPASSWORD=${postgres_password} pg_dump --host=${postgres_host} --username=${postgres_user} --verbose ${sourcenamedb} > ${FULL_PATH_DB_ARCHIVE}pg_dump_${sourcenamedb}.sql
    done
    # roles
    PGPASSWORD=${postgres_password} pg_dumpall --host=${postgres_host} --username=${postgres_user} --roles-only --verbose > ${FULL_PATH_DB_ARCHIVE}pg_dumpall_roles-only.sql

    echo "Done"
}

funcBackupDatabaseCompression() {
    echo "----------------------------------------------"
    echo "Backup databases: compression"
    echo "----------------------------------------------"
    
    # db backup
    declare FULL_PATH_DB_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/databases/"

    # rar
    # list folders
    listdbfiles=$(find ${FULL_PATH_DB_ARCHIVE} -maxdepth 1 -mindepth 1 -type f)
    for value in $listdbfiles
    do
        echo "Pack file db: ${value}"
        #get last file name
        folderspath=$(echo $value | tr "/" "\n")
        for filename in $folderspath
        do
            filename="${filename}" # mariadb-dump_dbname.sql
        done
        # Pack
        # rar
        sudo rar a ${RAR_COMMAND} ${FULL_PATH_DB_ARCHIVE}${filename}.rar ${value}
        sudo rm ${value}
    done

    echo "Done"
}

funcBackupDatabasesWithContainerStop() {
    echo "----------------------------------------------"
    echo "Backup VOLUMES with stopping Docker containers"
    echo "----------------------------------------------"
    
    # stop docker containers
    for labelcontainer in $listdbcontainersforstopping
    do
        # docker stop
        echo "Stop docker container: '${labelcontainer}'"
        sudo docker stop ${labelcontainer}
        sleep 2
    done

    # db volumes part 1
    declare FULL_PATH_VOLUMES_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/volumes/"
    for sourcepathvolume in $listdbvolumestobackup
    do
        # tar
        echo "TAR Volume added: '${sourcepathvolume}'"
        sudo tar --verbose --create --file=${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar ${SOURCE_VOLUMES}${sourcepathvolume}/_data
    done

    # start docker containers
    for labelcontainer in $listdbcontainersforstart
    do
        # docker start
        echo "Start docker container: '${labelcontainer}'"
        sudo docker start ${labelcontainer}
        sleep 1
    done

    # pause for containers to fully start, wait 12 seconds
    echo "Pause for containers to fully start, wait 12 seconds"
    echo "12 seconds left ..."
    sleep 2
    echo "10 seconds left ..."
    sleep 2
    echo "8 seconds left ..."
    sleep 2
    echo "6 seconds left ..."
    sleep 2
    echo "4 seconds left ..."
    sleep 2
    echo "2 seconds left ..."
    sleep 2
    echo "Resumption ..."

    # db volumes part 2
    for sourcepathvolume in $listdbvolumestobackup
    do
        # rar
        echo "RAR Volume added: '${sourcepathvolume}'"
        sudo rar a ${RAR_COMMAND} ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar.rar ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar
        sudo rm ${FULL_PATH_VOLUMES_ARCHIVE}${sourcepathvolume}.tar
    done

    echo "Done"
}

funcBackupCrontab() {
    echo "----------------------------------------------"
    echo "Backup crontab"
    echo "----------------------------------------------"
    declare FULL_PATH_CRONTAB_ARCHIVE="${FULL_PATH_BACKUP_DESTINATION}/crontab.bak"
    sudo crontab -l > ${FULL_PATH_CRONTAB_ARCHIVE}
    echo "Done"
}

funcBackupUfw() {
    echo "----------------------------------------------"
    echo "Backup UFW (Uncomplicated Firewall)"
    echo "----------------------------------------------"
    sudo tar --verbose --append --file=ufw.tar /etc/ufw/
    sudo iptables-save > iptables-save.txt
    sudo tar --verbose --append --file=ufw.tar iptables-save.txt
    sudo rm iptables-save.txt
    sudo ufw status > ufw-status-rules-backup.txt
    sudo tar --verbose --append --file=ufw.tar ufw-status-rules-backup.txt
    sudo rm ufw-status-rules-backup.txt
    sudo rar a ${RAR_COMMAND} ${FULL_PATH_BACKUP_DESTINATION}/ufw.tar.rar ufw.tar
    sudo rm ufw.tar
    echo "Done"
}

funcBackupFail2ban() {
    echo "----------------------------------------------"
    echo "Backup fail2ban"
    echo "----------------------------------------------"
    sudo tar --verbose --append --file=fail2ban.tar /etc/fail2ban/
    sudo rar a ${RAR_COMMAND} ${FULL_PATH_BACKUP_DESTINATION}/fail2ban.tar.rar fail2ban.tar
    sudo rm fail2ban.tar
    echo "Done"
}

# *********************************************************

echo "================= Start backup ================="
# script execution start time
START_TIME=$(date +%s)
echo "Start is: $(date)"
echo "Folder: ${FULL_PATH_BACKUP_DESTINATION}"
echo "----------------------------------------------"
echo ""

funcBackupFiles

funcBackupFolders

funcBackupVolumes

funcBackupDatabasesMariaDB

funcBackupDatabasesPostgreSQL

funcBackupDatabaseCompression

funcBackupDatabasesWithContainerStop

funcBackupCrontab

funcBackupUfw

funcBackupFail2ban

echo "================= End backup ================="

# set current user privileges on backup
declare USER_PTS=$(ps ax | grep xinit | awk '{print $2}')
declare USER_SESSION=$(who | grep ${USER_PTS} | awk '{print $1}')
sudo chown -R ${USER_SESSION}:${USER_SESSION} ${FULL_PATH_BACKUP_DESTINATION}
# drwxrwxr-x
sudo find ${FULL_PATH_BACKUP_DESTINATION} -type d -exec sudo chmod 755 {} +
# -rw-rw-r--
sudo find ${FULL_PATH_BACKUP_DESTINATION} -type f -exec sudo chmod 644 {} +

END_TIME=$(date +%s)
difference=$(( $END_TIME - $START_TIME ))

echo "End is: $(date)"
echo "Total: $difference seconds"
echo "Successfully"
exit 0;
