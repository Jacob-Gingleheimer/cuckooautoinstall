#!/bin/bash

# CuckooAutoInstall

# Rewritten and simplified for ubuntu 14.04 by Jacob Gingleheimer (JJGS) - jacob.gingleheimer@gmail.com

# Using the excellent code provided by:
# Copyright (C) 2014-2015 David Reguera García - dreg@buguroo.com
# Copyright (C) 2015 David Francos Cuartero - dfrancos@buguroo.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SUDO="sudo"
TMPDIR=$(mktemp -d)
RELEASE=$(lsb_release -cs)
CUCKOO_USER="cuckoo"
LOG="cuckooAutoinstall.log"
CUCKOO_REQS="/home/cuckoo/cuckoo/requirements.txt"
ORIG_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
VOLATILITY_URL="http://downloads.volatilityfoundation.org/releases/2.5/volatility_2.5.linux.standalone.zip"
VIRTUALBOX_REP="deb http://download.virtualbox.org/virtualbox/debian $RELEASE contrib"
CUCKOO_REPO='https://github.com/cuckoobox/cuckoo'
CUCKOO_BRANCH= "master"

# Pretty icons
log_icon="\e[31m✓\e[0m"
log_icon_ok="\e[32m✓\e[0m"
log_icon_nok="\e[31m✗\e[0m"


print_copy(){
cat <<EO
┌─────────────────────────────────────────────────────────┐
│                CuckooAutoInstall 0.5                    │
│   Just contributing a little bit & trying to help out   │
│ Jacob Gingleheimer - JJGS <jacob.gingleheimer@gmail.com>│
│                                                         │
│ Using the code provided by:                             │
│ David Reguera García - Dreg <dreguera@buguroo.com>      │
│ David Francos Cuartero - XayOn <dfrancos@buguroo.com>   │
│            Buguroo Offensive Security - 2015            │
│                                                         │
└─────────────────────────────────────────────────────────┘
EO
}

# What do we need installed so that cuckoo can run?
packages=(python-pip python-sqlalchemy mongodb python-bson python-dpkt python-jinja2 python-magic python-gridfs python-libvirt python-bottle python-pefile python-chardet git build-essential autoconf automake libtool dh-autoreconf libcurl4-gnutls-dev libmagic-dev python-dev tcpdump libcap2-bin virtualbox dkms python-pyrex yara python-yara libyara3 libjansson4)

python_packages=(pymongo django maec py3compat lxml cybox distorm3 pycrypto pydeep)

# Can you bring the "magic"
check_viability(){
    [[ $UID != 0 ]] && {
        type -f $SUDO || {
            echo "I know root and you're no root! ... and you don't have $SUDO, please become root or install $SUDO before executing. $0"
            exit
        }
    } || {
        SUDO=""
    }

    [[ ! -e /etc/debian_version ]] && {
        echo  "This script currently works only on debian-based (debian, ubuntu...) distros"
        exit 1
    }
}

print_help(){
    cat <<EOH
Usage: $0 [--verbose|-v] [--help|-h]

    --verbose   Print output to stdout instead of temp logfile
    --help      This help menu ... which doesn't really help, :-P

EOH
    exit 1
}

setopts(){
    optspec=":hvu-:"
    while getopts "$optspec" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    help) print_help ;;
                    verbose) LOG=/dev/stdout ;;
                esac;;
            h) print_help ;;
            v) LOG=/dev/stdout;;
        esac
    done
}

#Let's get cuckoo for cocoapuffs!
cdcuckoo(){
    eval cd ~${CUCKOO_USER}
    return 0
}

create_cuckoo_user(){
    $SUDO adduser ${CUCKOO_PASSWD} -gecos "Cuckoo Sandbox" ${CUCKOO_USER}
    $SUDO usermod -G vboxusers ${CUCKOO_USER}
    return 0
}

clone_cuckoo(){
    cdcuckoo
    $SUDO git clone ${CUCKOO_REPO}
    cdcuckoo
    [[ $STABLE ]] && $SUDO git checkout ${CUCKOO_BRANCH}
    CUCKOO_REQS=`pwd`"/cuckoo/requirements.txt"
    cd ..
    $SUDO chown -R ${CUCKOO_USER}:${CUCKOO_USER} cuckoo
    cd $TMPDIR
    return 0
}

