# Configure Nginx SSL
This page explains how to override the default, built it, self signed SSL certificates that come with the 
Nginx for Artifactory Docker image.

## Overriding built in SSL certificate
When the Nginx container start, the host's `/data/nginx` is mounted to the container's `/var/opt/jfrog/nginx`.  
The `/var/opt/jfrog/nginx/ssl` directory has has the pre-loaded SSL certificate files `example.pem` and `example.key`.  
These keys were generated at the time the Docker image was built by the following command:  
```bash
openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key \
        -out /etc/pki/tls/certs/example.pem -days 356 \
        -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=localhost"
```
If you wish to use your own key and certificate, you need to place your own `<file>.key` and `<file>.pem` in the host's 
`/data/nginx/ssl` directory. The Nginx container will detect and use them instead of the pre-loaded example.
