About CuckooAutoinstall
=======================

`Cuckoo Sandbox <http://www.cuckoosandbox.org/>`_. auto install script

What is Cuckoo Sandbox?
-----------------------

Cuckoo Sandbox is a malware analysis system.

What does that mean? 
--------------------

It means that you can throw any suspicious file at it and get a report with
details about the file's behavior inside an isolated environment.

The original file was created by the team at `Buguroo Offensive Security <http://www.buguroo.com>`_  to make
the initial installation quicker, easier and a little less painful.

I have since "improved" the script by adding Volatility 2.5 and generating more log files (to troubleshoot any errors/issues).

Supported systems
-----------------

This script is designed for Ubuntu 14.04 and worked for me on 1 October 2016.  I think it will work on Debian, but no
guarantees.  

Also, given that we use the propietary virtualbox version (most of the time OSE
edition doesn't fulfill our needs), this script requires that they've got
a debian repo in `Virtualbox Downloads <http://downloads.virtualbox.org>`_ 
for your distro. Forcing the distro in config file should make it work in
unsupported ones.

Authors
-------

`John Jacob Gingleheimer Schmidt - JJGS <https://github.com/Jacob-Gingleheimer>`_ - `jacob.gingleheimer@gmail.com <mailto:jacob.gingleheimer@gmail.com>`_

`David Reguera García - Dreg <http://github.com/David-Reguera-Garcia-Dreg>`_ - `dreguera@buguroo.com <mailto:dreguera@buguroo.com>`_ - `@fr33project <https://twitter.com/fr33project>`_ 

`David Francos Cuartero - XayOn <http://github.com/Xayon>`_ - `dfrancos@buguroo.com <mailto:dfrancos@buguroo.com>`_ - `@davidfrancos <https://twitter.com/davidfrancos>`_


Quickstart guide
================

* Clone this repo & execute the script: *bash cuckooautoinstall.bash*

.. image:: https://github.com/Jacob-Gingleheimer/cuckooautoinstall/blob/master/doc/Cropped%20CuckooAutoInstall%201.0.png


If you trust us, your network setup and a lot of more variables enough
(wich is totally not-recommended) and you're as lazy as it gets, you can
execute as a normal user if you've got sudo configured:

::

    wget -O - https://raw.githubusercontent.com/jacob-gingleheimer/cuckooautoinstall/master/cuckooautoinstall.bash | bash



The script does accept a configuration file in the form of a simple
bash script with options such as:

::

    SUDO="sudo"
    TMPDIR=$(mktemp -d)
    chmod 777 $TMPDIR
    RELEASE=$(lsb_release -cs)
    CUCKOO_USER="cuckoo"
    INSTALL_USER=$(whoami)
    CUCKOO_REQS="/home/cuckoo/cuckoo/requirements.txt"
    ORIG_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
    VOLATILITY_URL="http://downloads.volatilityfoundation.org/releases/2.5/volatility_2.5.linux.standalone.zip"
    VIRTUALBOX_REP="deb http://download.virtualbox.org/virtualbox/debian $RELEASE contrib"
    CUCKOO_REPO='https://github.com/cuckoobox/cuckoo'
    CUCKOO_BRANCH="master"
    YARA_REPO="https://github.com/plusvic/yara"
    JANSSON_REPO="https://github.com/akheron/jansson"

If you want to change any of these variables, download and tweak as you see fit.

It doesn't accept parameters. **DEALL** :-P

::

    ┌─────────────────────────────────────────────────────────┐
    │                CuckooAutoInstall 1.0                    │
    │   Just contributing a little bit & trying to help out   │
    │ Jacob Gingleheimer - JJGS <jacob.gingleheimer@gmail.com>│
    │                                                         │
    │ Using the code provided by:                             │
    │ David Reguera García - Dreg <dreguera@buguroo.com>      │
    │ David Francos Cuartero - XayOn <dfrancos@buguroo.com>   │
    │            Buguroo Offensive Security - 2015            │
    │                                                         │
    └─────────────────────────────────────────────────────────┘
    Usage: cuckooautoinstall.bash 
     **NOTE**  There is no help.  It either works or it don't :-P

CONGRATS! You have successfully installed Cuckoo Sandbox.  You have finished step 2 in setting up the host.  Continue along here: `Configuration <http://docs.cuckoosandbox.org/en/latest/installation/host/configuration/>`_     

* Add a password (as root) for the user *'cuckoo'* created by the script

::

    sudo bash
    passwd cuckoo

* Create the virtual machines `http://docs.cuckoosandbox.org/en/latest/installation/guest/`
  or import virtual machines

::

  VBoxManage import virtual_machine.ova

* Add to the virtual machines with HostOnly option using vboxnet0

::

  vboxmanage modifyvm “virtual_machine" --hostonlyadapter1 vboxnet0

* Configure cuckoo (`http://docs.cuckoosandbox.org/en/latest/installation/host/configuration/` )

* Execute cuckoo 

::

  cd ~cuckoo/cuckoo
  python cuckoo.py

.. image::  https://github.com/Jacob-Gingleheimer/cuckooautoinstall/blob/master/doc/Cropped%20Cuckoo%20first%20launch.png 
* And if you want all the community created goodies, execute one or both of the following commands
::

  ./utils/community.py -wafb monitor` or `./utils/community.py -waf


* Execute also django using port 6969

::

  cd ~cuckoo/cuckoo/web
  python manage.py runserver 0.0.0.0:6969

.. image:: /../screenshots/github%20django.png?raw=true

Script features
=================

* Installs by default Cuckoo sandbox with the ALL optional stuff: yara, ssdeep, django ...
* Installs the last versions of ssdeep, yara, pydeep-master & jansson.
* Solves common problems during the installation: ldconfigs, autoreconfs...
* Installs by default virtualbox and *creates the hostonlyif*.
* Creates the *'cuckoo'* user in the system and it is also added this user to *vboxusers* group.
* Enables *mongodb* in *conf/reporting.conf* 
* Creates the *iptables rules* and the ip forward to enable internet in the cuckoo virtual machines

::

    sudo iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
    sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A POSTROUTING -t nat -j MASQUERADE
    sudo sysctl -w net.ipv4.ip_forward=1

Enables run *tcpdump* from nonroot user

::

    sudo apt-get -y install libcap2-bin
    sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

Again CONGRATS! You have successfully installed Cuckoo Sandbox.  You have finished step 2 in setting up the host.  Continue along with the host `configuration <http://docs.cuckoosandbox.org/en/latest/installation/host/configuration/>`_ 

Install cuckoo as daemon
==========================

For this, we recommend supervisor usage.

Install supervisor

::

    sudo apt-get install supervisor

Edit */etc/supervisor/conf.d/cuckoo.conf* , like

::

        [program:cuckoo]
        command=python cuckoo.py
        directory=/home/cuckoo
        User=cuckoo

        [program:cuckoo-api]
        command=python api.py
        directory=/home/cuckoo/utils
        user=cuckoo

Reload supervisor

::

  sudo supervisorctl reload


iptables
========

As you probably have already noticed, iptables rules don't stay there after
a reboot. If you want to make them persistent, we recommend 
iptables-save & iptables-restore

::

    iptables-save > your_custom_iptables_rules
    iptables-restore < your_custom_iptables_rules



Extra help
==========

You may want to read:

* `Remote <./doc/Remote.rst>`_ - Enabling remote administration of VMS and VBox
* `OVA <./doc/OVA.rst>`_ - Working with OVA images
* `Antivm <./doc/Antivm.rst>`_ How to deal with malware that has VM detection techniques
* `VMcloak <./doc/Vmcloak.rst>`_ VMCloak - Cuckoo windows virtual machines management

TODO
====

* Improve documentation

Contributing
============

This project is licensed as GPL3+ as you can see in "LICENSE" file.
All pull requests are welcome, having in mind that:

- The scripting style must be compliant with the current one
- New features must be in sepparate branches (way better if it's git-flow =) )
- Please, check that it works correctly before submitting a PR.

We'd probably be answering to PRs in a 7-14 day period, please be patient.
