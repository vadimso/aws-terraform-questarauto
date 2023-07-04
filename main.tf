provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

resource "aws_lambda_function" "hello_world_lambda" {
  function_name = "hello-world-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "lambda_function_payload.zip"

  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "hello_world_api" {
  name          = "hello-world-api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.hello_world_lambda.invoke_arn
}

resource "aws_apigatewayv2_integration" "hello_world_integration" {
  api_id                 = aws_apigatewayv2_api.hello_world_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.hello_world_lambda.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "hello_world_route" {
  api_id    = aws_apigatewayv2_api.hello_world_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.hello_world_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.hello_world_api.execution_arn}/*/*/*"
}
