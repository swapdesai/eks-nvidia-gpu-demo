# Set up cluster

### Download and deploy the Terraform code
```
git clone git@github.com:swapdesai/eks-nvidia-gpu-demo.git
cd terraform

export MY_CIDR="$(curl -s https://checkip.amazonaws.com)/32"
terraform apply -var "endpoint_public_access_cidrs=['${MY_CIDR}']"
```
