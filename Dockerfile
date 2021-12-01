FROM        ghcr.io/frickeldave/fd_jre11:11.0.13_p8-r0

ARG         KC_VERSION=15.0.1
ARG         DBC_VERSION=8.0.27
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
            apk --no-cache add mariadb-client; \
            rm -rf /var/lib/apt/lists/*; \
            rm -rf /var/cache/apk/*

ADD         start.sh /home/appuser/app/start.sh
ADD         module.xml /home/appuser/app/module.xml
ADD         standalone.xml /home/appuser/app/standalone.xml
ADD         keycloak_createdb.sql /home/appuser/app/keycloak_createdb.sql
ADD         testusers.json /home/appuser/app/testusers.json

RUN         curl -L https://downloads.jboss.org/keycloak/${KC_VERSION}/keycloak-${KC_VERSION}.tar.gz --output /home/appuser/app/keycloak.tar.gz --progress-bar; \
	        tar xzf /home/appuser/app/keycloak.tar.gz -C /home/appuser/app; \
            mv /home/appuser/app/keycloak-${KC_VERSION} /home/appuser/app/keycloak; \
	        rm -f /home/appuser/app/keycloak.tar.gz

RUN         curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${DBC_VERSION}.tar.gz --output /home/appuser/app/mysql-connector-java.tar.gz --progress-bar; \
	        tar xzf /home/appuser/app/mysql-connector-java.tar.gz -C /home/appuser/app; \
            mkdir -p /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mysql/main; \
            mv /home/appuser/app/mysql-connector-java-${DBC_VERSION}/mysql-connector-java-${DBC_VERSION}.jar /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mysql/main/mysql-connector-java.jar; \
            cp -f /home/appuser/app/module.xml /home/appuser/app/keycloak/modules/system/layers/keycloak/com/mysql/main/module.xml; \
            rm -rf /home/appuser/app/mysql-connector-java-${DBC_VERSION}; \
            rm -rf /home/appuser/app/mysql-connector-java.tar.gz

RUN         chown appuser:appuser /home/appuser/app/start.sh /home/appuser/app/keycloak_createdb.sql /home/appuser/app/testusers.json; \
            chown -R appuser:appuser /home/appuser/app/keycloak; \
            chmod +x /home/appuser/app/start.sh

USER        appuser

CMD         ["/home/appuser/app/start.sh"]