resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = var.step_function_name
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode(
    {
      "StartAt" : "lambda-two-config",
      "States" : {
        "lambda-two-config" : {
          "Comment" : "To configure the lambda-two.",
          "Type" : "Pass",
          "Result" : {
            "min" : 1,
            "max" : 10
          },
          "ResultPath" : "$",
          "Next" : "lambda-two"
        },


        "lambda-two" : {
          "Comment" : "Generate a number based on input.",
          "Type" : "Task",
          "Resource" : "${aws_lambda_function.lambda-two.arn}",
          "Next" : "send-notification-if-less-than-5"
        },


        "send-notification-if-less-than-5" : {
          "Comment" : "A choice state to decide to send out notification for <5 or trigger power of three lambda for >5.",
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$",
              "NumericGreaterThanEquals" : 5,
              "Next" : "power-of-three-lambda"
            },
            {
              "Variable" : "$",
              "NumericLessThan" : 5,
              "Next" : "send-multiple-notification"
            }
          ]
        },


        "power-of-three-lambda" : {
          "Comment" : "Increase the input to power of 3 with customized input.",
          "Type" : "Task",
          "Parameters" : {
            "base.$" : "$",
            "exponent" : 3
          },
          "Resource" : "${aws_lambda_function.lambda-one.arn}",
          "End" : true
        },


        "send-multiple-notification" : {
          "Comment" : "Trigger multiple notification using AWS SNS",
          "Type" : "Parallel",
          "End" : true,
          "Branches" : [
            {
              "StartAt" : "send-sms-notification",
              "States" : {
                "send-sms-notification" : {
                  "Type" : "Task",
                  "Resource" : "arn:aws:states:::sns:publish",
                  "Parameters" : {
                    "Message" : "SMS: Random number is less than 5 $",
                    "PhoneNumber" : "${var.phone_number_for_notification}"
                  },
                  "End" : true
                }
              }
            }
          ]
        }
      }
    }
  )

  depends_on = [aws_lambda_function.lambda-two, aws_lambda_function.lambda-two]

}

resource "aws_iam_policy" "policy_publish_sns" {
  name = "stepFunctionSampleSNSInvocationPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "sns:Publish",
              "sns:SetSMSAttributes",
              "sns:GetSMSAttributes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role" "step_function_role" {
  name               = "${var.step_function_name}-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "states.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": "StepFunctionAssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.step_function_name}-policy"
  role = aws_iam_role.step_function_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
      "Action": [
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_publish_sns" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.policy_publish_sns.arn
}