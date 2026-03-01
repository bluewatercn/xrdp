FROM debian:experimental AS builder
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git build-essential libpulse-dev libsndfile-dev \
        autoconf libtool intltool pkg-config \
        lsb-release dpkg-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /root
RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /root/pulseaudio-module-xrdp
RUN ./scripts/install_pulseaudio_sources_apt.sh
RUN ./bootstrap && ./configure PULSE_DIR=/root/pulseaudio.src
RUN make
RUN make install
RUN find /usr/lib -name "module-xrdp-*.so" > /tmp/path.txt
RUN mkdir -p /tmp/modules;for i in $(cat /tmp/path.txt);do cp $i /tmp/modules;done


########################################################################
FROM debian:experimental
ARG USER=user
ENV USER=user
ENV DEBIAN_FRONTEND=noninteractive

# COPY ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh

# DISABLE LANGUAGE CACHE
RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99nolanguages

# INSTALL BASE
RUN apt-get update \
     && apt-get install -y --fix-broken --no-install-recommends --no-install-suggests sudo pulseaudio vim psmisc openbox obconf tint2 xterm fonts-wqy-zenhei fonts-liberation pavucontrol dbus-x11 libutempter0 firefox xrdp xorgxrdp  \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* \
     && rm -rf /usr/share/doc/* /usr/share/man/* /tmp/* \
     && rm -rf /usr/share/locale/* \
     && chmod +x /entrypoint.sh \
     && adduser --gecos '' $USER \
     && adduser $USER sudo \
     && echo $USER:$USER | chpasswd \
     && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 

# COPY FROM BUILDER
COPY --from=builder /tmp/path.txt /tmp/path.txt
COPY --from=builder /tmp/modules/ /tmp/modules/
RUN des_path=$(sed -n 1p /tmp/path.txt | awk 'BEGIN{FS="/";OFS="/"}{$NF="";print $0}') ; mv /tmp/modules/* $des_path ; rm /tmp/path.txt

# CONFIG FILE
RUN  echo '#!/bin/sh' > /etc/xrdp/startwm.sh  \
     && echo 'pulseaudio --daemonize=yes --system=false --exit-idle-time=-1 --log-target=stderr'  >> /etc/xrdp/startwm.sh \
     && echo 'pactl load-module module-xrdp-sink' >> /etc/xrdp/startwm.sh \
     && echo 'pactl load-module module-xrdp-source' >> /etc/xrdp/startwm.sh \
     && echo 'pactl set-default-sink xrdp-sink' >> /etc/xrdp/startwm.sh \
     && echo 'pactl set-default-source xrdp_source' >> /etc/xrdp/startwm.sh \
     && echo 'exec openbox-session' >> /etc/xrdp/startwm.sh \
     && chown -R $USER:$USER /home/$USER

WORKDIR /home/$USER
ENTRYPOINT ["/entrypoint.sh"]

