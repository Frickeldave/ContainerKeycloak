# Keycloak container image (fd_keycloak) for the frickeldave infrastructure

This describes the keycloak container image for the frickeldave environment. This is a simple single-host configuration (standalone) which is mostly dynamic configurable with variables. 

## References

The following references can be used to configure keycloak: 

- The keycloak [configuration docs](https://www.keycloak.org/docs/latest/server_installation)
- A How-To for configuring a cluster node written by [shami](https://shami.blog/2021/07/howto-build-a-keycloak/ubuntu/mariadb-cluster-without-multicast-udp)
- The keycloak [container configuration](https://github.com/keycloak/keycloak-containers/tree/main/server)
- Configuring mariadb datasource in [wildfly] (https://www.ivojonker.nl/?p=741)

## Source for this image

The image is based on the frickeldave image [jre11 image](https://github.com/Frickeldave/ContainerBase/tree/main/jre11/README.md).

## Quick reference

- Where to file issues: Not possible now, its just for private use. 
- Supported architecture: amd64

## How to use this image

- Pull from commandline

  ``` docker pull ghcr.io/frickeldave/fd_keycloak:<tag> ```

- How to build by yourself

  ``` docker build -t ghcr.io/frickeldave/fd_keycloak --build-arg fd_buildnumber=<int> --build-arg fd_builddate=$(date -u +'%Y-%m-%dT%H:%M:%SZ') . ```

- How to run mariadb

  Please use the [docker-compose.yaml](./docker-compose.yaml) file in this repository as a reference implementation. 

  - **KC_AJPINTPORT**  
    The port for the AJP interface
  - **KC_HTTPINTPORT**  
    The http port
  - **KC_HTTPSINTPORT**  
    The SSL port
  - **KC_MGNTHTTPINTPORT**  
    The port for the management interface
  - **KC_MGNTHTTPSINTPORT**  
    The port for the SSL management interface
  - **KC_MDBHOST**  
    The name of the database server
  - **KC_MDBPORT**  
    The port where the database server is listening to
  - **KC_MDBDB**  
    The name of the database
  - **KC_MDBUSERNAME**  
    The user with write access to the database
  - **KC_MDBPASSWORD**  
    The password of the database access user
  - **KC_MDBHEALTHUSER**  
    The user which should be used to check the health of the database during initial setup 
  - **KC_MDBHEALTHPWD**  
    The password for the healthuser
  - **KC_BINDADDRESS**  
    The IP address where you want to should bind keycloak to. Can be 0.0.0.0 as well, but it is recommended to assign a fixed IP and bind that (-> docker compose)
  - **KC_CERTPWD**  
    The password for the java keystore which will be created during setup
  - **KC_ADMINUSER**  
    The name of the initial admin user
  - **KC_ADMINPWD**  
    The password of the initial admin user
  - **KC_CREATEINITREALM**  
    Can be "true" or "false" and controls if the INITREALM will be created 
  - **KC_INITREALM**  
    The name of the inital real
  - **KC_INITUSERMAILDOMAIN**  
    ???
  - **KC_INITUSERPASSWORD**  
    ???
  - **Certificate management CRT_VALIDITY / CRT_C / CRT_S / CRT_L / CRT_OU / CRT_CN**  
    The configuration for the alpine image is described in the base image [README.md](https://github.com/Frickeldave/ContainerBase/blob/main/alpine/README.md) 

## What it does and what not
This image is a keycloak implementation for the wildfly based server system. It will automatically create self-signed certificated and inject them into the server. It will use a mariadb as database backend. The database system cannot be changed, but all scripts are designed to do that later.

## Useful hints
Some comments for the container image that are probably useful

### Wait for mariadb database

When starting keycloak the very first time, it will wait automatically for the mariadb instance. This is done directly in the start.sh script, so we have dependency to some "outside" technology like healthchecks. 
You can see that behavior, when starting keycloak with the docker-compose file. The script will wait for the database initialization and check the database connection every 5 seconds. When the database is there, it will wait additional 15 seconds, because in some situations mariadb will restart again. 

```
containerkeycloak-mariadb-1   | Initialize MariadB data, when it was never done before
containerkeycloak-mariadb-1   | Installing MariaDB/MySQL system tables in '/home/appuser/data/mariadb/db' ...
containerkeycloak-keycloak-1  | Running start.sh script of keycloak
containerkeycloak-keycloak-1  | First start, set initialstart variable to 1
containerkeycloak-keycloak-1  | Connect to mariadb with user healthstatus (https://github.com/Frickeldave/ContainerBase/tree/main/mariadb)
containerkeycloak-keycloak-1  | ERROR 2002 (HY000): Can't connect to server on 'mariadb' (115)
containerkeycloak-keycloak-1  | MariaDB server (mariadb) is not available. Wait 5s and try again ...
containerkeycloak-keycloak-1  | ERROR 2002 (HY000): Can't connect to server on 'mariadb' (115)
containerkeycloak-keycloak-1  | ...
containerkeycloak-keycloak-1  | ...
containerkeycloak-keycloak-1  | ...
containerkeycloak-keycloak-1  | MariaDB server (mariadb) is not available. Wait 5s and try again ...
containerkeycloak-mariadb-1   | OK
containerkeycloak-mariadb-1   |
containerkeycloak-mariadb-1   | To start mysqld at boot time you have to copy
containerkeycloak-mariadb-1   | support-files/mysql.server to the right place for your system
containerkeycloak-mariadb-1   |
containerkeycloak-mariadb-1   |
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | Consider joining MariaDB's strong and vibrant community:
containerkeycloak-mariadb-1   | https://mariadb.org/get-involved/
containerkeycloak-mariadb-1   |
containerkeycloak-mariadb-1   | Wait 5s
containerkeycloak-keycloak-1  | ERROR 2002 (HY000): Can't connect to server on 'mariadb' (115)
containerkeycloak-keycloak-1  | MariaDB server (mariadb) is not available. Wait 5s and try again ...
containerkeycloak-mariadb-1   | Start mariaDB one time to inject initial changes
containerkeycloak-mariadb-1   | to be sure that the server is up and running, lets wait a bit
containerkeycloak-mariadb-1   | Wait 5s
containerkeycloak-mariadb-1   | 2021-12-03 18:53:14 0 [Note] mysqld (server 10.6.4-MariaDB-debug) starting as process 89 ...
containerkeycloak-keycloak-1  | ERROR 1130 (HY000): Host 'containerkeycloak-keycloak-1.containerkeycloak_kcnet' is not allowed to connect to this MariaDB server
containerkeycloak-keycloak-1  | MariaDB server (mariadb) is not available. Wait 5s and try again ...
containerkeycloak-mariadb-1   | patch setup.sql based on given environment variables
containerkeycloak-mariadb-1   | inject changes
containerkeycloak-mariadb-1   | --------------
containerkeycloak-mariadb-1   | FLUSH PRIVILEGES
containerkeycloak-mariadb-1   | --------------
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | ...
containerkeycloak-mariadb-1   | --------------
containerkeycloak-mariadb-1   | GRANT ALL PRIVILEGES ON *.* TO 'adminkeycloakdb'@'%' WITH GRANT OPTION
containerkeycloak-mariadb-1   | --------------
containerkeycloak-mariadb-1   |
containerkeycloak-mariadb-1   | let us wait a few seconds more to be sure that everything is applied
containerkeycloak-keycloak-1  | Database
containerkeycloak-keycloak-1  | information_schema
containerkeycloak-keycloak-1  | Wait additional time, because the MariaDB server will be restarted after creating the healthstatus user
containerkeycloak-mariadb-1   | kill MariaDB
containerkeycloak-mariadb-1   | Start MariaDB process finally
containerkeycloak-mariadb-1   | 2021-12-03 18:53:27 0 [Note] mysqld (server 10.6.4-MariaDB-debug) starting as process 143 ...
containerkeycloak-keycloak-1  | Check if its initial start
containerkeycloak-keycloak-1  | initialstart variable is set to 1
containerkeycloak-keycloak-1  | First start. Create initial certificates with an alternative name
containerkeycloak-keycloak-1  | Create certificates with following values
containerkeycloak-keycloak-1  | ... Validity:      3650
```

### Database initializtion took very long time
It can take up to 15 minutes to initalize the database. Please be patient. For this reason the timout values are increased (from 5 to 15 minutes).

### Logging
The logging of keycloak is not very focused. It will output nearly everything. When you have an issues it will also output the stacktraces, so logfiles are nearly unreadable. It's highly recommended to use a console with a large cache to have all information avalaible.

## License

View license information for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.