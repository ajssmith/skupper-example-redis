# Skupper Redis Example

#### A Redis primary cache with replicas deployed across Kubernetes clusters using Skupper

This example is part of a [suite of examples][examples] showing the
different ways you can use [Skupper][website] to connect services
across cloud providers, data centers, and edge sites.

[website]: https://skupper.io/
[examples]: https://skupper.io/examples/index.html

#### Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Step 1: Configure separate console sessions](#step-1-configure-separate-console-sessions)
* [Step 2: Access your clusters](#step-2-access-your-clusters)
* [Step 3: Set up your namespaces](#step-3-set-up-your-namespaces)
* [Step 4: Install Skupper in your namespaces](#step-4-install-skupper-in-your-namespaces)
* [Step 5: Check the status of your namespaces](#step-5-check-the-status-of-your-namespaces)
* [Step 6: Link your namespaces](#step-6-link-your-namespaces)
* [Step 7: Deploy the Redis primary, replica and Sentinel servers](#step-7-deploy-the-redis-primary-replica-and-sentinel-servers)
* [Step 8: Expose the Redis and Sentinel servers to the Skupper network](#step-8-expose-the-redis-and-sentinel-servers-to-the-skupper-network)
* [Step 9: Observe the set of Redis server and Sentinel services exist in each site on the Skupper network](#step-9-observe-the-set-of-redis-server-and-sentinel-services-exist-in-each-site-on-the-skupper-network)
* [Step 10: Deploy the Skupper gateway to centrally access redis services](#step-10-deploy-the-skupper-gateway-to-centrally-access-redis-services)
* [Step 11: Attach to prmary redis server and verify the ROLE](#step-11-attach-to-prmary-redis-server-and-verify-the-role)
* [Step 12: Attach to the first replica servier and verify the ROLE](#step-12-attach-to-the-first-replica-servier-and-verify-the-role)
* [Step 13: Attach to the second replica servier and verify the ROLE](#step-13-attach-to-the-second-replica-servier-and-verify-the-role)
* [Step 14: Attach to first redis sentinel and verify the primary status](#step-14-attach-to-first-redis-sentinel-and-verify-the-primary-status)
* [Step 15: Attach to the second redis sentinel and verify the primary status](#step-15-attach-to-the-second-redis-sentinel-and-verify-the-primary-status)
* [Step 16: Attach to the third redis sentinel and verify the primary status](#step-16-attach-to-the-third-redis-sentinel-and-verify-the-primary-status)
* [Step 17: Deploy the wiki-getter service](#step-17-deploy-the-wikigetter-service)
* [Step 18: Test the application](#step-18-test-the-application)
* [Summary](#summary)
* [Cleaning up](#cleaning-up)
* [Next steps](#next-steps)

## Overview

This example deploys a simple highly available Redis architecture with
Sentinel across multiple Kubernetes clusters using Skupper.

In addition to the Redis server and Redis Sentinel, the example
contains one service:

* A wiki-getter service that exposes an `/api/search?query=` endpoint. 
  The server returns the result from the Redis cache if present otherwise
  it will retrieve the query via the wiki api and cache the content via
  the Redis primary server.

With Skupper, you can place the Redis primary server in one cluster and 
the replica servers in alternative clusters without requiring that
the servers be exposed to the public internet.

## Prerequisites

* The `kubectl` command-line tool, version 1.15 or later
  ([installation guide][install-kubectl])

* The `skupper` command-line tool, the latest version ([installation
  guide][install-skupper])

* Access to at least one Kubernetes cluster, from any provider you
  choose

[install-kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[install-skupper]: https://skupper.io/install/index.html

## Step 1: Configure separate console sessions

Skupper is designed for use with multiple namespaces, typically on
different clusters.  The `skupper` command uses your
[kubeconfig][kubeconfig] and current context to select the namespace
where it operates.

[kubeconfig]: https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/

Your kubeconfig is stored in a file in your home directory.  The
`skupper` and `kubectl` commands use the `KUBECONFIG` environment
variable to locate it.

A single kubeconfig supports only one active context per user.
Since you will be using multiple contexts at once in this
exercise, you need to create distinct kubeconfigs.

Start a console session for each of your namespaces.  Set the
`KUBECONFIG` environment variable to a different path in each
session.

Console for _west_:

~~~ shell
export KUBECONFIG=~/.kube/config-west
~~~

Console for _east_:

~~~ shell
export KUBECONFIG=~/.kube/config-east
~~~

Console for _north_:

~~~ shell
export KUBECONFIG=~/.kube/config-north
~~~

## Step 2: Access your clusters

The methods for accessing your clusters vary by Kubernetes provider.
Find the instructions for your chosen providers and use them to
authenticate and configure access for each console session.  See the
following links for more information:

* [Minikube](https://skupper.io/start/minikube.html)
* [Amazon Elastic Kubernetes Service (EKS)](https://skupper.io/start/eks.html)
* [Azure Kubernetes Service (AKS)](https://skupper.io/start/aks.html)
* [Google Kubernetes Engine (GKE)](https://skupper.io/start/gke.html)
* [IBM Kubernetes Service](https://skupper.io/start/ibmks.html)
* [OpenShift](https://skupper.io/start/openshift.html)
* [More providers](https://kubernetes.io/partners/#kcsp)

## Step 3: Set up your namespaces

Use `kubectl create namespace` to create the namespaces you wish to
use (or use existing namespaces).  Use `kubectl config set-context` to
set the current namespace for each session.

Console for _west_:

~~~ shell
kubectl create namespace west
kubectl config set-context --current --namespace west
~~~

Console for _east_:

~~~ shell
kubectl create namespace east
kubectl config set-context --current --namespace east
~~~

Console for _north_:

~~~ shell
kubectl create namespace north
kubectl config set-context --current --namespace north
~~~

## Step 4: Install Skupper in your namespaces

The `skupper init` command installs the Skupper router and service
controller in the current namespace.  Run the `skupper init` command
in each namespace.

[minikube-tunnel]: https://skupper.io/start/minikube.html#running-minikube-tunnel

**Note:** If you are using Minikube, [you need to start `minikube
tunnel`][minikube-tunnel] before you install Skupper.

Console for _west_:

~~~ shell
skupper init
~~~

Console for _east_:

~~~ shell
skupper init
~~~

Console for _north_:

~~~ shell
skupper init --ingress none
~~~

Here we are using `--ingress none` in one of the namespaces simply to
make local development with Minikube easier.  (It's tricky to run two
Minikube tunnels on one host.)  The `--ingress none` option is not
required if your two namespaces are on different hosts or on public
clusters.

## Step 5: Check the status of your namespaces

Use `skupper status` in each console to check that Skupper is
installed.

Console for _west_:

~~~ shell
skupper status
~~~

Console for _east_:

~~~ shell
skupper status
~~~

Console for _north_:

~~~ shell
skupper status
~~~

You should see output like this for each namespace:

~~~
Skupper is enabled for namespace "<namespace>" in interior mode. It is not connected to any other sites. It has no exposed services.
The site console url is: http://<address>:8080
The credentials for internal console-auth mode are held in secret: 'skupper-console-users'
~~~

As you move through the steps below, you can use `skupper status` at
any time to check your progress.

## Step 6: Link your namespaces

Creating a link requires use of two `skupper` commands in conjunction,
`skupper token create` and `skupper link create`.

The `skupper token create` command generates a secret token that
signifies permission to create a link.  The token also carries the
link details.  Then, in a remote namespace, The `skupper link create`
command uses the token to create a link to the namespace that
generated it.

**Note:** The link token is truly a *secret*.  Anyone who has the
token can link to your namespace.  Make sure that only those you trust
have access to it.

First, use `skupper token create` in one namespace to generate the
token.  Then, use `skupper link create` in the other to create a link.

Console for _west_:

~~~ shell
skupper token create ~/west.token --uses 2
~~~

Console for _east_:

~~~ shell
skupper token create ~/east.token
skupper link create ~/west.token
~~~

Console for _north_:

~~~ shell
skupper link create ~/west.token
skupper link create ~/east.token
skupper link status --wait 30
~~~

If your console sessions are on different machines, you may need to
use `scp` or a similar tool to transfer the token.

## Step 7: Deploy the Redis primary, replica and Sentinel servers

Use `kubectl apply` to deploy the primary server in `north` and
the replica servers in `west` and in `east`.

Console for _north_:

~~~ shell
kubectl apply -f redis-a.yaml
~~~

Console for _west_:

~~~ shell
kubectl apply -f redis-b.yaml
~~~

Console for _east_:

~~~ shell
kubectl apply -f redis-c.yaml
~~~

## Step 8: Expose the Redis and Sentinel servers to the Skupper network

We now have three namepaces linked to form a Skupper network and 
have deployed the Redis servers. Expose the primary, replica and 
Sentinel service to the Skupper network.

Console for _north_:

~~~ shell
./expose-deployments-a.sh
~~~

Sample output:

~~~
deployment redis-server exposed as redis-server-a
deployment redis-sentinel exposed as redis-sentinel-a
~~~

Console for _west_:

~~~ shell
./expose-deployments-b.sh
~~~

Sample output:

~~~
deployment redis-server exposed as redis-server-b
deployment redis-sentinel exposed as redis-sentinel-b
~~~

Console for _east_:

~~~ shell
./expose-deployments-c.sh
~~~

Sample output:

~~~
deployment redis-server exposed as redis-server-c
deployment redis-sentinel exposed as redis-sentinel-c
~~~

## Step 9: Observe the set of Redis server and Sentinel services exist in each site on the Skupper network

Console for _north_:

~~~ shell
kubectl get services
~~~

Sample output:

~~~
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
redis-sentinel-a   ClusterIP   10.101.89.83     <none>        26379/TCP   8m1s
redis-sentinel-b   ClusterIP   10.98.239.225    <none>        26379/TCP   7m52s
redis-sentinel-c   ClusterIP   10.101.197.162   <none>        26379/TCP   7m43s
redis-server-a     ClusterIP   10.99.100.75     <none>        6379/TCP    8m1s
redis-server-b     ClusterIP   10.100.253.180   <none>        6379/TCP    7m52s
redis-server-c     ClusterIP   10.109.243.96    <none>        6379/TCP    7m49s
~~~

Console for _west_:

~~~ shell
kubectl get service
~~~

Sample output:

~~~
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
redis-sentinel-a   ClusterIP   172.21.224.245   <none>        26379/TCP   9m38s
redis-sentinel-b   ClusterIP   172.21.25.14     <none>        26379/TCP   9m33s
redis-sentinel-c   ClusterIP   172.21.104.194   <none>        26379/TCP   9m24s
redis-server-a     ClusterIP   172.21.172.63    <none>        6379/TCP    9m38s
redis-server-b     ClusterIP   172.21.114.86    <none>        6379/TCP    9m35s
redis-server-c     ClusterIP   172.21.168.102   <none>        6379/TCP    9m30s
~~~

Console for _east_:

~~~ shell
kubectl get service
~~~

Sample output:

~~~
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
redis-sentinel-a   ClusterIP   172.21.63.112    <none>        26379/TCP   9m48s
redis-sentinel-b   ClusterIP   172.21.70.155    <none>        26379/TCP   9m41s
redis-sentinel-c   ClusterIP   172.21.222.171   <none>        26379/TCP   9m36s
redis-server-a     ClusterIP   172.21.211.253   <none>        6379/TCP    9m48s
redis-server-b     ClusterIP   172.21.125.230   <none>        6379/TCP    9m41s
redis-server-c     ClusterIP   172.21.255.86    <none>        6379/TCP    9m38s
~~~

## Step 10: Deploy the Skupper gateway to centrally access redis services

We have established connectivity between three namespaces and have 
made the Redis servers in each namespace available to the peer servers.
We will deploy a gateway to enable the redis-cli application to connect 
and query each of the servers and sentinels deployed. We will assign each 
server a unique port number to distinguish the redis-cli target.

Console for _east_:

~~~ shell
./redis-cli-gateway.sh
skupper gateway status
~~~

Sample output:

~~~
Gateway Definitions:
╰─ hostname-username type: service version: 1.17.1 url: amqp://127.0.0.1:5672
   ╰─ Forwards:
      ├─ redis-server-b:6379 tcp redis-server-b:6379 0.0.0.0 6380:6380
      ├─ redis-server-a:6379 tcp redis-server-a:6379 0.0.0.0 6379:6379
      ├─ redis-server-c:6379 tcp redis-server-c:6379 0.0.0.0 6381:6381
      ├─ redis-sentinel-a:26379 tcp redis-sentinel-a:26379 0.0.0.0 26379:26379
      ├─ redis-sentinel-b:26379 tcp redis-sentinel-b:26379 0.0.0.0 26380:26380
      ╰─ redis-sentinel-c:26379 tcp redis-sentinel-c:26379 0.0.0.0 26381:26381
~~~

## Step 11: Attach to prmary redis server and verify the ROLE

Console for _east_:

~~~ shell
redis-cli -p 6379
127.0.0.1:6379> ROLE
127.0.0.1:6379> exit
~~~

Sample output:

~~~
$ redis-cli -p 6379
127.0.0.1:6379>

$ 127.0.0.1:6379> ROLE
1) "master"
2) (integer) 576461
3) 1) 1) "redis-server-b"
      2) "6379"
      3) "576159"
   2) 1) "redis-server-c"
      2) "6379"
   3) "576461"
~~~

## Step 12: Attach to the first replica servier and verify the ROLE

Console for _east_:

~~~ shell
redis-cli -p 6380
127.0.0.1:6380> ROLE
127.0.0.1:6380> exit
~~~

Sample output:

~~~
1) "slave"
2) "redis-server-a"
3) (integer) 6379
4) "connected"
5) (integer) 714873
~~~

## Step 13: Attach to the second replica servier and verify the ROLE

Console for _east_:

~~~ shell
redis-cli -p 6381
127.0.0.1:6381> ROLE
127.0.0.1:6381> exit
~~~

Sample output:

~~~
1) "slave"
2) "redis-server-a"
3) (integer) 6379
4) "connected"
5) (integer) 75973
~~~

## Step 14: Attach to first redis sentinel and verify the primary status

Console for _east_:

~~~ shell
redis-cli -p 26379
127.0.0.1:26379> sentinel master redis-skupper
127.0.0.1:26379> exit
~~~

Sample output:

~~~
1) "name"
2) "redis-skupper"
3) "ip"
4) "redis-server-a"
5) "port"
6) "6379"
7) "runid"
8) "e6e9e131eb80b05c528100a37c1bcc40fddd275c"
9) "flags"
10) "master"            
...
~~~

