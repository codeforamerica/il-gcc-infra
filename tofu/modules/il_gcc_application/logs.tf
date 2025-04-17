# resource "aws_cloudwatch_log_subscription_filter" "datadog" {
#   for_each = length(local.datadog_lambda) > 0 ? toset(["application", "application-worker"]) : toset([])
# 
#   name            = "datadog"
#   log_group_name  = "/aws/ecs/illinois-getchildcare/${var.environment}/${each.key}"
#   filter_pattern  = ""
#   destination_arn = data.aws_lambda_function.datadog["this"].arn
# }