# Networking stuff goes here:
create_hostonly_iface(){
    $SUDO vboxmanage hostonlyif create
    $SUDO iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
    $SUDO iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    $SUDO iptables -A POSTROUTING -t nat -j MASQUERADE
    $SUDO sysctl -w net.ipv4.ip_forward=1
    return 0
}

setcap(){
    $SUDO /bin/bash -c 'setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump' 2&>/dev/null
    return 0
}

# We want the MongoDB
enable_mongodb(){
    cdcuckoo
    $SUDO sed -i '/\[mongodb\]/{ N; s/.*/\[mongodb\]\nenabled = yes/; }' cuckoo/conf/reporting.conf
    cd $TMPDIR
    return 0
}

# Need me some memory analysis
build_volatility(){
    wget $VOLATILITY_URL
    unzip volatility_2.5.linux.standalone.zip
    cd volatility_2.5.linux.standalone/
    $SUDO ln ./volatility_2.5_linux_x64 /usr/sbin/vol.py
    $SUDO chmod 666 /usr/sbin/vol.py
    chmod 666 vol*
    return 0
}

# Got's to have the virutal machines
prepare_virtualbox(){
    cd ${TMPDIR}
    echo ${VIRTUALBOX_REP} |$SUDO tee /etc/apt/sources.list.d/virtualbox.list
    wget -O - https://www.virtualbox.org/download/oracle_vbox.asc | $SUDO apt-key add -
    pgrep virtualbox && return 1
    pgrep VBox && return 1 
    return 0
}

# Install ALL THE THINGS!!!
install_packages(){     
	echo -n "Updating source directories ";     
	$SUDO apt-get update &>> ${LOG} || echo -e $log_icon_nok " " && echo -e $log_icon_ok " ";     
	echo -n "Updating system ";     
	$SUDO apt-get upgrade -y &>> ${LOG} || echo -e $log_icon_nok " " && echo -e $log_icon_ok " ";      
	echo "Installing all the necessary packages for Cuckoo";    
	for package in ${packages[@]}; do 
		echo -n "$package"
		echo "Installing: $package" >> ${LOG}
		$SUDO apt-get install -y ${1} &>> ${LOG} || echo -e -n $log_icon_nok " " && {
			echo -e -n $log_icon_ok " ";}   
		done;
	echo " " 
}

# Install python packages
install_via_pip(){
	echo "Installing python packages via pip:"
	for package in ${python_packages[@]}; do 
		pip_install=`grep $package -i $CUCKOO_REQS -i` 
		[ -z "$pip_install" ] && pip_install=$package
		echo -n $pip_install
		$SUDO -H pip install $pip_install &>> ${LOG} || echo -e -n $log_icon_nok " " && {
			echo -e -n $log_icon_ok " ";}
	done;
	echo " "
} 

# This makes it look pretty.
run_and_log(){
    $1 &>> ${LOG} && {
        _log_icon=$log_icon_ok
    } || {
        _log_icon=$log_icon_nok
        exit_=1
    }
    echo -e "${_log_icon} ${2}"
    [[ $exit_ ]] && { echo -e "\t -> ${_log_icon} $3";  exit; }
}

# Init.
print_copy
check_viability
setopts ${@}

# Create a log file in the current directory for easy review
echo "Logging enabled on ${LOG}"
echo `date --rfc-3339=seconds` "Cuckoo Autoinstall" > $LOG

# Install packages
run_and_log prepare_virtualbox "Getting virtualbox repo ready" "Virtualbox is running, please close it"
install_packages

# Get Cuckoo setup since we will use the cuckoo requirements.txt file in wit pip
run_and_log create_cuckoo_user "Creating cuckoo user" "Could not create cuckoo user"
run_and_log clone_cuckoo "Downloading cuckoo" "Failed"

install_via_pip
run_and_log build_volatility "Installing volatility"

run_and_log enable_mongodb "Enabling mongodb in cuckoo"

# Networking (last, because sometimes it crashes...)
run_and_log create_hostonly_iface "Creating hostonly interface for cuckoo"
run_and_log setcap "Setting capabilities"

