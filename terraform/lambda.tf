// Create AWS Lambda functions

resource "aws_lambda_function" "lambda-one" {
  filename      = "../lambda-one/archive.zip"
  function_name = "step-functions-lambda-one"
  role          = aws_iam_role.lambda_assume_role.arn
  handler       = "index.handler"
  runtime       = "python3.8"

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lambda_function" "lambda-two" {
  filename      = "../lambda-two/archive.zip"
  function_name = "step-functions-lambda-two"
  role          = aws_iam_role.lambda_assume_role.arn
  handler       = "index.handler"
  runtime       = "python3.8"
}
// Create archives for AWS Lambda functions which will be used for Step Function

data "archive_file" "archive-lambda-one" {
  type        = "zip"
  output_path = "../lambda-one/archive.zip"
  source_file = "../lambda-one/index.py"
}

data "archive_file" "archive-lambda-two" {
  type        = "zip"
  output_path = "../lambda-two/archive.zip"
  source_file = "../lambda-two/index.py"
}

// Lambda IAM assume role
resource "aws_iam_role" "lambda_assume_role" {
  name               = "${var.lambda_function_name}-assume-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json

  lifecycle {
    create_before_destroy = true
  }
}

// IAM policy document for lambda assume role
data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  version = "2012-10-17"

  statement {
    sid     = "LambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}
