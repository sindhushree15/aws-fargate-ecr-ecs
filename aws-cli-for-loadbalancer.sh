aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ca-central-1:816605281523:loadbalancer/app/secure-applications-ecs/d9db12d799161a4c --region ca-central-1


aws elbv2 create-load-balancer \
    --scheme internal \
    --name my-testing-balancer \
    --subnets subnet-0da689ba36c2af4c9 subnet-0875527f8fb822536 \
    --region ca-central-1 \
    --security-groups sg-0c107ac1969ee10a4

#Changes by sindhu, added --target-type
aws elbv2 create-target-group --name my-targets --protocol HTTP --port 80 \
--vpc-id vpc-0598c7d356EXAMPLE --ip-address-type ipv4 --target-type ip

SERVICE_NAME="jenkin-streamlit-service"

TASK_ARN=$(aws ecs list-tasks --cluster ECSFargateForPipeline --service-name "$SERVICE_NAME" --region ca-central-1 --query 'taskArns[0]' --output text)
echo $TASK_ARN
TASK_DETAILS=$(aws ecs describe-tasks --cluster ECSFargateForPipeline --task "${TASK_ARN}" --region ca-central-1 --query 'tasks[0].attachments[0].details[0].privateIPv4Address')
echo $TASK_DETAILS

aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:ca-central-1:816605281523:targetgroup/test-target/d3122a15152d818f  \
    --targets Id=10.211.28.210 \
    --region ca-central-1

#Create listeners to forward request to ECS
aws elbv2 create-listener --load-balancer-arn loadbalancer-arn \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:ca-central-1:816605281523:targetgroup/test-target/d3122a15152d818f

#Verify the health of the registered tragets
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:ca-central-1:816605281523:targetgroup/test-target/d3122a15152d818f



aws ecs list-container-instances --cluster ECSFargateForPipeline  containerInstanceArns arn:aws:ecs:ca-central-1:816605281523:service/ECSFargateForPipeline/jenkin-streamlit-service --region ca-central-1

aws ecs update-service --cluster ECSFargateForPipeline --load-balancers "arn:aws:elasticloadbalancing:ca-central-1:816605281523:loadbalancer/app/secure-applications-ecs/d9db12d799161a4c" --service jenkin-streamlit-service --task-definition jenkin-streamlit --desired-count 2



aws ecs update-service --cluster ECSFargateForPipeline --service jenkin-streamlit-service --task-definition jenkin-streamlit --region ca-central-1 --desired-count 2

--load-balancers
