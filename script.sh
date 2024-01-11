ROLE_ARN=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.executionRoleArn`
echo "ROLE_ARN= " $ROLE_ARN

FAMILY=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.family`
echo "FAMILY= " $FAMILY

NAME=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.containerDefinitions[].name`
echo "NAME= " $NAME

sed -i "s#BUILD_NUMBER#$IMAGE_TAG#g" task-definition.json
sed -i "s#REPOSITORY_URI#$REPOSITORY_URI#g" task-definition.json
sed -i "s#ROLE_ARN#$ROLE_ARN#g" task-definition.json
sed -i "s#FAMILY#$FAMILY#g" task-definition.json
sed -i "s#NAME#$NAME#g" task-definition.json


aws ecs register-task-definition --cli-input-json file://task-definition.json --region="${AWS_DEFAULT_REGION}"

REVISION=`aws ecs describe-task-definition --task-definition "${TASK_DEFINITION_NAME}" --region "${AWS_DEFAULT_REGION}" | jq .taskDefinition.revision`
echo "REVISION= " "${REVISION}"

#https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html
#Check load balancers exists Method 1
BLNCR_ARN=`aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ca-central-1:816605281523:loadbalancer/app/secure-applications-ecs/d9db12d799161a4c --region ca-central-1 | jq.LoadBalancers[].LoadBalancerArn`

if [ -z "$BLNCR_ARN" ]; then
    echo "🔥🔥🔥🔥🔥Balancer doesn't exists, create one and save the ARN🔥🔥🔥🔥🔥🔥"
    BLNCR_ARN=`aws elbv2 create-load-balancer \
     --scheme internal \
     --name my-testing-balancer \
     --subnets subnet-0da689ba36c2af4c9 subnet-0875527f8fb822536 \
     --region ca-central-1 \
     --security-groups sg-0c107ac1969ee10a4 | jq.LoadBalancers[].LoadBalancerArn`
else
    echo "🔥🔥🔥🔥🔥$BLNCR_ARN🔥🔥🔥🔥🔥🔥"
fi


#Method 2
load_balancer_arn = aws elbv2 describe-load-balancers --names 'load balancer name' --query "LoadBalancers[0].LoadBalancerArn" --output text 2> /dev/null
if [-z "$load_balancer_arn"]; then IsExists=0 else IsExists=1

#https://docs.aws.amazon.com/cli/latest/reference/elbv2/create-load-balancer.html#examples
#https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html
#https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html
#https://docs.aws.amazon.com/cli/latest/reference/ecs/update-service.html#examples
aws elbv2 create-load-balancer \
    --name my-load-balancer \
    --subnets subnet-b7d581c0 subnet-8360a9e7
#Create targets and register 
aws elbv2 create-target-group --name my-targets --protocol HTTP --port 80 \
--vpc-id vpc-0598c7d356EXAMPLE --ip-address-type [ipv4 or ipv6] --target-type ip

#Register targets
#https://fossies.org/linux/aws-cli/awscli/examples/elbv2/register-targets.rst
#https://docs.aws.amazon.com/cli/latest/reference/elbv2/register-targets.html
aws elbv2 register-targets --target-group-arn targetgroup-arn  \
--targets Id=i-0abcdef1234567890 Id=i-1234567890abcdef0

#Create listeners to forward request to ECS
aws elbv2 create-listener --load-balancer-arn loadbalancer-arn \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=targetgroup-arn

#Verify the health of the registered tragets
aws elbv2 describe-target-health --target-group-arn targetgroup-arn


aws ecs update-service --cluster "${CLUSTER_NAME}" --load-balancers "laodbalancer arn" --service "${SERVICE_NAME}" --task-definition "${TASK_DEFINITION_NAME}":"${REVISION}" --desired-count "${DESIRED_COUNT}"
aws ecs update-service --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" --task-definition "${TASK_DEFINITION_NAME}":"${REVISION}" --desired-count "${DESIRED_COUNT}"