## Step 15: Attach to the second redis sentinel and verify the primary status

Console for _east_:

~~~ shell
redis-cli -p 26380
127.0.0.1:26380> sentinel master redis-skupper
127.0.0.1:26380> exit
~~~

Sample output:

~~~
1) "name"
2) "redis-skupper"
3) "ip"
4) "redis-server-a"
5) "port"
6) "6379"
7) "runid"
8) "e6e9e131eb80b05c528100a37c1bcc40fddd275c"
9) "flags"
10) "master"
...
~~~

## Step 16: Attach to the third redis sentinel and verify the primary status

Console for _east_:

~~~ shell
redis-cli -p 26381
127.0.0.1:26381> sentinel master redis-skupper
127.0.0.1:26381> exit
~~~

Sample output:

~~~
1) "name"
2) "redis-skupper"
3) "ip"
4) "redis-server-a"
5) "port"
6) "6379"
7) "runid"
8) "e6e9e131eb80b05c528100a37c1bcc40fddd275c"
9) "flags"
10) "master"
...
~~~

## Step 17: Deploy the wiki-getter service

We will choose one of the example namespaces to create a wiki-getter
deployment and service. The client in this service will determine the 
Sentinel service to access the current Redis primary servier for 
query and cache updates.

Console for _north_:

