import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:earthos/core/models/user_identity.dart';

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
