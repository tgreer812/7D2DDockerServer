FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    lib32gcc-s1 \
    && rm -rf /var/lib/apt/lists/*

ENV STEAMCMD_DIR /opt/steamcmd
RUN mkdir -p $STEAMCMD_DIR

RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -O /tmp/steamcmd.tar.gz && \
    tar -xvzf /tmp/steamcmd.tar.gz -C $STEAMCMD_DIR && \
    rm /tmp/steamcmd.tar.gz

WORKDIR /7dtd

COPY configs/serverconfig.xml /7dtd/serverconfig.xml

# Server installation is now handled by start-server.sh at runtime
# RUN $STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir /7dtd +app_update 294420 validate +quit

COPY ./scripts/start-server.sh /start-server.sh
RUN chmod +x /start-server.sh

EXPOSE 26900/udp 26901/tcp 26902/tcp

CMD ["/start-server.sh"]