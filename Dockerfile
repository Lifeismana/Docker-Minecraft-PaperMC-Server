########################################################
############## Running environment #####################
########################################################
FROM ubuntu:focal

LABEL Marc Tönsing <marc@marc.tv>

ARG ZULU_REPO_VER=1.0.0-3

ENV DEBIAN_FRONTEND=noninteractive\
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8\
    TZ=Europe/Paris

RUN set -eux &&\
    apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install gnupg software-properties-common locales curl su-exec && \
    locale-gen en_US.UTF-8 && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9 && \
    curl -sLO https://cdn.azul.com/zulu/bin/zulu-repo_${ZULU_REPO_VER}_all.deb && dpkg -i zulu-repo_${ZULU_REPO_VER}_all.deb && \
    apt-get -qq update && \
    apt-get -qq -y dist-upgrade && \
    apt-get -qq -y --no-install-recommends install zulu17-jdk && \
    apt-get -qq -y purge gnupg software-properties-common curl && \
    apt -y autoremove && \
    rm -rf /var/lib/apt/lists/* zulu-repo_${ZULU_REPO_VER}_all.deb\
    dpkgArch="$(dpkg --print-architecture)";


ENV JAVA_HOME=/usr/lib/jvm/zulu17-ca-${dpkgArch}


# Working directory
WORKDIR /data

# Obtain runable jar from build stage
COPY paperclip.jar /opt/minecraft/paperspigot.jar

# Install and run rcon
ARG RCON_CLI_VER=1.4.8
RUN wget --quiet https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VER}/rcon-cli_${RCON_CLI_VER}_linux_${dpkgArch}.tar.gz -O /tmp/rcon-cli.tgz\
  tar -x -C /usr/local/bin -f /tmp/rcon-cli.tgz rcon-cli && \
  rm /tmp/rcon-cli.tgz

# Volumes for the external data (Server, World, Config...)
VOLUME "/data"

# Expose minecraft port
EXPOSE 25565/tcp
EXPOSE 25565/udp

# Set memory size
ARG memory_size=3G
ENV MEMORYSIZE=$memory_size

# Set Java Flags
ARG java_flags="-Dlog4j2.formatMsgNoLookups=true -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=mcflags.emc.gs -Dcom.mojang.eula.agree=true"
ENV JAVAFLAGS=$java_flags

WORKDIR /data

COPY /docker-entrypoint.sh /opt/minecraft
RUN chmod +x /opt/minecraft/docker-entrypoint.sh


# Entrypoint
ENTRYPOINT ["/opt/minecraft/docker-entrypoint.sh"]

