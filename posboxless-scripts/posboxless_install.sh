#!/bin/sh
set -e
set -x

### Set some variables
#####################################
__dir="$(dirname `realpath $0`)"
__odoo_dir="${__dir}/odoo/addons/point_of_sale/tools/posbox/"

POS_USER="pi"
MOUNT_POINT="${__odoo_dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__odoo_dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__odoo_dir}/overwrite_after_init"
VERSION=8.0
REPO=https://github.com/odoo/odoo.git
CLONE_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/${POS_USER}/odoo"
USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"
PY_VER=""

first_stage() {
    ## Init apt-get
    ###############
    echo "Initialize apt-get"
    apt-get update
    echo "Upgrade existing packages"
    apt-get -y upgrade

    ## Install packages required for this script
    ############################################
    DEBIAN_FRONTEND=noninteractive apt-get install -y git curl unzip adduser sudo

    if [ ! -e /home/pi ]; then
        echo "You need to create the user ${POS_USER}"
        exit 1
    fi

    echo "Clone master dir"
    git clone --depth 1 ${REPO} "odoo"

    cd ${__odoo_dir}

    echo "Clone ${VERSION} repo"
    mkdir -p "${CLONE_DIR}"
    git clone -b ${VERSION} --no-local --no-checkout --depth 1 ${REPO} "${CLONE_DIR}"
    cd "${CLONE_DIR}"
    git config core.sparsecheckout true


    echo "addons/web
addons/web_kanban
addons/hw_*
addons/point_of_sale/tools/posbox/configuration
openerp/
odoo.py" | tee --append .git/info/sparse-checkout > /dev/null
    git read-tree -mu HEAD

    cd "${_odoo__dir}"
    mkdir -p "${USR_BIN}"

    ## Install NGROK
    echo "Install ngrok"
    cd "/tmp"
    curl 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip' > ngrok.zip
    unzip ngrok.zip
    rm ngrok.zip
    cd "${__odoo_dir}"
    mv /tmp/ngrok "${USR_BIN}"

    echo "Copy init files..."
    mkdir -p "${MOUNT_POINT}" #-p: no error if existing
    cp -a "${OVERWRITE_FILES_BEFORE_INIT_DIR}"/* "${MOUNT_POINT}"
    cp -a "${OVERWRITE_FILES_AFTER_INIT_DIR}"/* "${MOUNT_POINT}"

    echo "cleanup config files"
    cd "${MOUNT_POINT}"
    rm -rf  etc/dnsmasq.conf \
            etc/ld.so.preload \
            etc/lightdm/lightdm.conf \
            etc/fstab \
            etc/init_posbox_image.sh \
            etc/systemd/system/ramdisks.service \
            configuration/setup_ramdisks.sh \
            etc/ld.so.preload


    find * -type f | while read line; do
        _path=$(dirname $line)
        if [ ! -e "/$_path" ]; then
            mkdir -p "/${_path}"
        fi
        cp -p "$line" "/${_path}"
    done

    systemctl daemon-reload
}

second_stage() {
    PKGS_TO_INSTALL="
        fswebcam \
        nginx-full \
        dbus \
        dbus-x11 \
        cups \
        printer-driver-all \
        cups-ipp-utils \
        libcups2-dev \
        pcscd \
        localepurge \
        vim \
        mc \
        mg \
        screen \
        rsync \
        swig \
        console-data \
        adduser \
        usbutils \
        postgresql \
        python-cups \
        python${PY_VER} \
        python${PY_VER}-pyscard \
        python${PY_VER}-urllib3 \
        python${PY_VER}-dateutil \
        python${PY_VER}-decorator \
        python${PY_VER}-docutils \
        python${PY_VER}-feedparser \
        python${PY_VER}-pil \
        python${PY_VER}-jinja2 \
        python${PY_VER}-ldap3 \
        python${PY_VER}-lxml \
        python${PY_VER}-mako \
        python${PY_VER}-mock \
        python${PY_VER}-openid \
        python${PY_VER}-psutil \
        python${PY_VER}-psycopg2 \
        python${PY_VER}-babel \
        python${PY_VER}-pydot \
        python${PY_VER}-pyparsing \
        python${PY_VER}-pypdf2 \
        python${PY_VER}-reportlab \
        python${PY_VER}-requests \
        python${PY_VER}-simplejson \
        python${PY_VER}-tz \
        python${PY_VER}-vatnumber \
        python${PY_VER}-werkzeug \
        python${PY_VER}-serial \
        python${PY_VER}-pip \
        python${PY_VER}-dev \
        python${PY_VER}-netifaces \
        python${PY_VER}-passlib \
        python${PY_VER}-libsass \
        python${PY_VER}-qrcode \
        python${PY_VER}-html2text \
        python${PY_VER}-unittest2 \
        python${PY_VER}-usb \
        python${PY_VER}-simplejson
        python${PY_VER}-yaml \
        python${PY_VER}-pychart \
        python${PY_VER}-cups"

#        python${PY_VER}-evdev\
    echo "Install dependencies"
    DEBIAN_FRONTEND=noninteractiv apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ${PKGS_TO_INSTALL}
    echo "Start pgsql"
    pg_lsclusters

    systemctl start postgresql
    systemctl status postgresql

    echo "configure pgsql"
    sudo -u postgres createuser -s pi
    apt-get clean
#    localepurge

    ## Use PIP to install a few stuff
    #################################
    PIP_TO_INSTALL="
    gatt \
    v4l2 \
    polib \
    pycups\
    evdev"

    pip${PY_VER} install ${PIP_TO_INSTALL}

    groupadd usbusers
    usermod -a -G usbusers ${POS_USER}
    usermod -a -G lp ${POS_USER}
    mkdir /var/log/odoo
    chown ${POS_USER}:${POS_USER} /var/log/odoo
    chown ${POS_USER}:${POS_USER} -R /home/${POS_USER}/odoo/

    # logrotate is very picky when it comes to file permissions
    chown -R root:root /etc/logrotate.d/
    chmod -R 644 /etc/logrotate.d/
    chown root:root /etc/logrotate.conf
    chmod 644 /etc/logrotate.conf

    echo "* * * * * rm /var/run/odoo/sessions/*" | crontab -

    update-rc.d timesyncd defaults
    systemctl daemon-reload
#    systemctl disable ramdisks.service
#    systemctl disable dphys-swapfile.service
    systemctl enable ssh

    echo "disable_overscan=1" >> /boot/config.txt
    echo "addons/hw_drivers/drivers/" > /home/${POS_USER}/odoo/.git/info/exclude

}

#first_stage
second_stage
