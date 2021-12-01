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

echo "Connect to mysql with user healthstatus (https://github.com/Frickeldave/ContainerBase/tree/main/mariadb)"
while ! mysql -h ${KC_MYSQLHOST} -u ${KC_MYSQLHEALTHUSER} -p${KC_MYSQLHEALTHPWD} -P ${KC_MYSQLPORT} -e "show databases;"; do
   echo "MariaDB server (${KC_MYSQLHOST}) is not available. Wait 5s and try again ..."
    sleep 5s
done

echo "Wait additional time, because the MariaDB server will be restarted after creating the healthstatus user"
sleep 15s

# delete old config file
if [ -f /home/appuser/data/standalone.xml ]; then echo "delete old config file"; rm -f /home/appuser/data/standalone.xml; fi

echo "Use keycloak.xml which is stored in /home/appuser/app"
cp -f /home/appuser/app/standalone.xml /home/appuser/data/standalone.xml

echo "patch keycloak.xml configuration file"
echo "patch MYSQLHOST"
sed -i -e "s/#KC_MYSQLHOST#/${KC_MYSQLHOST}/g" /home/appuser/data/standalone.xml
echo "patch MYSQLPORT"
sed -i -e "s/#KC_MYSQLPORT#/${KC_MYSQLPORT}/g" /home/appuser/data/standalone.xml
echo "patch MYSQLDB"
sed -i -e "s/#KC_MYSQLDB#/${KC_MYSQLDB}/g" /home/appuser/data/standalone.xml
echo "patch MYSQLUSERNAME"
sed -i -e "s/#KC_MYSQLUSERNAME#/${KC_MYSQLUSERNAME}/g" /home/appuser/data/standalone.xml
echo "patch MYSQLPASSWORD"
sed -i -e "s/#KC_MYSQLPASSWORD#/${KC_MYSQLPASSWORD}/g" /home/appuser/data/standalone.xml

echo "patch AJPPORT (orig: 8009)"
sed -i -e "s/#KC_AJPINTPORT#/${KC_AJPINTPORT}/g" /home/appuser/data/standalone.xml
echo "patch KC_HTTPINTPORT (orig: 8080)"
sed -i -e "s/#KC_HTTPINTPORT#/${KC_HTTPINTPORT}/g" /home/appuser/data/standalone.xml
echo "patch KC_HTTPSINTPORT (orig: 8443)"
sed -i -e "s/#KC_HTTPSINTPORT#/${KC_HTTPSINTPORT}/g" /home/appuser/data/standalone.xml
echo "patch KC_MGNTHTTPINTPORT (orig: 9990)"
sed -i -e "s/#KC_MGNTHTTPINTPORT#/${KC_MGNTHTTPINTPORT}/g" /home/appuser/data/standalone.xml
echo "patch KC_MGNTHTTPSINTPORT (orig: 9993)"
sed -i -e "s/#KC_MGNTHTTPSINTPORT#/${KC_MGNTHTTPSINTPORT}/g" /home/appuser/data/standalone.xml

echo "patch KC_BINDADDRESS"
sed -i -e "s/#KC_BINDADDRESS#/${KC_BINDADDRESS}/g" /home/appuser/data/standalone.xml
echo "patch KC_CERTPWD"
sed -i -e "s/#KC_CERTPWD#/${KC_CERTPWD}/g" /home/appuser/data/standalone.xml
echo "patch MC_PROJECT"
sed -i -e "s/#MC_PROJECT#/${MC_PROJECT}/g" /home/appuser/data/standalone.xml


echo "Check if its initial start"
if [ "$INITIALSTART" == "1" ]
then
    echo "initialstart variable is set to $INITIALSTART"
    
    echo "First start. Create initial certificates with an alternative name"
    export CRT_ALTNAME=${KC_BINDADDRESS}
    export CRT_ALTTYPE="IP"
	/home/appuser/app/helper/createcerts.sh

    echo "Create certificate for keycloak"
    openssl pkcs12 -export -in /home/appuser/data/certificates/cer.pem -inkey /home/appuser/data/certificates/key.pem -out /home/appuser/data/certificates/keycloak.p12 -passout pass:${KC_CERTPWD}

    echo "Create keystore for keycloak"
    keytool -importkeystore -noprompt -deststorepass ${KC_CERTPWD} -destkeypass ${KC_CERTPWD} -destkeystore /home/appuser/data/certificates/keycloak_keystore.jks -srckeystore /home/appuser/data/certificates/keycloak.p12 -srcstoretype PKCS12 -srcstorepass ${KC_CERTPWD} -deststoretype pkcs12

    ## Disabled, beacuse database should be created with mariadb container scripts
    # if [ "$KC_REMOVE_DB" == "true" ]
    # then 
    #     echo "Remove existing database"
    #     mysql -h ${KC_MYSQLHOST} -u ${KC_MYSQLADMINUSER} -p${KC_MYSQLADMINPASSWORD} -P ${KC_MYSQLPORT} -e "DROP DATABASE IF EXISTS ${KC_MYSQLDB}"
    # fi 

    # echo "copy database creation script to data directory"
    # cp /home/appuser/app/keycloak_createdb.sql /home/appuser/data/keycloak_createdb.sql

    # echo "patch keycloak_createdb.sql based on given environment variables"
    # sed -i -e "s/#KC_MYSQLUSERNAME#/${KC_MYSQLUSERNAME}/g" /home/appuser/data/keycloak_createdb.sql
    # sed -i -e "s/#KC_MYSQLPASSWORD#/${KC_MYSQLPASSWORD}/g" /home/appuser/data/keycloak_createdb.sql
    # sed -i -e "s/#KC_MYSQLDB#/${KC_MYSQLDB}/g" /home/appuser/data/keycloak_createdb.sql

    # echo "Create keycloak database - user: ${KC_MYSQLADMINUSER} - password: ***** - host: ${KC_MYSQLHOST}"
    # mysql -h ${KC_MYSQLHOST} -u ${KC_MYSQLADMINUSER} -p${KC_MYSQLADMINPASSWORD} -P ${KC_MYSQLPORT} < /home/appuser/data/keycloak_createdb.sql
    # rm -f /home/appuser/data/keycloak_createdb.sql 

    # Call keycloak script to add initial user
    # this will create file "/home/appuser/app/keycloak/standalone/configuration/keycloak-add-user.json" before server starts
    echo "Add admin user for \"master\" realm"
    /home/appuser/app/keycloak/bin/add-user-keycloak.sh -r master -u ${KC_ADMINUSER} -p ${KC_ADMINPWD}

    echo "Start server initially"
    /home/appuser/app/keycloak/bin/standalone.sh --server-config=../../../../data/standalone.xml &
    echo "Sleep 180 seconds"
    sleep 180
    
    if( "$KC_CREATEINITREALM" == "true" )
    then
        echo "Kill running instance" #TODO: Normally you have to do that with jboss-cli, but i had several issues to get this working
        ps -ef | grep 'java -D\[Standalone\]' | grep -v grep | awk '{print $1 }' | xargs kill -9
    fi

    echo "Sleep 10 seconds"
    sleep 10

    echo `date +%Y-%m-%d_%H:%M:%S_%z` > /home/appuser/data/firststart_finished.flg
fi

/home/appuser/app/keycloak/bin/standalone.sh --server-config=../../../../data/standalone.xml