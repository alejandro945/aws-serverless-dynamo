# Create the API Gateway --- Access Layer
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"
}

# Creation of the AWS lambda resource -- Business Layer
resource "aws_lambda_function" "save_visit" {
  filename      = "save_api_code.zip"
  function_name = "saveVisit"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visits_table.name
    }
  }
}

# DynamoDB Table --- Data Layer
resource "aws_dynamodb_table" "visits_table" {
  name         = "visits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "date"
    type = "S"
  }
  attribute {
    name = "location"
    type = "S"
  }

  global_secondary_index {
    name               = "location-index"
    hash_key           = "location"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  global_secondary_index {
    name               = "date-index"
    hash_key           = "date"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }
}

# Create the Lambda Integration --- Access Layer Binding
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id               = aws_apigatewayv2_api.main.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.save_visit.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# Create the Lambda Route --- Access Layer Binding
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Creación del IAM Role para la ejecución de las funciones Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Asociación de la política para acceder a DynamoDB a la IAM Role
resource "aws_iam_policy_attachment" "lambda_dynamodb_policy" {
  name       = "lambda_dynamodb_policy"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Empaquetado y despliegue del código de las funciones Lambda
data "archive_file" "save_api_code" {
  type        = "zip"
  source_dir  = "../saveVisit"
  output_path = "save_api_code.zip"
}
