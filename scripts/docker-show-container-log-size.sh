#!/bin/bash
# Run: 
# chmod +x docker-show-container-log-size.sh
# sudo ./docker-show-container-log-size.sh

# Running the script with the 'clear' key clears the log file of each container
# sudo ./docker-show-container-log-size.sh clear

# Display the size of the container log
# Script version: 1.1
# DevDotNet.ORG <anton@devdotnet.org> MIT License

set -e #Exit immediately if a comman returns a non-zero status

#
declare ISCLEAR="$1" # check 'clear'
#

# containers

declare CONTAINERS_LINE=("$(docker container ls -a --format="{{ json .Names }}" | sort  | tr '\n' ' ' |  sed 's/\"//g')") # get containers
# CONTAINERS_LINE="example-app-httpd portainer_local"
let COUNTER=1

echo "CONTAINERS"
echo "----------"
for CONTAINER_NAME in ${CONTAINERS_LINE}
do
  # get target
  declare CONTAINER_TARGET=$(docker container inspect ${CONTAINER_NAME} --format "{{ .LogPath }}")
  declare UNIT_SIZE="byte"

  # check none
  if [ -z "${CONTAINER_TARGET}" ] || [ ! -f "${CONTAINER_TARGET}" ]; then
    if [ -z "${CONTAINER_TARGET}" ]; then
      CONTAINER_TARGET="none"
      PRINT_TARGET_SIZE="none"
    else
      PRINT_TARGET_SIZE="REMOVED"
    fi
  else
    declare TARGET_SIZE=$(stat --printf="%s" ${CONTAINER_TARGET})
    declare ZERO_TARGET_SIZE=0
    declare PRINT_TARGET_SIZE=0

    # KiB
    ZERO_TARGET_SIZE=$((${TARGET_SIZE} / 1024))

    if [ $ZERO_TARGET_SIZE != "0" ]; then
      PRINT_TARGET_SIZE=`echo "scale=2; $TARGET_SIZE / 1024"| bc`
      UNIT_SIZE="KiB"
    fi

    # MiB
    ZERO_TARGET_SIZE=$((${TARGET_SIZE} / 1048576))

    if [ $ZERO_TARGET_SIZE != "0" ]; then
      PRINT_TARGET_SIZE=`echo "scale=2; $TARGET_SIZE / 1048576"| bc`
      UNIT_SIZE="MiB"
    fi
  fi

  # print
  echo "${COUNTER}) NAME: '${CONTAINER_NAME}', LOG_FILE: '${CONTAINER_TARGET}', SIZE: ${PRINT_TARGET_SIZE} ${UNIT_SIZE}"

  # check clear
  if [ "${ISCLEAR}" == "clear" ] && [ "${CONTAINER_TARGET}" != "none" ]; then
    echo "" > ${CONTAINER_TARGET}
    echo "Cleaned file: '${CONTAINER_TARGET}'"
  fi

  let COUNTER=COUNTER+1
done

# exit
exit 0
