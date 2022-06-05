data "aws_iam_policy_document" "lambda_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "iam-for-lambda-moderately"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy.json
}

data "aws_iam_policy_document" "allow_rekognition_lambda" {
  statement {
    sid    = "allowRekognitionLambda"
    effect = "Allow"

    actions = [
      "rekognition:DetectModerationLabels"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "allow_rekognition_lambda" {
  name        = "allow-rekognition-lambda"
  description = "Allows lambda function to use rekognition"

  policy = data.aws_iam_policy_document.allow_rekognition_lambda.json
}

resource "aws_iam_role_policy_attachment" "allow_rekognition_lambda" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.allow_rekognition_lambda.arn
}