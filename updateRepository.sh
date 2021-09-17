#!/bin/bash

# Name: updateRepository.sh
# Description: Update the packages repository
# Author: Titux Metal <tituxmetal[at]lgdweb[dot]fr>
# Url: https://github.com/ArchLinuxCustomEasy/repository
# Version: 1.0
# Revision: 2021.09.15
# License: MIT License

workspace="$HOME/ALICE-workspace"
localRepositoryDir="$(pwd)/x86_64/"
systemRepositoryDir="/opt/alice/x86_64/"
databaseName="alice"
commandOptions="--new --remove --verify"
# logFile="$(pwd)/$(date +%T).log"

# Helper function for printing messages $1 The message to print
printMessage() {
  message=$1
  tput setaf 2
  echo -en "-------------------------------------------\n"
  echo -en "${message}\n"
  echo -en "-------------------------------------------\n"
  tput sgr0
}

isRootUser() {
  if [[ ! "$EUID" = 0 ]]; then
    printMessage "Please Run As Root"
    exit 0
  fi
  printMessage "Ok to continue running the script"
  sleep .5
}

# Helper function to handle errors
handleError() {
  clear
  set -uo pipefail
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

cleanup() {
  printMessage "Cleanup database and signatures in ${localRepositoryDir}"
  rm -rfv ${systemRepositoryDir}${databaseName}.*
  sleep .5
}

updateRepository() {
  cleanup
  printMessage "Update repository in ${systemRepositoryDir}"
  repo-add ${commandOptions} ${systemRepositoryDir}${databaseName}.db.tar.gz ${systemRepositoryDir}*.pkg.tar.zst
  sleep .5
}

synchronizeRepository() {
  local=$1
  target=$2
  printMessage "Synchronize ${local} repository with ${target} repository"
  rsync -rltv --stats --progress "${local}" "${target}"
  sleep .5
}

changeOwner() {
  newOwner=$1
  directoryName=$2
  printMessage "Change owner of ${directoryName} to ${newOwner}"
  chown -R ${newOwner} ${directoryName}
  sleep .5
}

chooseOneAction() {
  update="1. update db in system repository"
  synchronize="2. sync local repo in system repo"
  quit="3. quit now"
  printMessage "${update}\n${synchronize}\n${quit}"

  PS3="Make your choice: "
  select opt in update sync quit ; do
  case $opt in
    update)
      printMessage "Update repository database in system repository"
      cleanup
      updateRepository
      synchronizeRepository "${systemRepositoryDir}" "${localRepositoryDir}"
      changeOwner "1000:1000" "${localRepositoryDir}"
      ;;
    sync)
      printMessage "Synchronize local repository in system repository"
      rm -rf ${systemRepositoryDir}*
      synchronizeRepository "${localRepositoryDir}" "${systemRepositoryDir}"
      ;;
    quit)
      printMessage "All is done!"
      exit 0
      ;;
    *)
      echo "Invalid option $REPLY"
      ;;
    esac
    chooseOneAction
  done
}

main() {
  handleError
  chooseOneAction
}

time main

exit 0
