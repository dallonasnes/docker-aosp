#
# Minimum Docker image to build Android AOSP
#
FROM ubuntu:16.04

MAINTAINER Kyle Manna <kyle@kylemanna.com>

# /bin/sh points to Dash by default, reconfigure to use bash until Android
# build becomes POSIX compliant
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

# Keep the dependency list as short as reasonable
RUN apt-get update && \
	apt -y install sudo

ARG DEBIAN_FRONTEND=noninteractive
RUN apt install autoconf dh-autoreconf libcurl4-openssl-dev tcl-dev gettext asciidoc docbook2x install-info libexpat1-dev libz-dev -y

RUN apt-get install -y apt-utils bc bison bsdmainutils build-essential curl ccache \
        flex g++-multilib gcc-multilib gnupg gperf lib32ncurses5-dev \
        lib32z1-dev libesd0-dev libncurses5-dev \
        libsdl1.2-dev libwxgtk3.0-dev libxml2-utils lzop sudo \
        openjdk-8-jdk \
        pngcrush schedtool wget xsltproc zip zlib1g-dev graphviz && \
    apt-get clean 

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get install -y python3.7

RUN rm /usr/bin/python
RUN ln -s /usr/bin/python3.7 /usr/bin/python
RUN PATH=/usr/bin/python:$PATH
RUN mkdir -p /usr/local/bin
RUN PATH=/usr/local/bin:$PATH

RUN apt-get install -y openjdk-8-jdk android-tools-adb bc bison build-essential curl flex g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev libgtk-3-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc yasm zip zlib1g-dev fakeroot dpkg-dev

WORKDIR /tmp
ADD ./compile-git-with-openssl.sh .
RUN bash compile-git-with-openssl.sh

RUN git config --global user.name "Dallon Asnes"
RUN git config --global user.email "dallon.asnes@gmail.com"

RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo
RUN repo init -u https://android.googlesource.com/platform/manifest
# Install latest version of JDK
# See http://source.android.com/source/initializing.html#setting-up-a-linux-build-environment

# All builds will be done by user aosp
COPY gitconfig /root/.gitconfig
COPY ssh_config /root/.ssh/config

# The persistent data will be in these two directories, everything else is
# considered to be ephemeral
VOLUME ["/tmp/ccache", "/aosp"]

# Work in the build directory, repo is expected to be init'd here
WORKDIR /aosp
RUN apt-get install ccache
COPY utils/docker_entrypoint.sh /root/docker_entrypoint.sh
ENTRYPOINT ["/root/docker_entrypoint.sh"]
