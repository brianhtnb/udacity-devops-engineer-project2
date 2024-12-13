# CD12352 - Infrastructure as Code Project Solution

## Project Overview
This project deploys a high-availability web application using CloudFormation. The infrastructure includes:
- A VPC with public and private subnets across two Availability Zones
- Internet Gateway and NAT Gateways for internet connectivity
- An Application Load Balancer
- Auto Scaling Group of EC2 instances running Ubuntu 22.04
- S3 bucket for static content
- Appropriate security groups and IAM roles

## Spin up instructions
1. First, deploy the network infrastructure:
```bash
./create.sh udagram-network network.yml network-parameters.json
```

2. Wait for the network stack to complete, then deploy the application stack:
```bash
./create.sh udagram-app udagram.yml udagram-parameters.json
```

3. To update existing stacks, use:
```bash
./update.sh udagram-network network.yml network-parameters.json
./update.sh udagram-app udagram.yml udagram-parameters.json
```

## Tear down instructions
1. Delete the application stack first:
```bash
./delete.sh udagram-app
```

2. Once completed, delete the network stack:
```bash
./delete.sh udagram-network
```

## Other considerations
- Make sure to replace the KeyName parameter in udagram-parameters.json with your own SSH key name
- The default region is set to us-east-1. Modify the region in the scripts if needed
- The application uses t2.micro instances by default to stay within free tier
- The S3 bucket is configured with public read access for static content
- The load balancer DNS name will be provided in the outputs section of the application stack 