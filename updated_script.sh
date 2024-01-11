ROLE_ARN=`aws ecs describe-task-definition --task-definition jenkin-streamlit --region ca-central-1 | jq .taskDefinition.executionRoleArn`
echo "ROLE_ARN= " $ROLE_ARN

#aws ecs list-task-definitions --region ca-central-1

FAMILY=`aws ecs describe-task-definition --task-definition jenkin-streamlit --region ca-central-1 | jq .taskDefinition.family`
echo "FAMILY= " $FAMILY

 NAME=`aws ecs describe-task-definition --task-definition jenkin-streamlit --region ca-central-1 | jq .taskDefinition.containerDefinitions[].name`
 echo "NAME= " $NAME

 #sed -i "s#BUILD_NUMBER#$IMAGE_TAG#g" task-definition.json
 #sed -i "s#REPOSITORY_URI#$REPOSITORY_URI#g" task-definition.json
 #sed -i "s#ROLE_ARN#$ROLE_ARN#g" task-definition.json
 #sed -i "s#FAMILY#$FAMILY#g" task-definition.json
 #sed -i "s#NAME#$NAME#g" task-definition.json


aws ecs register-task-definition --cli-input-json file://task-definition.json --region ca-central-1

 REVISION=`aws ecs describe-task-definition --task-definition jenkin-streamlit --region ca-central-1 | jq .taskDefinition.revision`
 echo "REVISION= " "${REVISION}"

 #Check wheather load balancers exists 
#BLNCR_ARN=`aws elbv2 describe-load-balancers --load-balancer-arns arn:aws:elasticloadbalancing:ca-central-1:816605281523:loadbalancer/app/secure-applications-ecs/d9db12d799161a4c --region ca-central-1 | jq.LoadBalancers[].LoadBalancerArn`
BLNCR_ARN=`aws elbv2 describe-load-balancers --names 'my-testing-balancer' --region ca-central-1 | jq .LoadBalancers[].LoadBalancerArn`
load_balancer_arn = aws elbv2 describe-load-balancers --names 'load balancer name' --query "LoadBalancers[0].LoadBalancerArn" --output text 2> /dev/null

if [ -z "$BLNCR_ARN" ]; then
    echo "🔥🔥🔥🔥🔥Balancer doesn't exists, create one and save the ARN🔥🔥🔥🔥🔥🔥"
    BLNCR_ARN=`aws elbv2 create-load-balancer \
     --scheme internal \
     --name my-testing-balancer \
     --subnets subnet-0da689ba36c2af4c9 subnet-0875527f8fb822536 \
     --region ca-central-1 \
     --security-groups sg-0c107ac1969ee10a4 | jq.LoadBalancers[0].LoadBalancerArn`
#####################################################################################################################################
     BLNCR_ARN=`aws elbv2 create-load-balancer \
              --scheme internal \
              --name my-testing-balancer \
              --subnets subnet-0a87267922cd88faa subnet-07595fe014ff3de1d \
              --region us-east-1 \
              --security-groups sg-0679ceb9cd27a45db --output text --query "LoadBalancers[0].LoadBalancerArn"`
echo $BLNCR_ARN

TARGET_GRP_ARN=`aws elbv2 create-target-group --name jenkins-target --protocol HTTP --port 80 \
             --vpc-id vpc-0e9b621472e9f1a7d --ip-address-type ipv4 --target-type ip \
             --region us-east-1 --output text --query "TargetGroups[0].TargetGroupArn"`

echo $TARGET_GRP_ARN


aws elbv2 register-targets --target-group-arn $TARGET_GRP_ARN  \
             --targets Id=10.211.29.189 \
             --region us-east-1
#####################################################################################################################################

     TARGET_GRP_ARN=`aws elbv2 create-target-group --name jenkins-target --protocol HTTP --port 80 \
     --vpc-id vpc-013a94a651e62b40b --ip-address-type ipv4 --target-type ip \
     --region ca-central-1 | jq .TargetGroups[0].TargetGroupArn`

     #Method 2
      TARGET_GRP_ARN2=aws elbv2 create-target-group --name jenkins-target --protocol HTTP --port 80 \
     --vpc-id vpc-013a94a651e62b40b --ip-address-type ipv4 --target-type ip \
     --region ca-central-1 | jq .TargetGroups[0].TargetGroupArn

     echo "TARGET_GRP_ARN2 =="$TARGET_GRP_ARN2

     #Method 3
      TARGET_GRP_ARN3=`aws elbv2 create-target-group --name jenkins-target --protocol HTTP --port 80 \
     --vpc-id vpc-013a94a651e62b40b --ip-address-type ipv4 --target-type ip \
     --region ca-central-1 --query "TargetGroups[0].TargetGroupArn"
     echo "TARGET_GRP_ARN3 =="$TARGET_GRP_ARN3

     aws elbv2 register-targets --target-group-arn "$TARGET_GRP_ARN"  \
     --targets Id=10.211.29.189 \
     --region ca-central-1


     aws elbv2 create-listener --load-balancer-arn $BLNCR_ARN \
     --protocol HTTP --port 80  \
     --default-actions Type=forward,TargetGroupArn=$TARGET_GRP_ARN \
     --region ca-central-1
     
     
else
    echo "🔥🔥🔥🔥🔥$BLNCR_ARN🔥🔥🔥🔥🔥🔥"
fi

# aws ecs update-service --cluster ECSFargateForPipeline --service jenkin-streamlit --task-definition jenkin-streamlit-service --desired-count 1 --region ca-central-1
aws ecs update-service --cluster ECSFargateForPipeline --service jenkin-streamlit-service --task-definition jenkin-streamlit --region ca-central-1 --desired-count 2

$originalString = 'Hello! you are using the "Replace" method to replace Double Quotes in PowerShell'
$newString = $originalString.Replace('"', "")
Write-Host $newString 
