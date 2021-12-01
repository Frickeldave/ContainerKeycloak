# Keycloak container image (fd_keycloak) for the frickeldave infrastructure

This describes the keycloak container image for the frickeldave environment.


## Source for this image

The image is based on the frickeldave image [jre11 image](https://github.com/Frickeldave/ContainerBase/tree/main/jre11/README.md).

## Quick reference

- Where to file issues: Not possible now, its just for private use. 
- Supported architecture: am64

## How to use this image

- Pull from commandline

  ``` docker pull ghcr.io/frickeldave/fd_keycloak:<tag> ```

- How to build by yourself

  ``` docker build -t ghcr.io/frickeldave/fd_keycloak --build-arg fd_buildnumber=<int> --build-arg fd_builddate=$(date -u +'%Y-%m-%dT%H:%M:%SZ') . ```

## License

View license information for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.