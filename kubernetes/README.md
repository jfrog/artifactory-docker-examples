# Artifactory in Kubernetes examples
This directory has some examples for setting up Artifactory running in a Kubernetes cluster.
 
## Kubernetes
Kubernetes is an open-source system for orchestrating containerized applications. To learn more about Kubernetes, see details in the [Kubernetes](https://kubernetes.io/docs/) documentation.  
This page assumes you have prior knowledge of Kubernetes and have a working cluster to deploy in.

## Kubectl
The examples are defines and deployed using the `kubectl` command line tool. See more details in the [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) documentation.  
Also see a useful [cheat sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/) with a good summary of the useful commands and usage.

In these examples Kubernetes objects are defines as Yaml files, so applying them is very easy
```bash
$ kubectl create -f artifactory.yml
``` 
This will create the object(s) defined in artifactory.yml in your Kubernetes cluster.
  
--- 
## Persistent Storage
For persistent storage, all volumes are mounted from the cluster's hosts.  
**NOTE:** The examples here use a simple [PersistentVolume](https://kubernetes.io/docs/user-guide/persistent-volumes/) and 
[PersistentVolumeClaim](https://kubernetes.io/docs/user-guide/persistent-volumes/) for example purposes. This setup should **NOT** be used for production! 
You should find your best matching [storage solution](https://kubernetes.io/docs/user-guide/volumes/) and use it.
 
---
## Database Driver
The database used in these examples is PostgreSQL. For Artifactory to communicate with the database, it needs the
database driver in its Tomcat's lib directory.  

For this, you can build your own Artifactory Docker image using the [Dockerfile](Dockerfile) in this directory that already adds the driver.  
To build the image
```bash
$ docker build -t <your-docker-reg>/jfrog/artifactory-pro-postgresql:latest -f Dockerfile .
```
This will build an image of artifactory-pro that includes the PostgreSQL driver in it. Make sure to push it into your registry
```bash
$ docker push <your-docker-reg>/jfrog/artifactory-pro-postgresql:latest
```
And edit the artifactory-service.yml to use this image.

#### Using Different Databases
Artifactory can run with other databases. For more details on supported databases and how to set them up for use with Artifactory, please refer to [Changing the Database](https://www.jfrog.com/confluence/display/RTF/Changing+the+Database) in the JFrog Artifactory Use Guide.

---
## Deploying your Artifactory to Kubernetes
The following describes the steps to do the actual deployment of the Artifactory and its services to Kubernetes.


### Preparing Resources
Need to create some resources that will be used by Nginx as SSL and Artifactory reverse proxy configuration

#### Docker registry secret
In case you built your own Artifactory image and pushed it to your private registry as suggested above, you might need to define a docker-registry secret to be used by Kubernetes to pull images
```bash
$ kubectl create secret docker-registry docker-reg-secret --docker-server=<your-docker-reg> --docker-username=${USER} --docker-password=${PASSWORD} --docker-email=you@domain.com
```

#### SSL secret
Create the SSL secret that will be used by Nginx's container  
**NOTE:** These are self signed key and certificate for demo use only!
```bash
$ kubectl create secret tls art-tls --cert=../files/nginx/ssl/demo.pem --key=../files/nginx/ssl/demo.key
```
You can replace the key and certificate with your own files
```bash
$ kubectl create secret tls art-tls --cert=<path_to>/myssl.pem --key=<path_to>/myssl.key
```

#### Artifactory Nginx configuration
Create a Kubernetes ConfigMap from artifactory.conf
```bash
$ kubectl create configmap nginx-art-pro --from-file=../files/nginx/conf.d/pro/artifactory.conf
```

### Deploying the applications
Now you are ready to create the applications in Kubernetes.  
The following sequence deploys **PostgreSQL**, **Artifactory** and **Nginx**. Note that the resources to use are already defined in the Yaml files.

**NOTE:** If running on [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/), you will need to deploy a simpler service (NodePort). See the differences in the code examples below.

```bash
# PostgreSQL storage, pods and service
$ kubectl create -f postgresql-storage.yml
$ kubectl create -f postgresql-service.yml

# Artifactory storage, pods and service
$ kubectl create -f artifactory-storage.yml
$ kubectl create -f artifactory-service.yml

# Nginx storage and deployment
$ kubectl create -f nginx-storage.yml
$ kubectl create -f nginx-deployment.yml

# Nginx service
# If running on a standard Kubernetes cluster
$ kubectl create -f nginx-service.yml

# If running on Minikube
$ kubectl create -f nginx-service-minikube.yml

```

Once done, you should be able to see the deployed pods and services
```bash
# Get pods and their status
$ kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
artifactory-k8s-deployment-1732455857-7w6gw   1/1       Running   0          31m
nginx-k8s-deployment-3171003233-q8gb2         1/1       Running   0          25m
postgresql-k8s-deployment-1240329637-25325    1/1       Running   0          33m

# Get services
# On a standard Kubernetes cluster
$ kubectl get services
NAME                     CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
artifactory              10.0.160.189   <nodes>       8081/TCP         31m
kubernetes               10.0.0.1       <none>        443/TCP          3d
nginx-k8s-service        10.0.26.194    59.156.13.6   80/TCP,443/TCP   25m
postgresql-k8s-service   10.0.172.76    <none>        5432/TCP         33m

# On Minikube
$ kubectl get services
NAME                     CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory              10.0.0.210   <nodes>       8081:32355/TCP               57m
kubernetes               10.0.0.1     <none>        443/TCP                      1h
nginx-k8s-service        10.0.0.113   <nodes>       80:30002/TCP,443:32600/TCP   48m
postgresql-k8s-service   10.0.0.165   <none>        5432/TCP                     1h

```

#### Accessing your Artifactory

**Standard Kubernetes**: You can see the Nginx is exposed with a public IP of `59.156.13.6` on ports 80 and 443.  
Now just point your browser to **http://59.156.13.6/artifactory/** or **https://59.156.13.6/artifactory/**  


**Minikube**: You need to use the Minikube's IP with the assigned port like `192.168.99.100`.  
The assigned ports can be seen in the output of `kubectl get services` as seen above.  
Now point your browser to **http://192.168.99.100:30002/artifactory/** or **https://192.168.99.100:32600/artifactory/**  
**NOTE**: When using `https`, you might need to confirm trusting the certificate and that will redirect you back to 
https://192.168.99.100/artifactory, resulting in an error. Just put the port 32600 again in the URL, refresh your page, 
and Artifactory should now load properly.

