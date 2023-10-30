#!/bin/bash
#
#date         :30/10/23
#version      :0.1
#authors      :jtudelag@redhat.com
#description  :Script to build an Ansible Execution Environment to build Applications.
#

set -euo pipefail

#VARS
# Dont include TAGS!!!! Only the name.
EE_IMAGE_NAME="ee-build-apps"
# Change the version as you make changes.
EE_IMAGE_VERSION="0.1"
# oc cli versions.
OCP_MAJOR=4
OCP_MINOR=12
OCP_PATCH=32
#Used for RPMs repos.
RHEL_VERSION="8"
# Other deps.
HELM_VERSION="3.13.1"
GRADLE_VERSION="6.9.4"
DELINEA_SS_VERSION="1.4.1"

# Constants, dont change!!!
OCP_XY="${OCP_MAJOR}.${OCP_MINOR}"
OCP_XYZ="${OCP_XY}.${OCP_PATCH}"
OC_FINAL_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OCP_XYZ}/openshift-client-linux.tar.gz"
HELM_FINAL_URL="https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
GRADLE_FINAL_URL="https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
DELINEA_SS_FINAL_URL="https://downloads.ss.thycotic.com/secretserversdk/${DELINEA_SS_VERSION}/secretserver-sdk-${DELINEA_SS_VERSION}-rhel.6-x64.zip"

# Create Temporary folders
BASE_TMPDIR="$(mktemp -d -q)"
BASE_TARGZ_DIR="${BASE_TMPDIR}/tar"
mkdir "${BASE_TARGZ_DIR}"
BASE_BIN_DIR="${BASE_TMPDIR}/bin"
mkdir "${BASE_BIN_DIR}"

DOWNLOAD_ZIP_DIR="./zip_files"
mkdir -p "${DOWNLOAD_ZIP_DIR}"

mkdir -p "./files"
FINAL_FILE="./files/binaries.tar.gz"

dl_oc () {
  echo "Downloading oc ;)"
  URL="${OC_FINAL_URL}"
  TAR_FILE="${BASE_TARGZ_DIR}/openshift-client-linux.tar.gz"
  curl -L "${URL}" -o "${TAR_FILE}"
  tar xvfz "${TAR_FILE}" --directory "${BASE_BIN_DIR}/" oc
}

dl_helm () {
  echo "Downloading helm ;)"
  URL="$HELM_FINAL_URL"
  TAR_FILE="${BASE_TARGZ_DIR}/helm-amd64.tar.gz"
  curl -L "${URL}" -o "${TAR_FILE}"
  tar xvfz "${TAR_FILE}" --strip-components=1 --directory "${BASE_BIN_DIR}/" linux-amd64/helm
}

dl_gradle () {
  echo "Downloading gradle ;)"
  URL="$GRADLE_FINAL_URL"
  ZIP_FILE="${DOWNLOAD_ZIP_DIR}/gradle.zip"
  curl -L "${URL}" -o "${ZIP_FILE}"
}

dl_ss () {
  echo "Downloading Delinea SS ;)"
  URL="$DELINEA_SS_FINAL_URL"
  ZIP_FILE="${DOWNLOAD_ZIP_DIR}/ss.zip"
  curl -L "${URL}" -o "${ZIP_FILE}"
}

download () {
  dl_oc
  dl_helm
  
  #chmod +x ${BASE_BIN_DIR}/*
  #chown root:root ${BASE_BIN_DIR}/*
  tar cvfz "${FINAL_FILE}" -C "${BASE_BIN_DIR}/" .

  dl_gradle
  dl_ss 
}

build () {
  #sudo subscription-manager repos --enable="rhocp-${OCP_MAJOR}.${OCP_MINOR}-for-rhel-${RHEL_VERSION}-x86_64-rpms"
 
  EE_BUILD_DATE="$(date "+%FT%H:%M:%S")"  
  #Build it
  ansible-builder build -v 3 \
  	--squash all \
	--build-arg EE_BASE_IMAGE="registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel${RHEL_VERSION}:latest" \
        --build-arg "HELM_VERSION=$HELM_VERSION" \
        --build-arg "GRADLE_VERSION=$GRADLE_VERSION" \
        --build-arg "DELINEA_SS_VERSION=$DELINEA_SS_VERSION" \
        --build-arg "OCP_VERSION=$OCP_XYZ" \
        --build-arg "EE_BUILD_DATE=$EE_BUILD_DATE" \
        --build-arg "EE_NAME=$EE_IMAGE_NAME" \
        --build-arg "EE_VERSION=$EE_IMAGE_VERSION" \
  	--prune-images \
  	--tag "${EE_IMAGE_NAME}:${EE_IMAGE_VERSION}"
}

all () {
  download
  build
}

help () {
   # Display Help
   echo "Script to build an Ansible EE to install OpenShift"
   echo
   echo "Syntax: build_ee.sh [-h|-a|-b|-d]"
   echo "options:"
   echo "-h   Print this Help."
   echo "-d   Download Openshift artifacts."
   echo "-b   Build EE."
   echo "-a   Download OpenShift artifacts and build EE."
   echo ""
}

#----------------------------------- MAIN--------------------------

PASSED_ARGS=$@
if [[ ${#PASSED_ARGS} -ne 0 ]]
then
     case "$1" in
        -h) # display Help
           help
           exit;;
        -a) # all
           all
           exit;;
        -b) # all
           build
           exit;;
        -d) # all
           download 
           exit;;
        *) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
        :) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
        \?) # incorrect option
           echo "Error: Invalid option"
  	   help
           exit;;
     esac
else
  help
  exit
fi
