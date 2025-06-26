#!/bin/bash
# Backup resources for b1_backup_server2.sh
# Script version: 1.1
#=================================================================
# Run:	chmod +x b1_backup_server2_vars.sh
# 		./b1_backup_server2_vars.sh
#=================================================================
# DevDotNet.ORG <anton@devdotnet.org> MIT License

set -e #Exit immediately if a comman returns a non-zero status
# set -x #Debug

# SOURCE ----------------------------------------------------------
# list files
declare listfilestobackup="
/etc/hostname
/etc/hosts
/etc/environment
/etc/docker/daemon.json"

# list folders
declare listfolderstobackup="
/etc/ssh/
/etc/netplan/"

# list volumes
declare listvolumestobackup="
gotify-data
pihole-config
pihole-dnsmasq-config"

# db
# db containers for stopping
declare listdbcontainersforstopping="
matomo_local
wallabag_local
some-mariadb
some-postgres"

# db creating a reverse list of containers to run
declare listdbcontainersforstart=""
for labelcontainer in $listdbcontainersforstopping
do
    listdbcontainersforstart="${labelcontainer} ${listdbcontainersforstart}"
done

# list db volumes
declare listdbvolumestobackup="
some-mariadb-data
some-postgres-data"

# MariaDB
declare mariadb_host="172.15.1.30"
declare mariadb_user="root"
declare mariadb_password="password"

# list db names
declare listnamesmariadb="
testdb
matomo"

# PostgreSQL
declare postgres_host="172.15.1.31"
declare postgres_user="postgres"
declare postgres_password="password"

# list db names
declare listnamespostgres="
testdb
wallabag"

# -----------------------------------------------------------------