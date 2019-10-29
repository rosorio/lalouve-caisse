#!/bin/sh
set -e

### Set some variables
#####################################
__dir="$(dirname `realpath $0`)"
__odoo_dir="${__dir}/odoo/addons/point_of_sale/tools/posbox/"

POS_USER="pi"
MOUNT_POINT="${__odoo_dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__odoo_dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__odoo_dir}/overwrite_after_init"
VERSION=11.0
REPO=https://github.com/odoo/odoo.git
CLONE_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/${POS_USER}/odoo"
USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"

first_stage() {
    ## Init apt-get
    ###############
    echo "Initialize apt-get"
    apt-get update 1>/dev/null 2>&1
    echo "Upgrade existing packages"
    apt-get -y upgrade 1>/dev/null 2>&1

    ## Install packages required for this script
    ############################################
    apt-get install git curl unzip 1>/dev/null 2>&1

    echo "Clone master dir"
    git clone --no-local --no-checkout --depth 1 ${REPO} odoo

    cd ${__odoo_dir}

    echo "Clone ${VERSION} repo"
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
    # get rid of the git clone
    rm -rf "${CLONE_DIR}"
    # and the ngrok usr/bin
    rm -rf "${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr"

    echo "cleanup config files"
    cd "${MOUNT_POINT}"
    rm -rf  etc/dnsmasq.conf \
            etc/ld.so.preload \
            etc/lightdm/lightdm.conf \
            etc/fstab \
            etc/init_posbox_image.sh \
            etc/systemd/system/ramdisks.service \
            home/caisse/odoo/addons/point_of_sale/tools/posbox/configuration/setup_ramdisks.sh
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
        postgresql \
        python-cups \
        python3 \
        python3-pyscard \
        python3-urllib3 \
        python3-dateutil \
        python3-decorator \
        python3-docutils \
        python3-feedparser \
        python3-pil \
        python3-jinja2 \
        python3-ldap3 \
        python3-lxml \
        python3-mako \
        python3-mock \
        python3-openid \
        python3-psutil \
        python3-psycopg2 \
        python3-babel \
        python3-pydot \
        python3-pyparsing \
        python3-pypdf2 \
        python3-reportlab \
        python3-requests \
        python3-simplejson \
        python3-tz \
        python3-vatnumber \
        python3-werkzeug \
        python3-serial \
        python3-pip \
        python3-dev \
        python3-netifaces \
        python3-passlib \
        python3-libsass \
        python3-qrcode \
        python3-html2text \
        python3-unittest2 \
        python3-simplejson \
        python3-usb \
        python3-evedev\
        python3-cups"

    echo "Install dependencies"
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ${PKGS_TO_INSTALL}
    echo "Start pgsql"
    pg_lsclusters
    systemctl start postgresql@9.6-main
    systemctl status postgresql@9.6-main

    echo "configure pgsql"
    sudo -u postgres createuser -s pi
    apt-get clean
    localepurge

    ## Use PIP to install a few stuff
    #################################
    PIP_TO_INSTALL="
    gatt \
    v4l2 \
    polib \
    pycups"

    pip3 install ${PIP_TO_INSTALL}

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
    systemctl disable ramdisks.service
    systemctl disable dphys-swapfile.service
    systemctl enable ssh

    echo "disable_overscan=1" >> /boot/config.txt
    echo "addons/hw_drivers/drivers/" > /home/${POS_USER}/odoo/.git/info/exclude

}
