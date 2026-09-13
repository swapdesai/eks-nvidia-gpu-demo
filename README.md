# Set up cluster

### Download and deploy the Terraform code
```bash
git clone git@github.com:swapdesai/eks-nvidia-gpu-demo.git
cd terraform

export MY_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
terraform apply -var "endpoint_public_access_cidrs=['${MY_CIDR}']" -var "my_cidr='${MY_CIDR}'"
```

### Create dynamic GPU NodePool
```bash
terraform apply -var "endpoint_public_access_cidrs=['${MY_CIDR}']" -var "my_cidr='${MY_CIDR}'" -var "nodepools={'spot-ondemand'={}}"
```

#### Test your GPU NodePool setup
```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nvidia-smi
  labels:
    guide: ai-eks-docs
spec:
  restartPolicy: OnFailure
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
  containers:
    - name: nvidia-smi
      image: public.ecr.aws/amazonlinux/amazonlinux:2023-minimal
      command: ["nvidia-smi"]
      resources:
        limits:
          nvidia.com/gpu: 1
EOF
```

