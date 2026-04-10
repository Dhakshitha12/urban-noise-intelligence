import json
import os
import boto3
from noise_library import AmbientNoiseAnalyzer

# Initialize SNS client
sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        # Parse the input from API Gateway
        body = json.loads(event.get('body', '{}'))
        amplitude = body.get('amplitude')

        if amplitude is None or amplitude <= 0:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST'
                },
                'body': json.dumps({'error': 'Invalid amplitude provided. Must be a positive number.'})
            }

        # Instantiate our custom Object-Oriented Library
        noise_engine = AmbientNoiseAnalyzer(amplitude)
        
        # Utilize the library to generate the intelligent report
        response_body = noise_engine.get_full_report()

        # SNS Service Logic - Fire alert if High Noise
        if response_body['noise_type'] == "High Noise" and SNS_TOPIC_ARN:
            try:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject='URBAN NOISE ALERT: High Noise Event Detected',
                    Message=f"A High Noise event was detected.\n\nDecibel Level: {response_body['decibel']} dB\nClassification: {response_body['noise_type']}\n\nPlease review the dashboard."
                )
            except Exception as sns_error:
                print("SNS Publish failed:", sns_error)

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST'
            },
            'body': json.dumps(response_body)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST'
            },
            'body': json.dumps({'error': str(e)})
        }
