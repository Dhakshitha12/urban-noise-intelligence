import json
from noise_library import AmbientNoiseAnalyzer

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
