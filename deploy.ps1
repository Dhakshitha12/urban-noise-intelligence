# deploy.ps1 - Deployment Script for Urban Noise Intelligence Platform (SNS Edition)

# Settings
$AWS_REGION = "us-east-1"
$RANDOM_SUFFIX = Get-Random -Maximum 9999
$BUCKET_NAME = "urban-noise-platform-app-2026-$RANDOM_SUFFIX"
$LAMBDA_NAME = "urban-noise-analyzer-$RANDOM_SUFFIX"
$SNS_EMAIL = "admin@example.com"

Write-Host "============================"
Write-Host "Deploying Urban Noise Platform (With SNS)"
Write-Host "============================"

# Fetch standard Academy Account details
$callerId = aws sts get-caller-identity --no-cli-pager | ConvertFrom-Json
$accountId = $callerId.Account
$roleArn = "arn:aws:iam::" + $accountId + ":role/LabRole"
Write-Host "Utilizing Student Academy LabRole: $roleArn"

# 1. S3 Deployment 
Write-Host "`n[1/5] Setting up S3 Bucket for Static Website Hosting..."
aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION --no-cli-pager

$s3Policy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
"@
Set-Content -Path policy.json -Value $s3Policy
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false --no-cli-pager
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://policy.json --no-cli-pager
Remove-Item policy.json

aws s3 website "s3://$BUCKET_NAME" --index-document login.html --no-cli-pager
aws s3 sync .\frontend\ "s3://$BUCKET_NAME" --no-cli-pager

# 2. Amazon SNS Deployment
Write-Host "`n[2/5] Deploying Amazon SNS Topic for High Noise Alerts..."
$snsTopicRaw = aws sns create-topic --name "UrbanNoiseAlerts-$RANDOM_SUFFIX" --no-cli-pager
$snsTopic = $snsTopicRaw | ConvertFrom-Json
$snsTopicArn = $snsTopic.TopicArn
Write-Host "SNS Topic Created: $snsTopicArn"

aws sns subscribe --topic-arn $snsTopicArn --protocol email --notification-endpoint $SNS_EMAIL --no-cli-pager
Write-Host "Subscription successfully issued to $SNS_EMAIL!"

# 3. Deploy Lambda
Write-Host "`n[3/5] Deploying Lambda Function (Including OOP Engine)..."
Compress-Archive -Path .\backend\lambda_function.py, .\backend\noise_library.py -DestinationPath .\backend\lambda_function.zip -Force
$lambdaResultRaw = aws lambda create-function --function-name $LAMBDA_NAME --runtime python3.9 --role $roleArn --handler lambda_function.lambda_handler --zip-file "fileb://backend/lambda_function.zip" --environment "Variables={SNS_TOPIC_ARN=$snsTopicArn}" --no-cli-pager
$lambdaResult = $lambdaResultRaw | ConvertFrom-Json
$lambdaArn = $lambdaResult.FunctionArn

# 4. API Gateway Setup
Write-Host "`n[4/5] Setting up API Gateway..."
$apiResultRaw = aws apigatewayv2 create-api --name "UrbanNoiseAPI-$RANDOM_SUFFIX" --protocol-type HTTP --cors-configuration "AllowOrigins='*',AllowMethods='POST,OPTIONS',AllowHeaders='Content-Type'" --no-cli-pager
$apiResult = $apiResultRaw | ConvertFrom-Json
$apiId = $apiResult.ApiId
$apiUrl = $apiResult.ApiEndpoint

$integrationResultRaw = aws apigatewayv2 create-integration --api-id $apiId --integration-type AWS_PROXY --integration-uri $lambdaArn --payload-format-version 2.0 --no-cli-pager
$integrationResult = $integrationResultRaw | ConvertFrom-Json
$integrationId = $integrationResult.IntegrationId

aws apigatewayv2 create-route --api-id $apiId --route-key "POST /analyze-noise" --target "integrations/$integrationId" --no-cli-pager

aws lambda add-permission --function-name $LAMBDA_NAME --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:$AWS_REGION`:*:$apiId/*/*/analyze-noise" --no-cli-pager

Write-Host "`n[5/5] Updating Frontend Configuration with API URL..."
$fullApiUrl = "$apiUrl/analyze-noise"
Write-Host "New API Gateway URL: $fullApiUrl"

$analyzerPath = ".\frontend\analyzer.html"
$analyzerHtml = Get-Content $analyzerPath -Raw
$analyzerHtml = $analyzerHtml -replace 'https://placeholder\.execute-api\.us-east-1\.amazonaws\.com/analyze-noise', $fullApiUrl
$analyzerHtml = $analyzerHtml -replace 'https://[a-zA-Z0-9-]+\.execute-api\.us-east-1\.amazonaws\.com/analyze-noise', $fullApiUrl
Set-Content -Path $analyzerPath -Value $analyzerHtml

aws s3 cp $analyzerPath "s3://$BUCKET_NAME/analyzer.html" --no-cli-pager

Write-Host "`n============================"
Write-Host "ALL 5 SERVICES TRULY DEPLOYED SUCCESSFULLY!"
Write-Host "Public Website URL: http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
Write-Host "API Gateway Endpoint: $fullApiUrl"
Write-Host "============================"
