provider "aws" {
  region = "us-east-1"
}

# Creates an S3 bucket to store historical AWS cost data
resource "aws_s3_bucket" "costs_history" {
  bucket = "aws-costs-advisor-history-logs"
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "aws_costs_lambda_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy to allow Lambda to access AWS Cost Explorer, S3, and AWS Bedrock
resource "aws_iam_policy" "lambda_policy" {
  name        = "aws_costs_lambda_policy"
  description = "Allows Lambda to access AWS Cost Explorer, S3, and AWS Bedrock"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["ce:GetCostAndUsage"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::aws-costs-advisor-history-logs/*"
      },
      {
        Action = ["bedrock:InvokeModel"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function for AWS cost analysis with AI insights
resource "aws_lambda_function" "costs_lambda" {
  function_name    = "aws-costs-advisor"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.8"
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  
  environment {
    variables = {
      S3_BUCKET = "aws-costs-advisor-history-logs"
    }
  }
}

# API Gateway to expose the Lambda function as a REST service
resource "aws_apigatewayv2_api" "api" {
  name          = "aws-costs-advisor-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.costs_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /costs-advisor"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.costs_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
