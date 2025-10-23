# 查询由 K8s 创建的 NLB
data "aws_lb" "user_mgmt_nlb" {
  name = "user-mgmt-nlb"  # 这个名称在配置中是固定的
}

# 创建 REST API Gateway
resource "aws_api_gateway_rest_api" "user_management" {
  name        = "user-management-api"
  description = "API Gateway for Spring Boot User Management Application"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 创建代理资源，捕获所有路径
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  parent_id   = aws_api_gateway_rest_api.user_management.root_resource_id
  path_part   = "{proxy+}"
}

# 为代理资源创建 ANY 方法
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.user_management.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# 为根路径创建方法
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.user_management.id
  resource_id   = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# 创建 VPC Link 
resource "aws_api_gateway_vpc_link" "user_management_nlb_link" {
  name        = "user-management-nlb-link"
  target_arns = [data.aws_lb.user_mgmt_nlb.arn] # 指向内部NLB ARN
  description = "VPC Link for internal User Management NLB"
}

# 创建与 K8s NLB 的集成 - 代理路径
resource "aws_api_gateway_integration" "k8s_integration" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "https://${data.aws_lb.user_mgmt_nlb.dns_name}/{proxy}"
  connection_type         = "VPC_LINK" 
  connection_id           = aws_api_gateway_vpc_link.user_management_nlb_link.id # 关联VPC Link

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# 创建与 K8s NLB 的集成 - 根路径（修复：添加 VPC Link 配置）
resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "https://${data.aws_lb.user_mgmt_nlb.dns_name}/"
  connection_type         = "VPC_LINK"  # 添加这行
  connection_id           = aws_api_gateway_vpc_link.user_management_nlb_link.id  # 添加这行
}

# 为代理路径添加方法响应
resource "aws_api_gateway_method_response" "proxy_200" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "proxy_500" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "500"
}

# 为代理路径添加集成响应
resource "aws_api_gateway_integration_response" "proxy_200" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy_200.status_code

  depends_on = [
    aws_api_gateway_integration.k8s_integration
  ]
}

resource "aws_api_gateway_integration_response" "proxy_500" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy_500.status_code
  selection_pattern = "5\\d{2}"

  depends_on = [
    aws_api_gateway_integration.k8s_integration
  ]
}

# 为根路径添加方法响应
resource "aws_api_gateway_method_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "root_500" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "500"
}

# 为根路径添加集成响应
resource "aws_api_gateway_integration_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = aws_api_gateway_method_response.root_200.status_code

  depends_on = [
    aws_api_gateway_integration.root_integration
  ]
}

resource "aws_api_gateway_integration_response" "root_500" {
  rest_api_id = aws_api_gateway_rest_api.user_management.id
  resource_id = aws_api_gateway_rest_api.user_management.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = aws_api_gateway_method_response.root_500.status_code
  selection_pattern = "5\\d{2}"

  depends_on = [
    aws_api_gateway_integration.root_integration
  ]
}

# 创建部署
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.k8s_integration,
    aws_api_gateway_integration.root_integration,
    aws_api_gateway_integration_response.proxy_200,
    aws_api_gateway_integration_response.proxy_500,
    aws_api_gateway_integration_response.root_200,
    aws_api_gateway_integration_response.root_500,
    aws_api_gateway_vpc_link.user_management_nlb_link  # 添加 VPC Link 依赖
  ]
  
  rest_api_id = aws_api_gateway_rest_api.user_management.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_integration.k8s_integration.id,
      aws_api_gateway_integration.root_integration.id,
      aws_api_gateway_method_response.proxy_200.id,
      aws_api_gateway_method_response.proxy_500.id,
      aws_api_gateway_method_response.root_200.id,
      aws_api_gateway_method_response.root_500.id,
      aws_api_gateway_integration_response.proxy_200.id,
      aws_api_gateway_integration_response.proxy_500.id,
      aws_api_gateway_integration_response.root_200.id,
      aws_api_gateway_integration_response.root_500.id,
      aws_api_gateway_vpc_link.user_management_nlb_link.id  # 添加 VPC Link 到触发器
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 创建阶段
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.user_management.id
  stage_name    = "prod"
}