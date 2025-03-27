locals {
  datadog_lambda = [
    for lambda in data.aws_lambda_functions.all.function_names :
    lambda if length(regexall("^DatadogIntegration-ForwarderStack-", lambda)) > 0
  ]
}
