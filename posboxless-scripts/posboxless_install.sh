set -o errexit
set -o nounset
set -o pipefail

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"


POS_USER="caisse"
MOUNT_POINT="${__dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__dir}/overwrite_after_init"
VERSION=11.0
REPO=https://github.com/odoo/odoo.git
CLONE_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/${POS_USER}/odoo"
USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"

# Tools required to perform the install
apt-get install git curl unzip 

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

############ Installed files
etc/ssl/private/nginx-selfsigned.key

############ Installed files
## etc/ssl/private/nginx-selfsigned.key         | key for NGINX
## etc/ssl/certs/nginx-selfsigned.crt           | Certificate for NGINX
## etc/logrotate.conf                           | logrotate config
## etc/hostapd/hostapd.conf                     | hotapd conf NOT REQUIRED
## etc/default/ifplugd                          | ifplugd config NOT REQUIRED
## etc/default/hostapd                          | hostapd config NOT REQUIRED
## etc/default/keyboard                         | Default keyboard NOT REQUIRED
## etc/xdg/openbox/autostart                    | OpenBox autostart....really ? NOT REQUIRED
## etc/systemd/system/ramdisks.service          | ramdisk config for /var /etc /tmp and mount / on /root_bypass_ramdisks to access real values from those dirs
## etc/nginx/sites-enabled/default              | NGINX configuration for Posbox
## etc/dhcpcd.conf                              | dhcpd conf NOT REQUIRED
## etc/logrotate.d/odoo                         | Logrotate Odo logfile management
## etc/logrotate.d/rsyslog                      | Logrotate rsyslog 
## etc/init_posbox_image.sh                     | init posbox this script does the init job
 #                                                - install additional packages (PKG_TO_INSTALL list), use --force-confdef to keep new packages config
 #                                                - config postgresql
 #                                                - bypass rapbian packaging to install PIP pyusb==1.0.0b1 evdev gatt v4l2 pycups
 #                                                - set pi as usbuser lp and input groups member
 #                                                - enable ramdisks.service disable dphys-swapfile.service enable ssh
 #                                                - user pi autologin 
## etc/udev/rules.d/99-usb.rules                | udev usb rules
## etc/udev/rules.d/90-qemu.rules               | udev qemu rules 
## etc/udev/rules.d/99-z-input.rules            | zinput rules
## etc/cups/cups-files.conf                     | cups config
## etc/cups/cupsd.conf                          | cups config
## etc/network/interfaces                       | network interface NOT REQUIRED
## etc/dhcp/dhcpd.conf                          | DHCPD ???
## etc/dnsmasq.conf                             | DNSMASK
## etc/ld.so.preload                            | ld preload NOT REQUIRED
## etc/rc.local                                 | print ip, mkdir /var/run/odoo and chown 
## etc/lightdm/lightdm.conf
## etc/init.d/odoo                              | start odoo & odoo modules
## etc/init.d/timesyncd                         | start systemd-timesyncd service
## etc/fstab                                    | argggggg

##################
## Reboot the system
reboot

## Postreboo script
#cp -av "${OVERWRITE_FILES_AFTER_INIT_DIR}"/* "${MOUNT_POINT}"
