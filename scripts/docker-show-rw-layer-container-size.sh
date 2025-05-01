#!/bin/bash
# Run: 
# chmod +x docker-show-rw-layer-container-size.sh
# sudo ./docker-show-rw-layer-container-size.sh

# Output the size of the last layer of the R/W container
# Script version: 1.0
# DevDotNet.ORG <anton@devdotnet.org> MIT License

set -e #Exit immediately if a comman returns a non-zero status

# containers

declare CONTAINERS_LINE=("$(docker container ls -a --format="{{ json .Names }}" | sort  | tr '\n' ' ' |  sed 's/\"//g')") # get containers
# CONTAINERS_LINE="example-app-httpd portainer_local"

echo "CONTAINERS"
echo "----------"
for CONTAINER_NAME in ${CONTAINERS_LINE}
do
  # get size
  declare LAYER_RW_SIZE=$(docker inspect --size ${CONTAINER_NAME} -f '{{ .SizeRw }}')
  declare ZERO_LAYER_RW_SIZE=0
  declare PRINT_LAYER_RW_SIZE=0
# declare LAYER_ROOTFS_SIZE=$(docker inspect --size ${CONTAINER_NAME} -f '{{ .SizeRootFs }}')
  declare UNIT_RW_SIZE="byte"
  
  # KiB
  ZERO_LAYER_RW_SIZE=$((${LAYER_RW_SIZE} / 1024))
  
  if [ $ZERO_LAYER_RW_SIZE != "0" ]; then
	  PRINT_LAYER_RW_SIZE=`echo "scale=2; $LAYER_RW_SIZE / 1024"| bc`
	  UNIT_RW_SIZE="KiB"
  fi
  
  # MiB
  ZERO_LAYER_RW_SIZE=$((${LAYER_RW_SIZE} / 1048576))
  
  if [ $ZERO_LAYER_RW_SIZE != "0" ]; then
	  PRINT_LAYER_RW_SIZE=`echo "scale=2; $LAYER_RW_SIZE / 1048576"| bc`
	  UNIT_RW_SIZE="MiB"
  fi

  # print
  echo "${CONTAINER_NAME} LAYER_RW_SIZE = ${PRINT_LAYER_RW_SIZE} ${UNIT_RW_SIZE}"

done

# exit
exit 0
