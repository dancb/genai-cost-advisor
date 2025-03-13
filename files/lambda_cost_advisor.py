import json
import boto3
import datetime
import os

# Initialize AWS clients
cost_explorer = boto3.client('ce')
bedrock_runtime = boto3.client('bedrock-runtime')

def get_aws_costs(region, tag=None):
    """Fetches AWS cost data for a specific region, filtering by tag if provided."""
    today = datetime.date.today()
    start_date = today - datetime.timedelta(days=7)

    filters = {
        "Dimensions": {
            "Key": "REGION",
            "Values": [region]
        }
    }

    if tag:
        filters["Tags"] = {
            "Key": tag.split(":")[0],
            "Values": [tag.split(":")[1]]
        }

    response = cost_explorer.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': today.strftime('%Y-%m-%d')
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        Filter=filters
    )

    return response

def generate_cost_analysis(cost_data):
    """Generates a cost analysis summary using AWS Bedrock Gen AI."""
    prompt = (
        "Analyze the following AWS cost data and provide insights in simple terms: "
        + json.dumps(cost_data, indent=2)
    )

    response = bedrock_runtime.invoke_model(
        modelId="anthropic.claude-v2",
        contentType="application/json",
        body=json.dumps({"prompt": prompt, "max_tokens": 300})
    )

    response_body = json.loads(response['body'].read())
    return response_body['completion']

def lambda_handler(event, context):
    """AWS Lambda handler function for processing cost advisory requests."""
    try:
        body = json.loads(event['body'])
        region = body.get('region', 'us-east-1')
        tag = body.get('tag')

        cost_data = get_aws_costs(region, tag)
        analysis_text = generate_cost_analysis(cost_data)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'region': region,
                'tag': tag if tag else "All infrastructure",
                'cost_data': cost_data,
                'analysis': analysis_text
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
