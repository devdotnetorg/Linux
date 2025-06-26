#!/bin/bash
# Uploading data to MEGA.NZ
# Script version: 1.1
# Arguments:
# 1) -l|--login: login for authorization on MEGA.NZ.
# 2) -p|--password: password for account.
# 3) -s|--source: path to folder on host for uploading to MEGA.NZ storage.
# 4) -d|--destination: path to MEGA.NZ storage.
#=================================================================
# Run:	chmod +x b2_backup_upload_mega.nz.sh
# 		./b2_backup_upload_mega.nz.sh --login user@server.com --password PASSWORD --source /var/backup/ --destination /folder_on_mega/
#=================================================================
# DevDotNet.ORG <anton@devdotnet.org> MIT License
#
# Dependent packages:
# MEGA CMD app
# https://mega.io/cmd
# Ubuntu 24.04
# sudo apt update && sudo apt install wget
# wget https://mega.nz/linux/repo/xUbuntu_24.04/amd64/megacmd-xUbuntu_24.04_amd64.deb
# sudo apt install "$PWD/megacmd-xUbuntu_24.04_amd64.deb" && rm "$PWD/megacmd-xUbuntu_24.04_amd64.deb"

set -e #Exit immediately if a comman returns a non-zero status
# set -x #Debug

# reading arguments from CLI
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--login)
      MEGA_LOGIN="$2"
      shift # past argument
      shift # past value
      ;;

    -p|--password)
      MEGA_PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--source)
      DATA_SOURCE="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--destination)
      MEGA_DESTINATION="$2"
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
if [ -z "${MEGA_LOGIN}" ]; then
	echo "Error: --login not specified"
	exit 2;
fi

if [ -z "${MEGA_PASSWORD}" ]; then
	echo "Error: --password not specified"
	exit 2;
fi

if [ -z "${DATA_SOURCE}" ]; then
	echo "Error: --source not specified"
	exit 2;
fi

if [ -z "${MEGA_DESTINATION}" ]; then
	echo "Error: --destination not specified"
	exit 2;
fi

echo "================= Start upload ================="
# script execution start time
START_TIME=$(date +%s)
echo "Start is: $(date)"
echo "Folder: ${DATA_SOURCE}"
echo "----------------------------------------------"
echo ""

# check previous session
declare islogin="true"
mega-exec ls &>/dev/null || islogin="false"
if [ ${islogin} == "true" ] ; then
    echo "Logout of previous session ..."
    mega-logout
fi

# login
echo "Login '${MEGA_LOGIN}' ..."
mega-login ${MEGA_LOGIN} ${MEGA_PASSWORD}
echo "OK"

# upload
# list folders and files
declare listitems=$(find ${DATA_SOURCE} -maxdepth 1 -mindepth 1)
for item in $listitems
do
    echo "Put item: ${item}"
    mega-put ${item} ${MEGA_DESTINATION}
done

# logout
echo "Logout ..."
mega-logout
echo "OK"

echo "================= End upload ================="

END_TIME=$(date +%s)
difference=$(( $END_TIME - $START_TIME ))

echo "End is: $(date)"
echo "Total: $difference seconds"
echo "Successfully"
exit 0;
