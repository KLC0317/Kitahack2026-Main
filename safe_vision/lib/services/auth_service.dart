/// Service for handling user authentication
class AuthService {
  /// Authenticates user with email and password
  /// Returns true if credentials are valid, false otherwise
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock credentials validation
    return email == 'admin@safevision.com' && password == 'admin123';
  }

  /// Logs out the current user
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
