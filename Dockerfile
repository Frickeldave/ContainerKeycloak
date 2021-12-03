FROM        ghcr.io/frickeldave/fd_jre11:11.0.13_p8-r0

# Specify the version of keycloak which should be used.
ARG         KC_VERSION=15.0.2
# Sepcify the version of the mariadb j Connector. Tests 3.0.3 version failed, so be careful when updating. 
ARG         DBC_VERSION=2.7.4 

ARG 		fd_builddate
ARG 		fd_buildnumber

LABEL		org.opencontainers.image.authors="David Koenig <dave@frickeldave.de>"
LABEL		org.opencontainers.image.created="2021-11-29"
LABEL		org.opencontainers.image.version="$KC_VERSION"
LABEL		org.opencontainers.image.url="https://github.com/Frickeldave/ContainerKeycloak"
LABEL		org.opencontainers.image.documentation="https://github.com/Frickeldave/ContainerKeycloak/README.md"
LABEL		org.opencontainers.image.source="https://github.com/Frickeldave/ContainerKeycloak"
LABEL 		org.opencontainers.image.description "This is the keycloak image for the docker infrastructure of the Frickeldave environment."
LABEL		de.frickeldave.containers.builddate=$fd_builddate
LABEL		de.frickeldave.containers.buildnumber=$fd_buildnumber

# Install tools needed by keycloak
RUN         apk update; \
            apk upgrade; \ 
            apk --no-cache add mariadb-client; \
            rm -rf /var/lib/apt/lists/*; \
            rm -rf /var/cache/apk/*

# Download and install keycloak
RUN         curl -L https://github.com/keycloak/keycloak/releases/download/${KC_VERSION}/keycloak-${KC_VERSION}.tar.gz --output /home/appuser/app/keycloak.tar.gz --progress-bar; \
	        tar xzf /home/appuser/app/keycloak.tar.gz -C /home/appuser/app; \
            mv /home/appuser/app/keycloak-${KC_VERSION} /home/appuser/app/keycloak; \
	        rm -f /home/appuser/app/keycloak.tar.gz; \
            mkdir /home/appuser/app/keycloak/tools

# Install the mariadb java driver
RUN         mkdir -p /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mariadb/main; \
            curl -L https://downloads.mariadb.com/Connectors/java/connector-java-${DBC_VERSION}/mariadb-java-client-${DBC_VERSION}.jar --output /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mariadb/main/mariadb-java-client.jar --progress-bar

# Add all additional needed files
ADD         start.sh /home/appuser/app/start.sh

ADD         testusers.json /home/appuser/app/keycloak/tools/testusers.json
# Configures the certificates
ADD         keycloak_setcertificate.cli /home/appuser/app/keycloak/tools/keycloak_setcertificates.cli
# Configures the database connection into wildfly config file (used by jboss-cli)
ADD         mariadb_datasource.cli /home/appuser/app/keycloak/tools/mariadb_datasource.cli
# Configure higher timeout values into wildfly config file (used by jboss-cli) - https://serviceorientedarchitect.com/wflyctl0348-timeoutexception-while-running-keycloak-in-a-docker-container-with-an-external-database-mariadb/
ADD         keycloak_settimeout.cli /home/appuser/app/keycloak/tools/keycloak_settimeout.cli
# Copy the mariadb config module
ADD         mariadb_module.xml /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mariadb/main/module.xml

# Set permissions
RUN         chown appuser:appuser /home/appuser/app/start.sh; \
            chown -R appuser:appuser /home/appuser/app/keycloak; \
            chmod +x /home/appuser/app/start.sh

USER        appuser

CMD         ["/home/appuser/app/start.sh"]