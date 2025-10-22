package com.awsmpc.usermanagement.service;

import com.awsmpc.usermanagement.entity.User;
import java.util.List;
import java.util.Optional;

public interface UserService {
    List<User> getAllUsers();
    Optional<User> getUserById(Long id);
    Optional<User> getUserByUsername(String username);
    User createUser(User user);
    User updateUser(Long id, User userDetails);
    void deleteUser(Long id);
    List<User> getUsersByDepartment(String department);
    List<User> searchUsers(String keyword);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
}