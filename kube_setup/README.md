# What we want?

- Git (Gitlab?)
- CI
- CD
- Docker Registry (secure + minimal access)
- Kube Cluster (multi-master + multi AZ + no SSH / minimal interet access / all nodes on private subnets unless needed)
- RDS creation + minimal access
- Logging (secure view-only logs via ELK)
- Monitoring (Nodes CPU/RAM/Disk/Processes + Services Instances/Count/Errors)
- K8 Dashboard

## Prerequisites

- Access to AWS and AWS-CLI configured, setup and ready to go
- Download [kube-aws](https://github.com/kubernetes-incubator/kube-aws/releases) and available in PATH
- Make sure you have latest stable kubectl setup as well

## Important

- If you want to setup on existing VPC (more secure) make sure that public subnet allows DNS resolution and automatic IP association (only in public subnet).
- We want to setup controller plane in public subnet and etcd and workers in private subnet.
- Existing route tables to be reused by kube-aws must be tagged with the key KubernetesCluster and your cluster's name for the value.

## Step 1 - Used to encrypt and decrypt cluster TLS assets

```aws kms --region="eu-central-1" create-key --description="kube-aws k8-cluster-14Mar2017"```

Copy the key ARN safely

## Step 2


```./kube-aws init \
--cluster-name=k8-cluster-v4 \
--external-dns-name=k8.app-sandbox.de \
--region=eu-central-1 \
--key-name=rocky-app-sandbox-key \
--kms-key-arn="copy-key-arn-here"```


Edit cluster.yaml and fix the VPC values (workers and nodes in private subnet and controller in public subnet)

Sample with 2 Subnets is in repo.

Also, create S3 bucket e.g. k8-new-14mar17

## Step 3 ->

```openssl genrsa -out ca-key.pem 2048```

```openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"```

```./kube-aws render credentials --ca-cert-path=./ca.pem --ca-key-path=./ca-key.pem```

```./kube-aws render stack```

```./kube-aws validate --s3-uri s3://k8-cluster-18mar/v1```

```./kube-aws up --s3-uri s3://k8-cluster-18mar/v1```

```./kube-aws status```

__You may have to manually create the K8 DNS endpoint in Route53 here__

```kubectl --kubeconfig=./kubeconfig get nodes```

## Create the Docker Registry connection

```kubectl --kubeconfig=./kubeconfig create secret docker-registry b2b-registry --docker-server=b2b-registry.tedd.berlin:5000 --docker-username=kubernetes --docker-password='2Rt%v_tGf$r§99$&(uZghT6' --docker-email='rocky.jaiswal@tedd.berlin'```

## Create secrets

e.g.

```kubectl --kubeconfig=./kubeconfig apply -f ./cluster/secrets/```
```kubectl --kubeconfig=./kubeconfig get secrets```

## Create services

Same as secrets, make sure the service definition YAML has the right docker container version

## Check dashboard

The dashboard service is deployed by default in the kubernetes namespace. Check whether its running -

```kubectl --kubeconfig=./kubeconfig get pods --namespace=kube-system```

If you see a kubernetes-dashboard pod running (and you should), you are good to go.

```kubectl --kubeconfig=./kubeconfig proxy```

Go to http://localhost:8001/ui

To enable dashboard via the master server IP / URL more setup is needed. Also the dashboard can provide the logs on a per pod basis which is useful.







