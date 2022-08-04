resource "aws_cloudwatch_event_rule" "sfn_event_rule" {
  name                = "sfn-event-rule"
  description         = "retry scheduled every 2 min"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "sfn_target" {
  target_id = "stepfunction_target"
  arn  = aws_sfn_state_machine.sfn_state_machine.arn
  rule = aws_cloudwatch_event_rule.sfn_event_rule.name
  role_arn = aws_iam_role.EventBridgeRole.arn
}

resource "aws_iam_role" "EventBridgeRole" {
  assume_role_policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "events.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "EventBridgePolicy" {
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : [
        "states:StartExecution"
      ],
      "Resource" : "${aws_sfn_state_machine.sfn_state_machine.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "EventBridgePolicyAttachment" {
  role       = aws_iam_role.EventBridgeRole.name
  policy_arn = aws_iam_policy.EventBridgePolicy.arn
}