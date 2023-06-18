output "api_gateway_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}
output "api_gateway_id" {
  value = aws_apigatewayv2_api.main.id
}
output "lambda_function_arn" {
  value = aws_lambda_function.save_visit.arn
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.visits_table.name
}
output "lambda_function_name" {
  value = aws_lambda_function.save_visit.function_name
}

