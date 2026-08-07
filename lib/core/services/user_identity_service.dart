import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserIdentity {
  final String id;
  final String name;

  UserIdentity({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class UserIdentityService {
  static const String _idKey = 'user_id';
  static const String _nameKey = 'user_name';
  final Uuid _uuid = const Uuid();

  Future<UserIdentity> getOrCreateUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    final existingId = prefs.getString(_idKey);
    final existingName = prefs.getString(_nameKey);

    if (existingId != null && existingName != null) {
      return UserIdentity(
        id: existingId,
        name: existingName,
      );
    }

    // Generate new identity
    final newId = _uuid.v4();
    return UserIdentity(
      id: newId,
      name: '', // Empty name until user provides it
    );
  }

  Future<void> saveUser(String name, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, id);
    await prefs.setString(_nameKey, name);
  }
}
