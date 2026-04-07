import json
import math

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

        # Calculate decibel using the standard formula
        decibel = 20 * math.log10(amplitude)

        # Classify Noise
        if decibel > 80:
            noise_type = "High Noise"
        elif decibel > 50:
            noise_type = "Moderate Noise"
        else:
            noise_type = "Low Noise"

        # Prepare HTTP Response with CORS headers
        response_body = {
            'decibel': round(decibel, 2),
            'noise_type': noise_type
        }

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
