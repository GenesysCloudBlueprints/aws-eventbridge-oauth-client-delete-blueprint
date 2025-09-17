# AWS Account Info
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_event_bus" "eventbridge_bus" {
  name              = var.eventbridge_source_name
  event_source_name = var.eventbridge_source_name
}

# Build TypeScript project
resource "null_resource" "build_typescript" {
  provisioner "local-exec" {
    command     = "cd ${path.module}/../typescript && npm install && npm run compile"
    working_dir = path.module
  }

  triggers = {
    always_run = timestamp()
  }
}

# Install Python dependencies
resource "null_resource" "build_python" {
  provisioner "local-exec" {
    command     = "cd ${path.module}/../python && pip3 install -r requirements.txt -t ."
    working_dir = path.module
  }

  triggers = {
    always_run = timestamp()
  }
}

# Python Lambda Function
data "archive_file" "python_lambda_zip" {
  depends_on  = [null_resource.build_python]
  type        = "zip"
  source_dir  = "${path.module}/../python"
  output_path = "${path.module}/python-lambda.zip"

  # Force recreation when files change
  excludes = ["__pycache__", "*.pyc", ".DS_Store"]
}

resource "aws_lambda_function" "eventbridge_function_python" {
  filename         = data.archive_file.python_lambda_zip.output_path
  function_name    = "eventbridge-oauth-client-delete-python"
  role             = aws_iam_role.lambda_role_python.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  source_code_hash = data.archive_file.python_lambda_zip.output_base64sha256

  environment {
    variables = {
      PAGER_DUTY_API_KEY    = var.pager_duty_api_key
      PAGER_DUTY_SERVICE_ID = var.pager_duty_service_id
    }
  }
}

# Node.js Lambda Function
data "archive_file" "node_lambda_zip" {
  depends_on  = [null_resource.build_typescript]
  type        = "zip"
  source_dir  = "${path.module}/../typescript"
  output_path = "${path.module}/node-lambda.zip"

  # Include compiled output and dependencies, exclude source
  excludes = ["src", "tsconfig.json", "*.ts", ".DS_Store", "node_modules/.cache"]
}

resource "aws_lambda_function" "eventbridge_function_node" {
  filename         = data.archive_file.node_lambda_zip.output_path
  function_name    = "eventbridge-oauth-client-delete-node"
  role             = aws_iam_role.lambda_role_node.arn
  handler          = "dist/app.lambdaHandler"
  runtime          = "nodejs20.x"
  timeout          = 10
  source_code_hash = data.archive_file.node_lambda_zip.output_base64sha256

  environment {
    variables = {
      PAGER_DUTY_API_KEY    = var.pager_duty_api_key
      PAGER_DUTY_SERVICE_ID = var.pager_duty_service_id
    }
  }
}

# IAM Role for Python Lambda
resource "aws_iam_role" "lambda_role_python" {
  name = "eventbridge-lambda-role-python"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_python" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role_python.name
}

# IAM Role for Node Lambda
resource "aws_iam_role" "lambda_role_node" {
  name = "eventbridge-lambda-role-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_node" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role_node.name
}

# EventBridge Rules
resource "aws_cloudwatch_event_rule" "eventbridge_rule_python" {
  name           = "eventbridge-rule-python"
  event_bus_name = aws_cloudwatch_event_bus.eventbridge_bus.name

  event_pattern = jsonencode({
    account = [data.aws_caller_identity.current.account_id]
  })
}

resource "aws_cloudwatch_event_rule" "eventbridge_rule_node" {
  name           = "eventbridge-rule-node"
  event_bus_name = aws_cloudwatch_event_bus.eventbridge_bus.name

  event_pattern = jsonencode({
    account = [data.aws_caller_identity.current.account_id]
  })
}

# EventBridge Targets
resource "aws_cloudwatch_event_target" "lambda_target_python" {
  rule           = aws_cloudwatch_event_rule.eventbridge_rule_python.name
  event_bus_name = aws_cloudwatch_event_bus.eventbridge_bus.name
  target_id      = "EventBridgeLambdaTargetPython"
  arn            = aws_lambda_function.eventbridge_function_python.arn
}

resource "aws_cloudwatch_event_target" "lambda_target_node" {
  rule           = aws_cloudwatch_event_rule.eventbridge_rule_node.name
  event_bus_name = aws_cloudwatch_event_bus.eventbridge_bus.name
  target_id      = "EventBridgeLambdaTargetNode"
  arn            = aws_lambda_function.eventbridge_function_node.arn
}

# Lambda Permissions for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_python" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_function_python.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_rule_python.arn
}

resource "aws_lambda_permission" "allow_eventbridge_node" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_function_node.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_rule_node.arn
}
