# Find the lambda function for the Datadog forwarder so that we can use it as a
# destination for CloudWatch log subscriptions.
data "aws_lambda_functions" "all" {}

data "aws_lambda_function" "datadog" {
  for_each = length(local.datadog_lambda) > 0 ? toset(["this"]) : toset([])

  function_name = local.datadog_lambda[0]
}
