output "api_url" {
  description = "API Gateway 完整访问 URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.user_management.id
}

output "stage_name" {
  description = "API Stage 名称"
  value       = aws_api_gateway_stage.prod.stage_name
}

output "rest_api_id" {
  description = "REST API ID"
  value       = aws_api_gateway_rest_api.user_management.id
}

output "nlb_dns_name" {
  description = "K8s 创建的 NLB 的 DNS 名称"
  value       = data.aws_lb.user_mgmt_nlb.dns_name
}

output "nlb_arn" {
  description = "NLB 的 ARN"
  value       = data.aws_lb.user_mgmt_nlb.arn
}

output "api_gateway_invoke_url" {
  description = "API Gateway 调用 URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.user_management.id
}


