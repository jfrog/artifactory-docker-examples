# Artifactory in Kubernetes using Helm package manager
This directory has examples for Artifactory in Kubernetes deployments using the [Helm](https://helm.sh/) package manager.

## Helm
From https://helm.sh/:
```
What is Helm?

Helm helps you manage Kubernetes applications — Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.
```

Helm in [GitHub](https://github.com/kubernetes/helm)

## Deployment

### Installing helm
Follow [instructions on installing helm](https://github.com/kubernetes/helm#install)
 
#### Setup Helm to use your cluster
To initialize Helm and install Tiller, you should run
```bash
$ helm init
```

### Deploying Artifactory Pro
You can deploy the Artifactory Pro chart, which is in the [artifactory-pro](artifactory-pro) directory
```bash
$ helm install -n artifactory-pro ./artifactory-pro
```

You can package the Artifactory Pro chart and distribute it for use later
```bash
$ helm package artifactory-pro/
```

This will create a file `artifactory-pro-<version>.tgz`. You can deploy it to Kubernetes with
```bash
$ helm install -n artifactory-pro ./artifactory-pro-<version>.tgz
```

### Accessing Artifactory
**NOTE:** It might take a few minutes for Artifactory's public IP to become available.
Follow the instructions outputted by the install command to get the Artifactory IP to access it.

### Updating Artifactory
Once you have a new chart version, you can update your deployment with
```bash
$ helm upgrade artifactory-pro ./artifactory-pro
```

This will apply any configuration changes on your existing deployment.

### Customizing Database password
You can override the specified database password (set in [artifactory-pro/values.yaml](artifactory-pro/values.yaml)), by passing it as a parameter in the install command line
```bash
$ helm install -n artifactory-pro --set db_env.db_pass=12_hX34qwerQ2 ./artifactory-pro
```

You can customise other parameters in the same way, by passing them on `helm install` command line.

### Deleting Artifactory
```bash
$ helm delete --purge artifactory-pro
```

This will completely delete your Artifactory Pro deployment.  
**IMPORTANT:** This will also delete your data volumes. You will loose all data!


See more details on [using helm](https://github.com/kubernetes/helm/blob/master/docs/using_helm.md).