~~~ shell
kubectl apply -f server.yaml
kubectl get service wiki-getter
~~~

Sample output:

~~~
NAME          TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
wiki-getter   LoadBalancer   10.96.10.149   10.96.10.149   5050:31495/TCP   8m29s
~~~

## Step 18: Test the application

Look up the external URL and use `curl` to send a request to query the Wikipedia API
url. Note the *X-Response-Time* header for the first query. The application will check 
the redis cache and if not found will fetch from the Wikipedia API. If the content has 
been stored, the application will provide the response directly.

Console for _north_:

~~~ shell
curl -f -I --head $(kubectl get service wiki-getter -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}:5050/api/search?query=Prague')
curl -f -I --head $(kubectl get service wiki-getter -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}:5050/api/search?query=Prague')
~~~

Sample output:

~~~
$ curl -f -I --head $(kubectl get service wiki-getter -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}:5050/api/search?query=Prague')
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 94742
ETag: W/"17216-6dDBCGBfQL9HEZ/y5HfTTPfPJ74"
X-Response-Time: 1697.655ms
...

$ curl -f -I --head $(kubectl get service wiki-getter -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}:5050/api/search?query=Prague')
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 94740
ETag: W/"17214-yf2/rssRjz6EnT8MQfVDicvviFY"
X-Response-Time: 5.566ms
...
~~~

