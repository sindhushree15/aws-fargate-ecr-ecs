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
# aws ecs update-service --cluster ECSFargateForPipeline --service jenkin-streamlit --task-definition jenkin-streamlit-service --desired-count 1 --region ca-central-1
aws ecs update-service --cluster ECSFargateForPipeline --service jenkin-streamlit-service --task-definition jenkin-streamlit --region ca-central-1 --desired-count 2

