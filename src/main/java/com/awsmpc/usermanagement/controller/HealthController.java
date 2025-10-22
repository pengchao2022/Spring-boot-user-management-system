package com.awsmpc.usermanagement.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@Tag(name = "健康检查", description = "应用健康状态检查API")
public class HealthController {
    
    @Autowired
    private Environment environment;
    
    @GetMapping
    @Operation(summary = "健康检查")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        status.put("service", "User Management System");
        status.put("version", "1.0.0");
        status.put("profile", String.join(",", environment.getActiveProfiles()));
        return ResponseEntity.ok(status);
    }
}