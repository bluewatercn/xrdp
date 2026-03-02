#!/bin/bash

set -eu

USER=${USER:-user}

adduser --gecos '' $USER \
&& adduser $USER sudo \
&& echo $USER:$USER | chpasswd \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 

#autostart tint2 xterm when openbox started
OPENBOX_PATH="/home/${USER}/.config/openbox"
if [[ ! -e "${OPENBOX_PATH}" ]];then 
	mkdir -p $OPENBOX_PATH 

	for i in tint2 xterm;do 
		echo "$i &" >> ${OPENBOX_PATH}/autostart;
	done;
fi

chown -R $USER:$USER /home/$USER \
&& cd /home/$USER \
&& rm -rf /var/run/xrdp-sesman.pid \
&& rm -rf /var/run/xrdp.pid \
&& rm -rf /var/run/xrdp/xrdp-sesman.pid \
&& rm -rf /var/run/xrdp/xrdp.pid \

# Use exec ... to forward SIGNAL to child processes
&& xrdp-sesman && exec xrdp -n

