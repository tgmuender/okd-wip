#!/usr/bin/env bash
# Based on the instructions here: https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-configuration-parameters_installing-bare-metal

set -euCo pipefail

declare -r SCRIPT_DIR=$(cd $(dirname "$0") && pwd)
declare -r INSTALL_DIR=${INSTALL_DIR:-"${SCRIPT_DIR}/install"}
declare -r INSTALLER_LOCATION="${SCRIPT_DIR}/openshift-install"
declare -r INSTALLER_URL='https://github.com/openshift/okd/releases/download/4.8.0-0.okd-2021-10-01-221835/openshift-install-linux-4.8.0-0.okd-2021-10-01-221835.tar.gz'

echo "Using install directory: ${INSTALL_DIR}"

rm -rf ${INSTALL_DIR}
mkdir ${INSTALL_DIR}

function downloadInstaller() {
    if [[ -f ${INSTALLER_LOCATION} ]];
    then
        echo "Installer found.."
    else
        echo "Installer not found, downloading.."
        curl -Lv -o ${SCRIPT_DIR}/openshift-install.tar.gz --create-dirs ${INSTALLER_URL}
        tar -xzvf ${SCRIPT_DIR}/openshift-install.tar.gz -C ${SCRIPT_DIR}
    fi
}

function createManifestAndIgnitionCfg() {
    echo "--> Creating manifests"
    ${INSTALLER_LOCATION} create manifests --dir ${INSTALL_DIR}

    echo "--> Creating ignition configs"
    ${INSTALLER_LOCATION} create ignition-configs --dir ${INSTALL_DIR}

}

downloadInstaller

echo "Copying install config.."
cp install-config.yaml ${INSTALL_DIR}/

createManifestAndIgnitionCfg

# Upload ignition files to webserver
scp -r ${INSTALL_DIR} web:/var/www/html/okd

rm -f bootstrap.ign
rm -f master.ign
cp ${INSTALL_DIR}/bootstrap.ign .
cp ${INSTALL_DIR}/master.ign .