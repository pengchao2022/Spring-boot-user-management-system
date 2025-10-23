# Spring boot-User-Management-System-AWS-EKS

In this demo, I'd like to show you something about AWS API Gateway + Internal NLB + VPC link

Spring boot backend service use the API Gateway as the door to communicate with Frontend service

## Features

- Terraform to create AWS API gateway

      - VPC Link
      - API Gateway

- EKS pods for backend and database service

      - PostgreSQL stateful with None ClusterIP for a Headless service
      - Internal NLB with SSL HTTPS for security
      - Dockerfile to package src code 

- Jenkinsfile for CD (deploy to EKS) 

- GitLab CI for code repository (private repo for security)

## Usage

- Check the API gateway URL:
```shell
pengchaoma@Pengchaos-MacBook-Pro Spring-boot-user-management-system % curl -v https://oqwgfxwlo7.execute-api.us-east-1.amazonaws.com/prod
* Host oqwgfxwlo7.execute-api.us-east-1.amazonaws.com:443 was resolved.
* Connected to oqwgfxwlo7.execute-api.us-east-1.amazonaws.com (3.225.84.182) port 443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
*  CAfile: /etc/ssl/cert.pem
*  CApath: none
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-AES128-GCM-SHA256 / [blank] / UNDEF
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=*.execute-api.us-east-1.amazonaws.com
*  start date: Mar 22 00:00:00 2025 GMT
*  expire date: Apr 19 23:59:59 2026 GMT
*  subjectAltName: host "oqwgfxwlo7.execute-api.us-east-1.amazonaws.com" matched cert's "*.execute-api.us-east-1.amazonaws.com"
*  issuer: C=US; O=Amazon; CN=Amazon RSA 2048 M03
*  SSL certificate verify ok.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://oqwgfxwlo7.execute-api.us-east-1.amazonaws.com/prod
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: oqwgfxwlo7.execute-api.us-east-1.amazonaws.com]
* [HTTP/2] [1] [:path: /prod]
* [HTTP/2] [1] [user-agent: curl/8.7.1]
* [HTTP/2] [1] [accept: */*]
> GET /prod HTTP/2
> Host: oqwgfxwlo7.execute-api.us-east-1.amazonaws.com
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/2 200 
< date: Thu, 23 Oct 2025 14:52:43 GMT
< content-type: application/json
< content-length: 204
< x-amzn-requestid: dc86a746-fd4d-4b4e-ba34-14b1af475e98
< x-amzn-remapped-connection: keep-alive
< x-amz-apigw-id: S58hWHdxoAMECjA=
< x-amzn-remapped-date: Thu, 23 Oct 2025 14:52:43 GMT
< 
* Connection #0 to host oqwgfxwlo7.execute-api.us-east-1.amazonaws.com left intact


{"service":"User Management System","documentation":"访问 /swagger-ui.html 查看API文档","health":"访问 /api/health 查看健康状态","message":"欢迎使用用户管理系统","version":"1.0.0"}%                                                                                                           
```
- Create one user
```shell

 curl -X POST https://oqwgfxwlo7.execute-api.us-east-1.amazonaws.com/prod/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "pengchao.ma",
    "email": "18510656167@163.com",
    "phone": "18510656167",
    "password": "123456",
    "firstName": "pengchao",
    "lastName": "ma"
  }'

{"success":true,"message":"用户创建成功","data":{"id":1,"username":"pengchao.ma","email":"18510656167@163.com","phone":"18510656167","department":null,"position":null,"createdAt":"2025-10-23T14:36:49.149424985","updatedAt":"2025-10-23T14:36:49.149424985"}}
```
- Search user with Phone number:
```shell
curl -X GET "https://oqwgfxwlo7.execute-api.us-east-1.amazonaws.com/prod/api/users?phone=18510656167"


{"success":true,"data":[{"id":1,"username":"pengchao.ma","email":"18510656167@163.com","phone":"18510656167","department":null,"position":null,"createdAt":"2025-10-23T14:36:49.149425","updatedAt":"2025-10-23T14:36:49.149425"}]}% 
```

Designed and Developed by Pengchao Ma @2025
