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

#Check load balancers exists Method 1
aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:us-west-2:xxxxxxxx:loadbalancer/app/production-lambda-alb/yyyyyyyyyyyy

#Method 2
load_balancer_arn = aws elbv2 describe-load-balancers --names 'load balancer name' --query "LoadBalancers[0].LoadBalancerArn" --output text 2> /dev/null
if [-z "$load_balancer_arn"]; then IsExists=0 else IsExists=1

#https://docs.aws.amazon.com/cli/latest/reference/elbv2/create-load-balancer.html#examples
#https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html
aws elbv2 create-load-balancer \
    --name my-load-balancer \
    --subnets subnet-b7d581c0 subnet-8360a9e7
  
aws ecs update-service --cluster "${CLUSTER_NAME}" --service "${SERVICE_NAME}" --task-definition "${TASK_DEFINITION_NAME}":"${REVISION}" --desired-count "${DESIRED_COUNT}"
