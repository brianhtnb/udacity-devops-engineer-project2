#!/bin/bash

echo "Verifying Network Stack..."
NETWORK_STATUS=$(aws cloudformation describe-stacks --stack-name udagram-network --query 'Stacks[0].StackStatus' --output text)
if [ "$NETWORK_STATUS" = "CREATE_COMPLETE" ] || [ "$NETWORK_STATUS" = "UPDATE_COMPLETE" ]; then
    echo "✅ Network Stack is running successfully"
else
    echo "❌ Network Stack status: $NETWORK_STATUS"
fi

echo -e "\nVerifying Application Stack..."
APP_STATUS=$(aws cloudformation describe-stacks --stack-name udagram-app --query 'Stacks[0].StackStatus' --output text)
if [ "$APP_STATUS" = "CREATE_COMPLETE" ] || [ "$APP_STATUS" = "UPDATE_COMPLETE" ]; then
    echo "✅ Application Stack is running successfully"
else
    echo "❌ Application Stack status: $APP_STATUS"
fi

echo -e "\nChecking Load Balancer URL..."
LB_URL=$(aws cloudformation describe-stacks --stack-name udagram-app --query 'Stacks[0].Outputs[0].OutputValue' --output text)
if [ ! -z "$LB_URL" ]; then
    echo "✅ Load Balancer URL: $LB_URL"
    if [[ "$LB_URL" == http://* ]]; then
        echo "✅ Load Balancer URL correctly starts with 'http://'"
    else
        echo "❌ Load Balancer URL should start with 'http://'"
    fi
    echo "  Try opening this URL in your browser"
else
    echo "❌ Could not retrieve Load Balancer URL"
fi

echo -e "\nChecking Load Balancer Health..."
LB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(DNSName, `udagram`)].LoadBalancerArn' --output text)
if [ ! -z "$LB_ARN" ]; then
    TG_HEALTH=$(aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --load-balancer-arn $LB_ARN --query 'TargetGroups[0].TargetGroupArn' --output text) --query 'TargetHealthDescriptions[*].TargetHealth.State' --output text)
    echo "Target Health Status: $TG_HEALTH"
    if [[ $TG_HEALTH == *"healthy"* ]]; then
        echo "✅ Load Balancer has healthy targets"
    else
        echo "❌ No healthy targets found"
    fi
fi

echo -e "\nChecking Auto Scaling Group Details..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `udagram`)].AutoScalingGroupName' --output text)
if [ ! -z "$ASG_NAME" ]; then
    echo "ASG Name: $ASG_NAME"
    DESIRED=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].DesiredCapacity' --output text)
    MIN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].MinSize' --output text)
    MAX=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].MaxSize' --output text)
    echo "Min/Desired/Max: $MIN/$DESIRED/$MAX"
    
    HEALTHY_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'length(AutoScalingGroups[0].Instances[?HealthStatus==`Healthy`])' --output text)
    echo "Healthy Instances: $HEALTHY_INSTANCES"
    if [ "$HEALTHY_INSTANCES" -ge "$MIN" ]; then
        echo "✅ ASG has required minimum healthy instances"
    else
        echo "❌ ASG has fewer healthy instances than required minimum"
    fi
fi

echo -e "\nChecking S3 Bucket..."
S3_BUCKET=$(aws s3 ls | grep udagram)
if [ ! -z "$S3_BUCKET" ]; then
    echo "✅ S3 bucket found: $S3_BUCKET"
else
    echo "❌ No S3 bucket found"
fi 