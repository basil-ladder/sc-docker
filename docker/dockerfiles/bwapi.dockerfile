ARG BASE_IMAGE=starcraft:wine
FROM ${BASE_IMAGE}
LABEL maintainer="Michal Sustr <michal.sustr@aic.fel.cvut.cz>"

ARG NVCUDA_RELAY_URL=https://github.com/SveSop/nvcuda/releases/download/v0.2/nvcuda-0.2.tar.xz
ARG NVCUDA_RELAY_SHA256=38003fc9f045474fa9e19b9e4f6232fafa7041499c48563e82e538c74d385326

ENV SC_DIR="$APP_DIR/sc"
ENV BWTA_DIR="$APP_DIR/bwta"
ENV BWAPI_DIR="$APP_DIR/bwapi"
ENV TM_DIR="$APP_DIR/tm"
ENV BOT_DIR="$APP_DIR/bot"
ENV MAP_DIR="$SC_DIR/maps"
ENV ERRORS_DIR="$SC_DIR/Errors"
ENV BWAPI_DATA_DIR="$SC_DIR/bwapi-data"

ENV BOT_DATA_AI_DIR="$BWAPI_DATA_DIR/AI"
ENV BOT_DATA_READ_DIR="$BWAPI_DATA_DIR/read"

# Entire BWAPI data dir is not shared with host, only these subdirs:
ENV BWAPI_DATA_BWTA_DIR="$BWAPI_DATA_DIR/BWTA"
ENV BWAPI_DATA_BWTA2_DIR="$BWAPI_DATA_DIR/BWTA2"
ENV BOT_DATA_WRITE_DIR="$BWAPI_DATA_DIR/write"

ARG BOT_UID=1001

# these are ports that SC uses,
# according to http://wiki.teamliquid.net/starcraft/Port_Forwarding
EXPOSE 6111:6119 6111:6119/udp

#####################################################################
USER root

# Create bot user which will have access only to BOT_DATA_*_DIR
RUN set -x \
    && addgroup bot \
    && adduser \
    --uid $BOT_UID \
    --ingroup users \
    --home /home/bot \
    --disabled-password \
    --gecos "" \
    --shell /bin/bash \
    --quiet \
    bot \
    && usermod -aG bot bot

# Sometime there was a weird error with protocols
COPY protocols /etc/protocols

#####################################################################
USER starcraft
WORKDIR $APP_DIR

# Create SC dir
RUN mkdir "${SC_DIR}"

# A 64-bit Wine prefix runs 32-bit StarCraft through WoW64. Keep PE32 DLLs
# in syswow64 and PE32+ DLLs in system32; win32 prefixes retain the legacy
# system32 layout.
COPY --chown=starcraft:users dlls/ /tmp/sc-docker-dlls/
RUN set -eux; \
    if [ "$WINEARCH" = "win64" ]; then \
      for dll in /tmp/sc-docker-dlls/*.dll; do \
        if winedump dump "$dll" | grep -q 'Optional Header (64bit)'; then \
          cp "$dll" "$WINEPREFIX/drive_c/windows/system32/"; \
        else \
          cp "$dll" "$WINEPREFIX/drive_c/windows/syswow64/"; \
        fi; \
      done; \
      wget -q -O /tmp/nvcuda-relay.tar.xz "$NVCUDA_RELAY_URL"; \
      echo "$NVCUDA_RELAY_SHA256  /tmp/nvcuda-relay.tar.xz" | sha256sum -c -; \
      tar -xf /tmp/nvcuda-relay.tar.xz -C /tmp; \
      cp /tmp/nvcuda-0.2/x64/nvcuda.dll "$WINEPREFIX/drive_c/windows/system32/"; \
      rm -rf /tmp/nvcuda-0.2 /tmp/nvcuda-relay.tar.xz; \
    else \
      cp /tmp/sc-docker-dlls/*.dll "$WINEPREFIX/drive_c/windows/system32/"; \
    fi; \
    rm -rf /tmp/sc-docker-dlls

# Install more dlls from winetricks. It requires X-server so let's run in bg for now :)
RUN /bin/bash -c "Xvfb :0 -auth ~/.Xauthority -screen 0 640x480x24 & winetricks -q vcrun2015"

# Copy bwheadless
COPY --chown=starcraft:users bwheadless.exe $SC_DIR

# Copy relevant BWAPI versions (cached)
COPY --chown=starcraft:users bwapi $BWAPI_DIR
COPY --chown=starcraft:users tm $TM_DIR

COPY scripts/launch_game /usr/bin/launch_game

#####################################################################
# Create wine profile for bot
USER root
RUN cp -r /home/starcraft/.wine /home/bot/.wine \
    && chown -R bot:users /home/bot/.wine

#####################################################################
USER starcraft
CMD ["./bwapi_entrypoint.sh"]
