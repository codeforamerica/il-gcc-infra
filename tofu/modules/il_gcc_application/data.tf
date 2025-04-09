# Find the lambda function for the Datadog forwarder so that we can use it as a
# destination for CloudWatch log subscriptions.
# data "aws_lambda_functions" "all" {}
# 
# data "aws_lambda_function" "datadog" {
#   for_each = length(local.datadog_lambda) > 0 ? toset(["this"]) : toset([])
# 
#   function_name = local.datadog_lambda[0]
# }

# Find the subnets and CIDR blocks for the private subnets in the VPC.
# data "aws_subnets" "private" {
#   filter {
#     name   = "vpc-id"
#     values = [var.vpc_id]
#   }
# 
#   tags = {
#     use = "private"
#   }
# }
# 
# data "aws_subnets" "public" {
#   filter {
#     name   = "vpc-id"
#     values = [var.vpc_id]
#   }
# 
#   tags = {
#     use = "public"
#   }
# }

# data "aws_subnet" "private" {
#   for_each = toset(data.aws_subnets.private.ids)
#   id       = each.value
# }

# output "subnet_cidr_blocks" {
#   value = [for s in data.aws_subnet.private : s.cidr_block]
# }
