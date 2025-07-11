// 🚀 VÍ DỤ: Implement Commands cho nhiều features

// ===============================================
// 👤 USER MANAGEMENT FEATURES
// ===============================================

// Load users - chỉ 4 lines!
class LoadUsersCommand extends Command<List<User>> {
  @override
  Future<List<User>> performAction() async {
    return await userService.getUsers();
  }
}

// Create user - chỉ 4 lines!
class CreateUserCommand extends Command1<User, UserData> {
  @override
  Future<User> performActionWith(UserData userData) async {
    return await userService.createUser(userData);
  }
}

// Update user - chỉ 4 lines!
class UpdateUserCommand extends Command1<User, User> {
  @override
  Future<User> performActionWith(User user) async {
    return await userService.updateUser(user);
  }
}

// Delete user - chỉ 4 lines!
class DeleteUserCommand extends Command1<bool, String> {
  @override
  Future<bool> performActionWith(String userId) async {
    return await userService.deleteUser(userId);
  }
}

// Search users - chỉ 4 lines!
class SearchUsersCommand extends Command1<List<User>, String> {
  @override
  Future<List<User>> performActionWith(String query) async {
    return await userService.searchUsers(query);
  }
}

// ===============================================
// 📦 PRODUCT MANAGEMENT FEATURES  
// ===============================================

// Load products
class LoadProductsCommand extends Command<List<Product>> {
  @override
  Future<List<Product>> performAction() async {
    return await productService.getProducts();
  }
}

// Add to cart
class AddToCartCommand extends Command2<bool, String, int> {
  @override
  Future<bool> performActionWith(String productId, int quantity) async {
    return await cartService.addToCart(productId, quantity);
  }
}

// Purchase
class PurchaseCommand extends Command1<Order, List<CartItem>> {
  @override
  Future<Order> performActionWith(List<CartItem> items) async {
    return await orderService.purchase(items);
  }
}

// ===============================================
// 📷 PHOTO UPLOAD FEATURES
// ===============================================

// Upload photo
class UploadPhotoCommand extends Command1<String, File> {
  @override
  Future<String> performActionWith(File imageFile) async {
    return await photoService.uploadPhoto(imageFile);
  }
}

// Compress photo before upload
class CompressPhotoCommand extends Command1<File, File> {
  @override
  Future<File> performActionWith(File originalFile) async {
    return await imageService.compressImage(originalFile);
  }
}

// ===============================================
// 💬 CHAT FEATURES
// ===============================================

// Send message
class SendMessageCommand extends Command1<Message, String> {
  @override
  Future<Message> performActionWith(String text) async {
    return await chatService.sendMessage(text);
  }
}

// Load chat history
class LoadChatHistoryCommand extends Command1<List<Message>, String> {
  @override
  Future<List<Message>> performActionWith(String chatId) async {
    return await chatService.getChatHistory(chatId);
  }
}

// ===============================================
// 🔐 AUTHENTICATION FEATURES
// ===============================================

// Login
class LoginCommand extends Command1<User, LoginData> {
  @override
  Future<User> performActionWith(LoginData loginData) async {
    return await authService.login(loginData.email, loginData.password);
  }
}

// Register
class RegisterCommand extends Command1<User, RegisterData> {
  @override
  Future<User> performActionWith(RegisterData registerData) async {
    return await authService.register(registerData);
  }
}

// Logout
class LogoutCommand extends Command<bool> {
  @override
  Future<bool> performAction() async {
    return await authService.logout();
  }
}

// Reset password
class ResetPasswordCommand extends Command1<bool, String> {
  @override
  Future<bool> performActionWith(String email) async {
    return await authService.resetPassword(email);
  }
}

// ===============================================
// 🌍 LOCATION FEATURES
// ===============================================

// Get current location
class GetLocationCommand extends Command<Location> {
  @override
  Future<Location> performAction() async {
    return await locationService.getCurrentLocation();
  }
}

// Search nearby places
class SearchNearbyCommand extends Command2<List<Place>, double, double> {
  @override
  Future<List<Place>> performActionWith(double lat, double lng) async {
    return await placesService.searchNearby(lat, lng);
  }
}

// ===============================================
// 💾 SYNC FEATURES
// ===============================================

// Sync data to server
class SyncToServerCommand extends Command<bool> {
  @override
  Future<bool> performAction() async {
    return await syncService.syncToServer();
  }
}

// Download offline data
class DownloadOfflineDataCommand extends Command<bool> {
  @override
  Future<bool> performAction() async {
    return await syncService.downloadOfflineData();
  }
}

// ===============================================
// 📊 ANALYTICS FEATURES
// ===============================================

// Track event
class TrackEventCommand extends Command1<bool, AnalyticsEvent> {
  @override
  Future<bool> performActionWith(AnalyticsEvent event) async {
    return await analyticsService.trackEvent(event);
  }
}

// Load analytics data
class LoadAnalyticsCommand extends Command1<AnalyticsData, DateRange> {
  @override
  Future<AnalyticsData> performActionWith(DateRange dateRange) async {
    return await analyticsService.getAnalytics(dateRange);
  }
}

// ===============================================
// 🔄 COMPLEX WORKFLOW COMMANDS
// ===============================================

// Multi-step onboarding
class OnboardingCommand extends Command<bool> {
  @override
  Future<bool> performAction() async {
    // Step 1: Setup user profile
    await userService.setupProfile();
    
    // Step 2: Download initial data
    await dataService.downloadInitialData();
    
    // Step 3: Setup notifications
    await notificationService.setupNotifications();
    
    // Step 4: Track onboarding completion
    await analyticsService.trackOnboardingComplete();
    
    return true;
  }
}

// Backup all user data
class BackupDataCommand extends Command<bool> {
  @override
  Future<bool> performAction() async {
    // Backup photos
    await photoService.backupPhotos();
    
    // Backup messages
    await chatService.backupMessages();
    
    // Backup user preferences
    await settingsService.backupSettings();
    
    return true;
  }
}

/*
🔥 PATTERN NHẬN XÉT:

1. ✅ MỖI COMMAND CHỈ 4-6 LINES
   - Không cần setState()
   - Không cần try-catch
   - Không cần duplicate prevention
   - Chỉ focus vào business logic

2. ✅ TẤT CẢ FEATURES ĐƯỢC BENEFIT
   - Automatic loading states
   - Automatic error handling  
   - Consistent UI behavior
   - Easy to test

3. ✅ PATTERNS THƯỜNG DÙNG:
   - Command<T>: No parameters (load, refresh, logout)
   - Command1<T, P>: 1 parameter (search, create, delete)
   - Command2<T, A, B>: 2 parameters (add to cart, search nearby)

4. ✅ COMPLEX WORKFLOWS:
   - Có thể combine multiple service calls
   - Automatic state management cho toàn bộ workflow
   - Easy to track progress

5. ✅ REUSABLE BASE:
   - Viết Command base class 1 lần
   - Mọi feature sau đó chỉ việc extend
   - Consistent behavior across entire app
*/ 