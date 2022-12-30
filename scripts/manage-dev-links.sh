#!/bin/sh

JAILNAME=$2
JAIL_ROOT=/mnt/pool1/iocage/jails/${JAILNAME}/root
DEVLINK_HOME=${JAIL_ROOT}/devlinks
# Links to create in the format of linkname:vendor:device
zwave="0x0658:0x0200"
zigbee="0x1cf1:0x0030"
LINKS="zwave zigbee"

# comment this out to run in full-anger mode
#SAFETY="echo"

printhelp(){
		echo "Usage: $0 [create|destroy] jailname"
		exit 1
}


pfc(){
	test "$(whoami)" == "root" ||  { echo "Must be run as root. USER=$USER. whomi=$(whoami). id=${id}. Exiting." >> /tmp/log; exit; }
	test -d ${DEVLINK_HOME} || mkdir -p ${DEVLINK_HOME} || { echo "${DEVLINK_HOME} missing and I can't create it. Exiting."; exit; }
	test "$2" || { echo "2 arguments reqired."; printhelp; }
}

makelink(){
	link=$1
	case $link in
		zwave)
			vendor=0x0658;
			product=0x0200;
		;;
		zigbee)
			vendor=0x1cf1;
			product=0x0030;
		;;
	esac
	cua_device_num=$(sysctl -a | awk -F[=\ ] '/^dev.umodem.*vendor='${vendor}'.*product='${product}'/{print $25}')
	cd ${JAIL_ROOT}/dev
	cd ${DEVLINK_HOME}
	ln -fs ../dev/cua${cua_device_num} ${link}
}

rmlink(){
	target=${JAIL_ROOT}/dev/$1
	if test -h ${TARGET}; then
		${SAFETY} rm ${TARGET}
	else
		echo "${link} doesn't appear to be a symlink"
	fi
}

# main
pfc $*

case $1 in
	create)		command=makelink;;
	destroy)	command=rmlink;;
	*)			echo "Unknown mode.";
				printhelp;;
esac

for link in ${LINKS}; do
	$command ${link}
done
