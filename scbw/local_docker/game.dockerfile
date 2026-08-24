ARG BASE_IMAGE=starcraft:java
FROM ${BASE_IMAGE}
LABEL maintainer="Michal Sustr <michal.sustr@aic.fel.cvut.cz>"

#####################################################################
USER starcraft
WORKDIR $SC_DIR

# Get Starcraft game from ICCUP
COPY starcraft.zip /tmp/starcraft.zip
COPY player* /tmp/

RUN unzip -q /tmp/starcraft.zip -d /tmp/starcraft \
    && rm -rf /tmp/starcraft/characters/* /tmp/starcraft/maps/* \
    && chown starcraft:users -R /tmp/starcraft \
    && cp /tmp/player* /tmp/starcraft/characters \
    && chown starcraft:users -R /tmp/starcraft/characters

USER root
RUN rm /tmp/starcraft.zip \
    && mv /tmp/starcraft/* $SC_DIR/

USER starcraft

RUN mkdir -m 775 $BWAPI_DATA_DIR $BWAPI_DATA_BWTA_DIR $BWAPI_DATA_BWTA2_DIR
RUN mkdir -m 755 $BOT_DIR $BOT_DATA_AI_DIR $BOT_DATA_READ_DIR
RUN mkdir -m 777 $BOT_DATA_WRITE_DIR $ERRORS_DIR
VOLUME $BWAPI_DATA_BWTA_DIR $BWAPI_DATA_BWTA2_DIR $MAP_DIR $BOT_DIR $BOT_DATA_WRITE_DIR $ERRORS_DIR

RUN echo "umask 0027" >> /home/starcraft/.bashrc

# Update the StarCraft registry keys
# This was previously done in a script on container startup (see play_common.sh), but it's more efficient to do at build time
# The sleep at the end is important, as we need to ensure the file is flushed before Docker creates the layer
RUN wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v ColorCycle /t REG_DWORD /d 00000001 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v UnitPortraits /t REG_DWORD /d 00000002 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v speed /t REG_DWORD /d 00000006 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v mscroll /t REG_DWORD /d 00000001 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v kscroll /t REG_DWORD /d 00000001 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v m_mscroll /t REG_DWORD /d 00000003 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v m_kscroll /t REG_DWORD /d 00000003 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v tipnum /t REG_DWORD /d 00000001 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v intro /t REG_DWORD /d 00000200 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v introX /t REG_DWORD /d 00000000 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v unitspeech /t REG_DWORD /d 00000001 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v unitnoise /t REG_DWORD /d 00000002 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v bldgnoise /t REG_DWORD /d 00000004 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v tip /t REG_DWORD /d 00000100 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v trigtext /t REG_DWORD /d 00000400 \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v StarEdit /t REG_EXPAND_SZ /d "Z:\app\sc\StarEdit.exe" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v "Recent Maps"  /t REG_EXPAND_SZ /d "" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v Retail /t REG_EXPAND_SZ /d "y" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v Brood  /t REG_EXPAND_SZ /d "y" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v StarCD /t REG_EXPAND_SZ /d "" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v InstallPath /t REG_EXPAND_SZ /d "Z:\app\sc\\" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Blizzard Entertainment\Starcraft" /v Program /t REG_EXPAND_SZ /d "Z:\app\sc\StarCraft.exe" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Blizzard Entertainment\Starcraft\DelOpt0" /v File0 /t REG_EXPAND_SZ /d "spc" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Blizzard Entertainment\Starcraft\DelOpt0" /v File1 /t REG_EXPAND_SZ /d "mpc" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Blizzard Entertainment\Starcraft\DelOpt0" /v Path0 /t REG_EXPAND_SZ /d "Z:\app\sc\characters" \
    && wine REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Blizzard Entertainment\Starcraft\DelOpt0" /v Path1 /t REG_EXPAND_SZ /d "Z:\app\sc\characters" \
    && sleep 5

WORKDIR $APP_DIR
