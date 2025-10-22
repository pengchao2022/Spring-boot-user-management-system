package com.awsmpc.usermanagement.controller;

import com.awsmpc.usermanagement.entity.User;
import com.awsmpc.usermanagement.service.UserService;
import com.awsmpc.usermanagement.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
@Tag(name = "用户管理", description = "用户信息管理API")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    @Operation(summary = "获取所有用户")
    public ResponseEntity<ApiResponse<List<User>>> getAllUsers() {
        List<User> users = userService.getAllUsers();
        return ResponseEntity.ok(ApiResponse.success(users));
    }
    
    @GetMapping("/{id}")
    @Operation(summary = "根据ID获取用户")
    public ResponseEntity<ApiResponse<User>> getUserById(@PathVariable Long id) {
        Optional<User> user = userService.getUserById(id);
        return user.map(u -> ResponseEntity.ok(ApiResponse.success(u)))
                  .orElse(ResponseEntity.ok(ApiResponse.error("用户不存在")));
    }
    
    @GetMapping("/username/{username}")
    @Operation(summary = "根据用户名获取用户")
    public ResponseEntity<ApiResponse<User>> getUserByUsername(@PathVariable String username) {
        Optional<User> user = userService.getUserByUsername(username);
        return user.map(u -> ResponseEntity.ok(ApiResponse.success(u)))
                  .orElse(ResponseEntity.ok(ApiResponse.error("用户不存在")));
    }
    
    @PostMapping
    @Operation(summary = "创建用户")
    public ResponseEntity<ApiResponse<User>> createUser(@Valid @RequestBody User user) {
        if (userService.existsByUsername(user.getUsername())) {
            return ResponseEntity.badRequest().body(ApiResponse.error("用户名已存在"));
        }
        if (userService.existsByEmail(user.getEmail())) {
            return ResponseEntity.badRequest().body(ApiResponse.error("邮箱已存在"));
        }
        User createdUser = userService.createUser(user);
        return ResponseEntity.ok(ApiResponse.success(createdUser, "用户创建成功"));
    }
    
    @PutMapping("/{id}")
    @Operation(summary = "更新用户")
    public ResponseEntity<ApiResponse<User>> updateUser(@PathVariable Long id, @Valid @RequestBody User userDetails) {
        try {
            User updatedUser = userService.updateUser(id, userDetails);
            return ResponseEntity.ok(ApiResponse.success(updatedUser, "用户更新成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
    
    @DeleteMapping("/{id}")
    @Operation(summary = "删除用户")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.ok(ApiResponse.success(null, "用户删除成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
    
    @GetMapping("/department/{department}")
    @Operation(summary = "根据部门获取用户")
    public ResponseEntity<ApiResponse<List<User>>> getUsersByDepartment(@PathVariable String department) {
        List<User> users = userService.getUsersByDepartment(department);
        return ResponseEntity.ok(ApiResponse.success(users));
    }
    
    @GetMapping("/search")
    @Operation(summary = "搜索用户")
    public ResponseEntity<ApiResponse<List<User>>> searchUsers(@RequestParam String keyword) {
        List<User> users = userService.searchUsers(keyword);
        return ResponseEntity.ok(ApiResponse.success(users));
    }
}