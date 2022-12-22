Amazon EKS is good to run Ethereum node, [Helm](https://helm.sh/) could be used to simplify the deployment work.

## Prerequisites
- Create Amazon EKS cluster with at least one node group
- Instance types used in node group should meet the requirements to run both `geth` and `lighthouse` together, *m6i.2xlarge* (has 8 vCPUs and 32GB memory) is a good point to start with for mainnet.
- Install and config `eksctl` and `kubectl` locally, follow [this document](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html) if needed
- Install Helm, https://helm.sh/docs/intro/install/

## Steps to setup Ethereum node

We'll use the default settings for demostration, if you want to use storage class other than gp2, enable ingress controller, or setup monitoring function, check [Other Considerations](#Other-Considerations) first.

If you decide to continue with gp2 storage class, make sure you've installed the *ebs-csi-controller* in your EKS cluster, if not, follow this [document](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) first.

### Clone the code

```bash
git clone https://github.com/Chen188/eth2-chart
```
### Create a dedicated k8s namespace

```bash
NAMESPACE=testnet
kubectl create namespace $NAMESPACE
```

### Create a JWT secret

JWT secret is required by [geth](https://geth.ethereum.org/docs/interface/consensus-clients) and [lighthouse](https://lighthouse-book.sigmaprime.io/run_a_node.html#step-3-run-lighthouse) to authenticate the RPC connection.

```bash
kubectl create secret generic eth2-jwt-secret --from-literal=jwt-secret=$(openssl rand -hex 32) -n $NAMESPACE
```

### Deploy Ethereum node

```bash
# for sepolia testnet
helm install my-eth2 -f charts/values-sepolia.yaml ./charts/ -n $NAMESPACE

# for mainnet
# helm install my-eth2 -f charts/values-mainnet.yaml ./charts/ -n $NAMESPACE
```

You can check the deployment status with:

```bash
kubectl get statefulset -n $NAMESPACE 

NAME                      READY   AGE
my-eth2-geth-lighthouse   1/1     99m
```

## Other Considerations

### Storage Class

There're many storage options to storing blockchain data, incluing gp2(default), gp3(current generation of general purpose EBS), FSx for OpenZFS and ephemeral instance storage. Here for demostration, we'll use default gp2 storage class , you can also follow the documents below if you want to try other options:

- gp3: https://aws.amazon.com/cn/blogs/containers/migrating-amazon-eks-clusters-from-gp2-to-gp3-ebs-volumes/

- FSx for OpenZFS: https://github.com/kubernetes-csi/csi-driver-nfs

### ALB ingress controller

You can expose geth's HTTP and Websocket endpoint through AWS ALB(Application Load Balancer).

To do so, set services[*].ingress.enabled to `true` in values-{sepolia,mainnet}.yaml file, and follow the document [Application load balancing on Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html), [Installing the AWS Load Balancer Controller add-on](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) to setup alb ingress controller.

After ALB ingress is deployed, you can test the endpoint using command below(replace the host with your ALB DNS name):

```bash
curl -X POST \
-H "Content-Type: application/json" \
--data '{"jsonrpc": "2.0", "id": 1, "method": "eth_syncing", "params": []}' \
"http://k8s-eth2-xxxx-7eaf279140-1407294883.us-east-1.elb.amazonaws.com/api/v1"
```

## Acknowledgement

This chart is developed based on [vulcanlink's repo](https://github.com/vulcanlink/charts).