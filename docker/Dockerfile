FROM ubuntu:24.04

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

# Create data directory and declare as volume
RUN mkdir -p /data
VOLUME /data

WORKDIR /7dtd

# Server installation - Do this early for better caching
# It doesn't depend on the config file being present during install
RUN $STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir /7dtd +app_update 294420 validate +quit

# Now copy configs and scripts, which change more often
# Copy both config files from the build context first.
COPY configs/serverconfig.xml /7dtd/myserverconfig.xml
COPY configs/serverconfig.default.xml /7dtd/serverconfig.default.xml

# Check if serverconfig.xml exists *within the image*. Copy default if needed.
RUN if [ ! -f /7dtd/serverconfig.xml ]; then \
    echo "WARNING: configs/serverconfig.xml not found in build context. Using default server configuration."; \
    cp /7dtd/serverconfig.default.xml /7dtd/serverconfig.xml; \
    fi

# Copy Scripts
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Set Working Directory
WORKDIR /app

EXPOSE 26900/udp 26900/tcp 26901/udp 26902/udp 26903/udp 8080/tcp 8081/tcp

# Define Entrypoint
ENTRYPOINT ["/app/scripts/start-server.sh"]