**Note:** If the embedded `kubectl get` command fails to get the
IP address, you can find it manually by running `kubectl get
services` and looking up the external IP of the
`wiki-getter` service.

## Summary

This example locates the redis server and sentinel services in different
namespaces, on different clusters.  Ordinarily, this means that they
have no way to communicate unless they are exposed to the public
internet.

Introducing Skupper into each namespace allows us to create a virtual
application network that can connect redis services in different clusters.
Any service exposed on the application network is represented as a
local service in all of the linked namespaces.

The redis primary server is located in `north`, but the redis replica 
services in `west` and `east` can "see" it as if it were local.
Redis replicat operations take place by service name and Skupper 
forwards the requests to the namespace where the corresponding server 
is running and routes the response back appropriately.

## Cleaning up

To remove Skupper and the other resources from this exercise, use the
following commands.

Console for _north_:

~~~ shell
kubectl delete -f server.yaml
./unexpose-deployments-a.sh
kubectl delete -f redis-a.yaml
skupper delete
~~~

Console for _west_:

~~~ shell
./unexpose-deployments-b.sh
kubectl delete -f redis-b.yaml
skupper delete
~~~

Console for _east_:

~~~ shell
skupper gateway delete
./unexpose-deployments-b.sh
kubectl delete -f redis-b.yaml
skupper delete
~~~

## Next steps

Check out the other [examples][examples] on the Skupper website.
