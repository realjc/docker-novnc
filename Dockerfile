FROM ubuntu:18.04

USER root 

ENV DEBIAN_FRONTEND noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV HOME=/root SHELL=/bin/bash

COPY /image/etc/apt/sources.list /etc/apt/sources.list
RUN rm -f /etc/apt/sources.list.d/*

COPY /image/etc/pip.conf /root/.pip/pip.conf 

# install:
RUN apt-get update -q --fix-missing && \
    apt-get install -y --no-install-recommends --allow-unauthenticated \
        # PPA utilities:
        software-properties-common \
        # certificates management:
        dirmngr gnupg2 \
        # download utilities:
        axel aria2 && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-keys 1EE2FF37CA8DA16B && \
    add-apt-repository ppa:apt-fast/stable && \
    apt-get update -q --fix-missing && \
    apt-get install -y --no-install-recommends --allow-unauthenticated apt-fast && \
    rm -rf /var/lib/apt/lists/*

COPY /image/etc/apt-fast.conf /etc/apt-fast.conf

RUN apt-fast update --fix-missing && \
    apt-fast install -y --no-install-recommends --allow-unauthenticated \
        # package utils:
        sudo dpkg pkg-config apt-utils \
        # security:
        openssh-server pwgen ca-certificates \
        # network utils:
        curl wget iputils-ping net-tools \
        # command line:
        vim grep sed patch \
        # io:
        pv zip unzip bzip2 \
        # version control:
        git mercurial subversion \
        # daemon & services:
        supervisor nginx \
        # potential image & rich text IO:
        lxde \
        xvfb dbus-x11 x11-utils libxext6 libsm6 x11vnc \
        gtk2-engines-pixbuf gtk2-engines-murrine pinta ttf-ubuntu-font-family \
        mesa-utils libgl1-mesa-dri libxrender1 \
        texlive-latex-extra \
        # c++:
        gcc g++ \
        make cmake build-essential autoconf automake libtool \
        libglib2.0-dev libboost-dev libboost-all-dev libtbb-dev \
        # python 2:
        python-pip python-dev python-tk \
        # development common:
        lua5.3 liblua5.3-dev libluabind-dev \
        libgoogle-glog-dev \
        libsdl1.2-dev \
        libsdl-image1.2-dev \
        # numerical optimization:
        coinor-libcoinutils-dev \
        coinor-libcbc-dev \
        libeigen3-dev \
        gfortran \
        libopenblas-dev liblapack-dev \
        libdw-dev libatlas-base-dev libsuitesparse-dev \
        libmetis-dev \
        # graph optimization -- https://github.com/RainerKuemmerle/g2o
        # a. visualization:
        libqt4-dev libqt4-opengl-dev \
        qt5-default qt5-qmake qtdeclarative5-dev libqglviewer-dev-qt5 \
        # GUI tools:
        freeglut3-dev \
        gnuplot \
        gnome-themes-standard \
        terminator \
        firefox && \
    apt-fast autoclean && \
    apt-fast autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN pip install ordered-startup-supervisord

COPY image/download-tini.sh /tmp/installers/
WORKDIR /tmp/installers

RUN chmod u+x ./download-tini.sh && ./download-tini.sh && dpkg -i tini.deb && \
    apt-get clean

RUN rm -rf /tmp/installers

COPY image /

WORKDIR /usr/lib/

RUN git clone https://github.com/novnc/noVNC.git -o noVNC

WORKDIR /usr/lib/noVNC/utils

RUN git clone https://github.com/novnc/websockify.git -o websockify

WORKDIR /usr/lib/webportal

RUN pip install -U pip setuptools 
RUN pip2 install --upgrade pip && pip2 install -r requirements.txt

EXPOSE 80 5901 9001

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /
RUN chmod +x ./startup.sh

ENTRYPOINT ["./startup.sh"]