#
# QGroundControl linux build environment
#

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV DISPLAY=:99

ARG WORKSPACE

# Basic installs
RUN apt-get update && apt-get -y --quiet --no-install-recommends install \
		apt-utils \
		binutils \
		build-essential \
		ca-certificates \
		ccache \
		checkinstall \
		curl \
		g++ \
		gcc \
		git \
        gpg-agent \
		gosu \
		libssl-dev \
		libudev-dev \
		locales \
		lsb-release \
		make \
		openssl \
		patchelf \
		pkg-config \
		rsync \
		software-properties-common \
		sudo \
		wget \
		xvfb \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Install GCC
RUN cd /opt && \
	wget https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz && \
	wget https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc && \
	sha256sum -c arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc && \
	rm arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc && \
	tar xf arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz -C /usr/share && \
	ln -s /usr/share/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-as      /usr/bin/arm-none-eabi-as && \
	ln -s /usr/share/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc     /usr/bin/arm-none-eabi-gcc && \
	ln -s /usr/share/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-g++     /usr/bin/arm-none-eabi-g++ && \
	ln -s /usr/share/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-size    /usr/bin/arm-none-eabi-size && \
	ln -s /usr/share/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-objcopy /usr/bin/arm-none-eabi-objcopy && \
	rm -rf /opt/*

# Create user with id 1000 to not run commands/generate files as root
# Note: sudo access is only meant for development purposes (ie: test installing packages, etc)
RUN useradd user --create-home --home-dir /home/user --shell /bin/bash --uid 1000 && \
    echo 'user:Docker!' | chpasswd && \
    usermod -aG sudo user
USER user

WORKDIR ${WORKSPACE}
CMD /bin/bash
