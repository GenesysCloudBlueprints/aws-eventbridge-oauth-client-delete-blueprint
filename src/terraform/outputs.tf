output "eventbridge_rule_python_arn" {
  description = "EventBridge Rule Python ARN"
  value       = aws_cloudwatch_event_rule.eventbridge_rule_python.arn
}

output "eventbridge_rule_node_arn" {
  description = "EventBridge Rule Node ARN"
  value       = aws_cloudwatch_event_rule.eventbridge_rule_node.arn
}

output "eventbridge_function_python_arn" {
  description = "EventBridge Lambda Function Python ARN"
  value       = aws_lambda_function.eventbridge_function_python.arn
}

output "eventbridge_function_node_arn" {
  description = "EventBridge Lambda Function Node ARN"
  value       = aws_lambda_function.eventbridge_function_node.arn
}

output "eventbridge_function_iam_role_python_arn" {
  description = "IAM Role created for EventBridge Python function"
  value       = aws_iam_role.lambda_role_python.arn
}

output "eventbridge_function_iam_role_node_arn" {
  description = "IAM Role created for EventBridge Node function"
  value       = aws_iam_role.lambda_role_node.arn
}