#!/bin/sh

INITIALSTART=0

# set initstart variable
echo "Running start.sh script of keycloak"

# set initstart variable
if [ ! -f /home/appuser/data/firststart.flg ]
then 
    echo "First start, set initialstart variable to 1"
    INITIALSTART=1
    echo `date +%Y-%m-%d_%H:%M:%S_%z` > /home/appuser/data/firststart.flg
else
	echo "It's not the first start, skip first start section"
fi

echo "Connect to mariadb with user healthstatus (https://github.com/Frickeldave/ContainerBase/tree/main/mariadb)"
while ! mysql -h ${KC_MDBHOST} -u ${KC_MDBHEALTHUSER} -p${KC_MDBHEALTHPWD} -P ${KC_MDBPORT} -e "show databases;"; do
   echo "MariaDB server (${KC_MDBHOST}) is not available. Wait 5s and try again ..."
    sleep 5s
done

echo "Wait additional time, because the MariaDB server will be restarted after creating the healthstatus user"
sleep 15s

echo "Check if its initial start"
if [ "$INITIALSTART" == "1" ]
then
    echo "initialstart variable is set to $INITIALSTART"
    
    echo "First start. Create initial certificates with an alternative name"
    export CRT_ALTNAME=${KC_BINDADDRESS}
    export CRT_ALTTYPE="IP"
	/home/appuser/app/tools/createcerts.sh

    echo "Create certificate for keycloak"
    openssl pkcs12 -export -in /home/appuser/data/certificates/cer.crt -inkey /home/appuser/data/certificates/key.key -out /home/appuser/data/certificates/keycloak.p12 -passout pass:${KC_CERTPWD}

    echo "Create keystore for keycloak"
    keytool -importkeystore -noprompt -deststorepass ${KC_CERTPWD} -destkeypass ${KC_CERTPWD} -destkeystore /home/appuser/data/certificates/keycloak_keystore.jks -srckeystore /home/appuser/data/certificates/keycloak.p12 -srcstoretype PKCS12 -srcstorepass ${KC_CERTPWD} -deststoretype pkcs12

    echo `date +%Y-%m-%d_%H:%M:%S_%z` > /home/appuser/data/firststart_finished.flg
fi


if [[ -n ${KC_ADMINUSER:-} && -n ${KC_ADMINPWD:-} ]]
then
    /home/appuser/app/keycloak/bin/add-user-keycloak.sh --user "${KC_ADMINUSER}" --password "${KC_ADMINPWD}"
fi

#   echo "set keycloak_tls_keystore_password=${PASSWORD}" >> "$JBOSS_HOME/bin/.jbossclirc"
#   echo "set keycloak_tls_keystore_file=${KEYSTORES_STORAGE}/${JKS_KEYSTORE_FILE}" >> "$JBOSS_HOME/bin/.jbossclirc"
#   echo "set configuration_file=standalone.xml" >> "$JBOSS_HOME/bin/.jbossclirc"
#   $JBOSS_HOME/bin/jboss-cli.sh --file=/opt/jboss/tools/cli/x509-keystore.cli >& /dev/null
#   sed -i '$ d' "$JBOSS_HOME/bin/.jbossclirc"
#   echo "set configuration_file=standalone-ha.xml" >> "$JBOSS_HOME/bin/.jbossclirc"
#   $JBOSS_HOME/bin/jboss-cli.sh --file=/opt/jboss/tools/cli/x509-keystore.cli >& /dev/null
#   sed -i '$ d' "$JBOSS_HOME/bin/.jbossclirc"

echo "Increase timeout values (needed for database initialization"
/home/appuser/app/keycloak/bin/jboss-cli.sh --file=/home/appuser/app/keycloak/tools/keycloak_settimeout.cli

echo "Load datasource into configuration"
/home/appuser/app/keycloak/bin/jboss-cli.sh --file=/home/appuser/app/keycloak/tools/keycloak_setcertificates.cli

echo "Load datasource into configuration"
/home/appuser/app/keycloak/bin/jboss-cli.sh --file=/home/appuser/app/keycloak/tools/mariadb_datasource.cli

if [[ -n ${KC_AJPINTPORT:-} ]]; then export SYS_PROPS="$SYS_PROPS -Djboss.ajp.port=${KC_AJPINTPORT}"; fi
if [[ -n ${KC_HTTPINTPORT:-} ]]; then export SYS_PROPS="$SYS_PROPS -Djboss.http.port=${KC_HTTPINTPORT}"; fi
if [[ -n ${KC_HTTPSINTPORT:-} ]]; then export SYS_PROPS="$SYS_PROPS -Djboss.https.port=${KC_HTTPSINTPORT}"; fi
if [[ -n ${KC_MGNTHTTPINTPORT:-} ]]; then export SYS_PROPS="$SYS_PROPS -Djboss.management.http.port=${KC_MGNTHTTPINTPORT}"; fi
if [[ -n ${KC_MGNTHTTPSINTPORT:-} ]]; then export SYS_PROPS="$SYS_PROPS -Djboss.management.https.port=${KC_MGNTHTTPSINTPORT}"; fi

echo "Following port are configured"
echo "$SYS_PROPS"

echo "Start keycloak."
/home/appuser/app/keycloak/bin/standalone.sh --server-config=standalone.xml $SYS_PROPS 