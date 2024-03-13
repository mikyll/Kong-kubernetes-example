<div align="center">

# Kong Kubernetes Example

This directory contains some examples for Kong Kubernetes installation (Kong Ingress Controller).

</div>

## Prerequisites

- Kubernetes Command Line Tools ([kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl));
- Helm CLI ([helm](https://helm.sh/docs/intro/install/));
- Linux shell, on Windows  you can obtain through many tools, such as [Git Bash](https://git-scm.com/downloads) and WSL.

### Local Installation

- [docker](https://www.docker.com/) (Docker Desktop for Windows users);
- [minikube](https://minikube.sigs.k8s.io/docs/start/);

NB: Minikube is a tool capable of running a Kubernetes cluster locally. It supports different drivers (including Docker, in which case Kubernetes will run as a Docker container).

#### Minikube

1. Start a minikube cluster:

    ```bash
    minikube start --driver="docker"
    ```

    Running this command will automatically set the Kubernetes config file to point to the local Kubernetes cluster.

2. Open a tunnel connection to LoadBalancer services (needed to be able to contact Kong proxy on localhost):

    ```bash
    minikube tunnel
    ```

    This command will keep running, so it's better to leave it in another terminal.

## Test Resources

[echo-test.yaml](./resources/echo-test.yaml) describes a set of resources that can be deployed to test the gateway features.

This manifest contains:

- a *Deployment* that uses [kong/go-echo](https://hub.docker.com/r/kong/go-echo) Docker image;
- a *Service* that points to that Deployment;
- a set of *HTTPRoutes*, which maps an API endpoint on the gateway to the echo deployment and a specific plugin;
- a set of *KongPlugins* to test different functionality;
- a set of *KongConsumers* and *Secrets* to use the corresponding plugins;

### API Endpoints

If deployed on a minikube cluster (with minikube tunnel), it will be accessible through `http://localhost:80`. The test resources expose the following API endpoints:

- `/echo`, simple route that forwards requests directly to the backend, with no further processing/operations;
- `/echo-ratelimit`, uses the rate limiting plugin, capped with 2 requests per minute;
- `/echo-keyauth`, uses the key authentication plugin, allowing only requests that contains a valid API key (header `apikey:alex_api_key`) to be forwarded to the backend;
- `/echo-basicauth`, uses the basic authentication plugin, allowing only requests that contains a valid basic authorization (basic authorization header with `joe:password` encoded in base64) to be forwarded to the backend;
- `/echo-jwtauth`, uses the JWT plugin, allowing only requests that contains a valid JWT token (bearer authorization header with [`JWT_ADMIN.txt`](./resources/JWTs/JWT_ADMIN.txt) or [`JWT_USER.txt`](./resources/JWTs/JWT_USER.txt.txt)) to be forwarded to the backend;
- `/echo-acl/admin`, uses the ACL plugin combined with the JWT plugin, to implement authentication + authorization. This endpoint allows forwarding to the backend service only for requests that contains a JWT corresponding to the group "admin" (such as [`JWT_ADMIN.txt`](./resources/JWTs/JWT_ADMIN.txt));
- `/echo-acl/anyone`, uses the ACL plugin combined with the JWT plugin, to implement authentication + authorization. This endpoint allows forwarding to the backend service only for requests that contains a JWT corresponding to the group "admin" and "user" (such as [`JWT_ADMIN.txt`](./resources/JWTs/JWT_ADMIN.txt) and [`JWT_USER.txt`](./resources/JWTs/JWT_USER.txt.txt));
- `/echo-loadtest`, uses a custom plugin to perform CPU intensive operation. It accepts the following query parameters:
  - `load_test`, a boolean that specifies if the plugin must perform a loop;
  - `load_loops`, an integer indicating the number of loops to be performed (CPU intensive operation, to be run on Kong gateway before the request forwarding);
  - `load_log`, a boolean that specifies if the plugin must print information in Kong gateway logs (see [Kong Log Watcher](#kong-log-watcher) below);
- `/echo-jwtchecker`, uses a custom plugin to check if the header contains a JWT. If it does, the response will have status code `200`, if it has an authorization header, but not containing a JWT, it will return `403`, in any other case it will return `401`. The body of the response will contain the response of the backend service, only if a JWT token was found. The plugin has the following configuration parameters:
  - `verbose` (default true), if set to true will add a message to the body (if a JWT was found it will print also the payload).

### Custom Plugins

#### Load Test

Directory: [loadtest/](./resources/custom_plugins/loadtest/)

#### JWT Checker

Directory: [jwtchecker/](./resources/custom_plugins/jwtchecker/)

#### How To Use Custom Plugins

Custom plugins are Lua scripts that can be injected in Kong gateway. In order to add them to Kong environment, we can create a config map:

```bash
kubectl create configmap "my-customplugin-configmap" --from-file="plugin_dir/" -n "kong"
```

And add a entry in Kong [values.yaml](./values/ingress-values.yaml) file:

```yaml
gateway:
  # [...]

  plugins:
    configMaps:
    - name: "my-customplugin-configmap"
      # This will be referenced by KongPlugin "plugin" field
      pluginName: mycustom
```

## Utility Scripts

The following sections describe some utility Bash scripts.

### Kong Installation

Script [kong_install_gd.sh](./kong_install_gd.sh) installs Kong in [Gateway Discovery](https://docs.konghq.com/kubernetes-ingress-controller/3.1.x/production/deployment-topologies/gateway-discovery/) mode, with no database. This is the most common deployment mode, and consists of 2 separate Kong deployments (Kubernetes Deployment instances):

- **Kong Controller** (Control Plane) is responsible for maintaining the Kong configuration and synching the gateway instances;
- **Kong Gateway** (Data Plane) is the actual proxy that receives requests and forwards them to backend services;

This deployment mode allows for *independent scaling* of the two deployments, contrary to the more traditional "sidecar" where both the controller and the gateway are installed in a single deployment instance (and will run in the same pod).

### Kong Uninstallation

Script [kong_uninstall.sh](./kong_uninstall.sh) uninstall any Kong installation using the Helm release name.

### Kong Echo Updater

Script [kong_apply_echo.sh](./kong_apply_echo.sh) applies the configuration of the "echo" resources, located in [./resources/echo-test.yaml](./resources/echo-test.yaml).

### Kong Log Watcher

Script [kong_watch_logs_all.sh](./kong_watch_logs_all.sh) opens two terminal windows showing real-time logs for the controller and the gateway deployments.

### Kong Manager

Script [kong_open_kong_manager.sh](./kong_open_kong_manager.sh) runs kubectl port-forward on admin and manager HTTP services, and opens a browser window at the Kong Manager URL.

### ConfigMap Creation

Script [create_configmaps.sh](./resources/custom_plugins/create_configmaps.sh) loops over the directories in [resources/custom_plugins/](./resources/custom_plugins/) and creates a YAML manifest for each custom plugin directory not starting with an underscore character (`_`).

## Extra

### Database

### Autoscaling

## References

- [Kong](https://konghq.com/)
- [Kong Ingress Controller docs](https://docs.konghq.com/kubernetes-ingress-controller/latest/)
