deployment_bucket=cf-templates-1eelshurnh905-eu-central-1

checksum="$(sha256sum -- lambda.py)"
checksum="${checksum%% *}"

zip -9 lambda.zip -- lambda.py

deployment_object_key="lambda/git-lfs/${checksum}.zip"

aws s3api put-object --bucket "${deployment_bucket}" --key "${deployment_object_key}" --body lambda.zip

aws cloudformation update-stack --stack-name git-lfs-music-function --template-body file://cft/function.yaml --parameters "ParameterKey=DeploymentBucket,ParameterValue=${deployment_bucket}" "ParameterKey=DeploymentObjectKey,ParameterValue=${deployment_object_key}" ParameterKey=DeploymentObjectVersion,ParameterValue= ParameterKey=ApiId,UsePreviousValue=true ParameterKey=GitLfsBucketName,UsePreviousValue=true --capabilities CAPABILITY_IAM
