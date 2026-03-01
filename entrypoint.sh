#!/bin/bash

set -eu

USER=${USER:-user}

#autostart tint2 xterm when openbox started
OPENBOX_PATH="/home/${USER}/.config/openbox"
if [[ ! -e "${OPENBOX_PATH}" ]];then 
	mkdir -p $OPENBOX_PATH 

	for i in tint2 xterm;do 
		echo "$i &" >> ${OPENBOX_PATH}/autostart;
	done;
fi


# Preventing xrdp startup failure
rm -rf /var/run/xrdp-sesman.pid
rm -rf /var/run/xrdp.pid
rm -rf /var/run/xrdp/xrdp-sesman.pid
rm -rf /var/run/xrdp/xrdp.pid

# Use exec ... to forward SIGNAL to child processes
xrdp-sesman && exec xrdp -n

