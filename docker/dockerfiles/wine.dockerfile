# Basic images to build up X server with wine.
FROM ubuntu:22.04
LABEL maintainer="Michal Sustr <michal.sustr@aic.fel.cvut.cz>"

ENV APP_DIR /app
ENV LOG_DIR $APP_DIR/logs
# Disable stupid install of mono/gecko, we don't need that
ENV WINEDLLOVERRIDES="mscoree,mshtml="
# Wine path
ENV WINEPREFIX /home/starcraft/.wine
# X display
ENV DISPLAY :0.0
# Make possible to use custom title bars
ENV WINEGUI_TITLEBAR "docker"
ARG STARCRAFT_UID=1000
ENV BASE_VNC_PORT 5900

EXPOSE $BASE_VNC_PORT

#####################################################################
USER root

# First create starcraft user and users group
# for all the X Window stuff.
#
# Required to do this first so we have consistent
# uid/gid between server and client container.
#
# Add this user to sudo group for later use if needed.
RUN set -x \
  && adduser \
  --uid $STARCRAFT_UID \
  --home /home/starcraft \
  --disabled-password \
  --shell /bin/bash \
  --ingroup users \
  --quiet \
  starcraft \
  && adduser starcraft sudo \
  && echo 'starcraft:starcraft' | chpasswd


# Install packages required for connecting against X Server
# and for building the image, and some other helpful tools.
#
# Install wine and related packages.
#
# Use the latest version of winetricks
RUN set -x \
  && apt-get update \
  && apt-get install wget gnupg2 software-properties-common -y \
  && dpkg --add-architecture i386 \
  && mkdir -pm755 /etc/apt/keyrings \
  && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
  && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources \
  && apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb xauth x11vnc winehq-stable unzip cabextract xz-utils \
  && wget https://github.com/Winetricks/winetricks/raw/master/src/winetricks \
  && chmod +x winetricks \
  && mv -v winetricks /usr/local/bin \
  && rm -rf /var/lib/apt/lists/*

COPY scripts/winegui /usr/bin/winegui

# Create root APP_DIR
RUN mkdir $APP_DIR && chown starcraft:users $APP_DIR
WORKDIR $APP_DIR

#####################################################################
ARG WINE_ARCH=win32
# Existing images remain win32 unless an image build explicitly opts into WoW64.
ENV WINEARCH=$WINE_ARCH

# Wine shouldn't be run as root, so let's use a 'starcraft' user
USER starcraft

RUN case "$WINEARCH" in win32|win64) ;; *) echo "Unsupported WINE_ARCH: $WINEARCH" >&2; exit 2 ;; esac

RUN mkdir -m 700 $LOG_DIR
VOLUME $LOG_DIR

# Init wine.
# Let's run some command that will make sure the first init runs.
#
# windows doesn't have sleep, but this hack seems to work :-)
RUN set -eux && xvfb-run wine ping 127.0.0.1 -n 1 | cat

