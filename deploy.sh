#!/bin/bash
# deploy.sh - AWS CloudShell Deployment Script for Urban Noise Platform

set -e

AWS_REGION="us-east-1"
RANDOM_SUFFIX=$RANDOM
BUCKET_NAME="urban-noise-platform-app-2026-$RANDOM_SUFFIX"
ROLE_NAME="UrbanNoiseLambdaRole-$RANDOM_SUFFIX"
LAMBDA_NAME="urban-noise-analyzer"

echo "============================"
echo "Deploying Urban Noise Platform via AWS CloudShell"
echo "============================"
echo "Target S3 Bucket: $BUCKET_NAME"

echo -e "\n[1/5] Setting up S3 Bucket for Static Website Hosting..."
aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION

# Create public read policy for S3 bucket
cat > policy.json <<EOF
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
EOF

aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://policy.json
rm policy.json

aws s3 website "s3://$BUCKET_NAME" --index-document login.html
aws s3 sync ./frontend/ "s3://$BUCKET_NAME"

echo -e "\n[2/5] Creating IAM Role for Lambda..."
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

ROLE_ARN=$(aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
rm trust-policy.json

echo -e "\nWaiting for IAM role to propagate (10 seconds)..."
sleep 10

echo -e "\n[3/5] Deploying Lambda Function..."
# Create deployment package
cd backend
zip -r lambda_function.zip lambda_function.py
cd ..

LAMBDA_ARN=$(aws lambda create-function --function-name $LAMBDA_NAME \
    --runtime python3.9 \
    --role $ROLE_ARN \
    --handler lambda_function.lambda_handler \
    --zip-file "fileb://backend/lambda_function.zip" \
    --query 'FunctionArn' --output text)

echo -e "\n[4/5] Setting up API Gateway..."
API_DATA=$(aws apigatewayv2 create-api --name "UrbanNoiseAPI" --protocol-type HTTP --cors-configuration "AllowOrigins='*',AllowMethods='POST,OPTIONS',AllowHeaders='Content-Type'" --query '[ApiId, ApiEndpoint]' --output text)
API_ID=$(echo $API_DATA | awk '{print $1}')
API_URL=$(echo $API_DATA | awk '{print $2}')

# Create integration
INTEGRATION_ID=$(aws apigatewayv2 create-integration --api-id $API_ID --integration-type AWS_PROXY --integration-uri $LAMBDA_ARN --payload-format-version 2.0 --query 'IntegrationId' --output text)

# Create route
aws apigatewayv2 create-route --api-id $API_ID --route-key "POST /analyze-noise" --target "integrations/$INTEGRATION_ID" >/dev/null

# Give API Gateway permission to invoke Lambda
aws lambda add-permission --function-name $LAMBDA_NAME --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:$AWS_REGION:*:$API_ID/*/*/analyze-noise" >/dev/null

echo -e "\n[5/5] Updating Frontend Configuration with API URL..."
FULL_API_URL="$API_URL/analyze-noise"
echo "New API Gateway URL: $FULL_API_URL"

# Try to update analyzer.html with the new URL programmatically
sed -i "s|https://placeholder.execute-api.us-east-1.amazonaws.com/analyze-noise|$FULL_API_URL|g" ./frontend/analyzer.html

# Re-upload analyzer HTML to S3
aws s3 cp ./frontend/analyzer.html "s3://$BUCKET_NAME/analyzer.html"

echo -e "\n============================"
echo "DEPLOYMENT COMPLETE!"
echo "Public Website URL: http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
echo "API Gateway Endpoint: $FULL_API_URL"
echo "============================"
