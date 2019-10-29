set -o errexit
set -o nounset
set -o pipefail

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

MOUNT_POINT="${__dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__dir}/overwrite_after_init"
VERSION=11.0
REPO=https://github.com/odoo/odoo.git
CLONE_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/pi/odoo"
USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"

# Cleanup the CLONE_DIR
rm -rf "${CLONE_DIR}"

# Clone the github repo
echo "Clone Github repo"
mkdir -p "${CLONE_DIR}"
git clone -b ${VERSION} --no-local --no-checkout --depth 1 ${REPO} "${CLONE_DIR}"
cd "${CLONE_DIR}"
git config core.sparsecheckout true
echo "addons/web
addons/hw_*
addons/point_of_sale/tools/posbox/configuration
odoo/
odoo-bin" | tee --append .git/info/sparse-checkout > /dev/null
git read-tree -mu HEAD

cd "${__dir}"
mkdir -p "${USR_BIN}"

## Install NGROK
cd "/tmp"
curl 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip' > ngrok.zip
unzip ngrok.zip
rm ngrok.zip
cd "${__dir}"
mv /tmp/ngrok "${USR_BIN}"

mkdir -p "${MOUNT_POINT}" #-p: no error if existing
cp -a "${OVERWRITE_FILES_BEFORE_INIT_DIR}"/* "${MOUNT_POINT}"
# get rid of the git clone
rm -rf "${CLONE_DIR}"
# and the ngrok usr/bin
rm -rf "${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr"
## Reboot the system
cp -av "${OVERWRITE_FILES_AFTER_INIT_DIR}"/* "${MOUNT_POINT}"
