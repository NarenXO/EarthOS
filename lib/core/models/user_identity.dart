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
