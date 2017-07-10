# Artifactory in Kubernetes examples
This directory has some examples for setting up Artifactory running in a Kubernetes cluster.
 
## Kubernetes
Kubernetes is an open-source system for orchestrating containerized applications. To learn more about Kubernetes, see details in the [Kubernetes](https://kubernetes.io/docs/) documentation.  
This page assumes you have prior knowledge of Kubernetes and have a working cluster to deploy in.

## Helm - a package manager for Kubernetes
The recommended way to deploy your applications to Kubernetes is using [Helm](https://helm.sh/) charts (packages).  
Artifactory Pro can be deployed and managed by the [Helm](https://helm.sh/) package manager (also [supported by Artifactory](https://github.com/JFrogDev/artifactory-user-plugins/tree/master/helm/helmRepoSupport))  
See the [helm](helm) directory for an example and usage. 

## Kubectl
The examples here are defines and deployed using the `kubectl` command line tool. See more details in the [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) documentation.  
Also see a useful [cheat sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/) with a good summary of the useful commands and usage.

In these examples Kubernetes objects are defines as Yaml files, so applying them is a simple call to `kubectl create`
  
--- 
## Persistent Storage
For persistent storage, all volumes are mounted from the cluster's hosts or as Google disks.  
**NOTE:** The examples here use a simple [PersistentVolume](https://kubernetes.io/docs/user-guide/persistent-volumes/) and 
[PersistentVolumeClaim](https://kubernetes.io/docs/user-guide/persistent-volumes/) for example purposes. This setup should **NOT** be used for production! 
You should find your best matching [storage solution](https://kubernetes.io/docs/user-guide/volumes/) and use it.
 
---
## Database Driver
The databases used in these examples are PostgreSQL and MySQL.  
For Artifactory to communicate with the database, it needs the database driver in its Tomcat's lib directory.  

Artifactory Docker image comes with the PostgreSQL driver pre-loaded.

For MySQL, you should build your own Artifactory Docker image using the `Dockerfile.mysql` in this directory that already adds the driver.  
To build the image
```bash
# For MySQL
$ docker build -t ${YOUR_DOCKER_REGISTRY}/jfrog/artifactory-pro-mysql:${VERSION} -f Dockerfile.mysql .
```
This will build an image of artifactory-pro that includes the MySQL driver in it. Make sure to push it into your registry
```bash
# For MySQL
$ docker push ${YOUR_DOCKER_REGISTRY}/jfrog/artifactory-pro-mysql:${VERSION}
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
$ kubectl create secret docker-registry docker-reg-secret --docker-server=${YOUR_DOCKER_REGISTRY} --docker-username=${USER} --docker-password=${PASSWORD} --docker-email=you@domain.com
```
#### SSL secret
Create the SSL secret that will be used by the Nginx pod  
**NOTE:** These are self signed key and certificate for demo use only!
```bash
$ kubectl create secret tls art-tls --cert=../files/nginx/ssl/demo.pem --key=../files/nginx/ssl/demo.key
```
You can replace the key and certificate with your own files
```bash
$ kubectl create secret tls art-tls --cert=${PATH_TO_CERT}/myssl.pem --key=${PATH_TO_CERT}/myssl.key
```

### Deploying the applications
Now you are ready to create the applications in Kubernetes.  
The following sequence deploys
- **PostgreSQL** or **MySQL** database
- **Artifactory** Pro or HA
- **Nginx**

Note that the resources to use are already defined in the Yaml files.

**NOTE:** If running on [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/), you will need to deploy a simpler service (NodePort). See the differences in the code examples below.

### Artifactory Pro
#### Database (using PostgreSQL)
```bash
# PostgreSQL storage, pods and service
$ kubectl create -f postgresql-storage.yml
$ kubectl create -f postgresql-service.yml
```

#### Artifactory
```bash
# Artifactory storage, pods and service
$ kubectl create -f artifactory-storage.yml
$ kubectl create -f artifactory-service.yml
```

#### Nginx
```bash
# Configuration
$ kubectl create configmap nginx-artifactory-conf --from-file=../files/nginx/conf.d/pro/artifactory.conf

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

---
### Artifactory HA
#### Database (using MySQL)
```bash
$ kubectl create -f mysql-storage.yml
$ kubectl create -f mysql-service.yml
```

#### Artifactory storage  
Prepare 3 storage volumes.
```bash
$ kubectl create -f artifactory-ha-storage.yml
```


#### Prepare the binary storage configuration
Artifactory HA can be configured with various storage solutions.  
You can see more details in [Configuring the Filestore](https://www.jfrog.com/confluence/display/RTF/Configuring+the+Filestore).  
In our examples, we have an example [binarystore.xml](../files/binarystore.xml) that configures a simple `cache-fs` template.  
- Place the file in the directory defined by the `artifactory-extra-conf` persistent volume in [artifactory-ha-storage.yml](artifactory-ha-storage.yml) (defaults to `/data/art-extra-conf/`)


#### Artifactory HA nodes
Spin up the two nodes.
```bash
$ kubectl create -f artifactory-ha-node1.yml
$ kubectl create -f artifactory-ha-node2.yml
```

#### Joining node 2 to the HA cluster
Once node 1 starts you need to prepare the configuration that node 2 will use to join the cluster. You can see more details in [Artifactory HA setup](https://www.jfrog.com/confluence/display/RTF/HA+Installation+and+Setup).  

Begin by obtaining the cluster's ip, the names of pods 1 and 2, and node the following to obtain the necessary variables for the process:
```bash
$ CLUSTER_IP="$(kubectl cluster-info | grep master | cut -d'/' -f3 | cut -d':' -f1)"
$ ART_NODE1_SERVICE_PORT=$(kubectl get services artifactory-node1 | grep artifactory-node1 | awk '{print $4}' | cut -d':' -f2 | cut -d'/' -f1)
$ ART_NODE1_POD_NAME=$(kubectl get pods | grep node1 | cut -d' ' -f1)
$ ART_NODE2_POD_NAME=$(kubectl get pods | grep node2 | cut -d' ' -f1)

# Echo the URL for node 1
$ echo http://${CLUSTER_IP}:${ART_NODE1_SERVICE_PORT}/artifactory
```

Copy URL from last echo's output and connect to node 1. Complete the initial onboarding process:
- Browse to node 1: `http://${CLUSTER_IP}:${ART_NODE1_SERVICE_PORT}/artifactory`

Then install a license and complete any additional steps you require (you can come back to this later).

Once complete, create a [bootstrap bundle](https://www.jfrog.com/confluence/display/RTF/HA+Installation+and+Setup#HAInstallationandSetup-CreatingtheBootstrapBundle) in node 1 to be copied over to node 2.  
The following will create the `bootstrap.bundle.tar.gz` under node 1's ARTIFACTORY_HOME/etc directory:
```bash
$ curl -XPOST -uadmin:password "http://${CLUSTER_IP}:${ART_NODE1_SERVICE_PORT}/artifactory/api/system/bootstrap_bundle"
```

Copy the `bootstrap.bundle.tar.gz` into node 2's ARTIFACTORY_HOME/etc:
```bash
# Copy bundle from node 1 to host
$ kubectl cp "default/${ART_NODE1_POD_NAME}:opt/jfrog/artifactory/etc/bootstrap.bundle.tar.gz" bootstrap.bundle.tar.gz

# Copy bundle from host to node 2
$ kubectl cp bootstrap.bundle.tar.gz "default/${ART_NODE2_POD_NAME}:/opt/jfrog/artifactory/etc/bootstrap.bundle.tar.gz"
```

Node 2 will detect it, continue its automatic setup, and join the cluster.


#### Nginx
```bash
# Configuration
$ kubectl create configmap nginx-artifactory-conf --from-file=../files/nginx/conf.d/ha/artifactory.conf

# Storage and deployment
$ kubectl create -f nginx-storage.yml
$ kubectl create -f nginx-deployment.yml

# Service
# If running on a standard Kubernetes cluster
$ kubectl create -f nginx-service.yml

# If running on Minikube
$ kubectl create -f nginx-service-minikube.yml
```

Once done, you should be able to see the deployed pods and services
```bash
# Get pods and their status (example output)
$ kubectl get pods
NAME                                    READY     STATUS    RESTARTS   AGE
artifactory-ha-node1-3776668781-fc3wq   1/1       Running   0          7m
artifactory-ha-node2-3265495874-cz6rj   1/1       Running   0          7m
mysql-k8s-deployment-4196928137-3s6tn   1/1       Running   0          7m
nginx-k8s-deployment-1544469967-bt5m1   1/1       Running   0          1m

# Get services (example output)
# On a standard Kubernetes cluster
$ kubectl get services
NAME                CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory-node1   10.0.0.159   <nodes>       8081:30690/TCP               8m
artifactory-node2   10.0.0.176   <nodes>       8081:30981/TCP               7m
kubernetes          10.0.0.1     <none>        443/TCP                      3d
mysql-k8s-service   10.0.0.17    <none>        3306/TCP                     8m
nginx-k8s-service   10.0.0.75    59.156.13.6   80:32094/TCP,443:30063/TCP   2m

# On Minikube
$ kubectl get services
NAME                CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory-node1   10.0.0.159   <nodes>       8081:30690/TCP               8m
artifactory-node2   10.0.0.176   <nodes>       8081:30981/TCP               7m
kubernetes          10.0.0.1     <none>        443/TCP                      3d
mysql-k8s-service   10.0.0.17    <none>        3306/TCP                     8m
nginx-k8s-service   10.0.0.75    <nodes>       80:30002/TCP,443:32600/TCP   2m

```

### Accessing your Artifactory
Depending on your deployment type, you can now access Artifactory through its Nginx.

#### Standard Kubernetes
You can see the Nginx is exposed with a public IP of `59.156.13.6` on ports 80 and 443.  
Now just point your browser to **http://59.156.13.6/artifactory/** or **https://59.156.13.6/artifactory/**  

#### Minikube
You need to use the Minikube's IP with the assigned port like `192.168.99.100`.  
You can get the Minikube IP with the command `minikube ip`.  
The assigned ports can be seen in the output of `kubectl get services` as seen above.  
Now point your browser to **http://192.168.99.100:30002/artifactory/** or **https://192.168.99.100:32600/artifactory/**  
**NOTE**: When using `https`, you might need to confirm trusting the certificate and that will redirect you back to 
https://192.168.99.100/artifactory, resulting in an error. Just put the port 32600 again in the URL, refresh your page, 
and Artifactory should now load properly.
