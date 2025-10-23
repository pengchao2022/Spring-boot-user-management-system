// src/main/java/com/awsmpc/usermanagement/controller/HomeController.java
package com.awsmpc.usermanagement.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@Tag(name = "首页", description = "应用首页和API信息")
public class HomeController {
    
    @GetMapping("/")
    @Operation(summary = "欢迎页面")
    public ResponseEntity<Map<String, String>> home() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "欢迎使用用户管理系统");
        response.put("service", "User Management System");
        response.put("version", "1.0.0");
        response.put("documentation", "访问 /swagger-ui.html 查看API文档");
        response.put("health", "访问 /api/health 查看健康状态");
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/api")
    @Operation(summary = "API首页")
    public ResponseEntity<Map<String, String>> apiHome() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "用户管理系统 API");
        response.put("endpoints", "/api/health, /api/users");
        response.put("health", "/api/health - 健康检查");
        response.put("users", "/api/users - 用户管理");
        return ResponseEntity.ok(response);
    }
}