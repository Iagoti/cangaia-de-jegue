class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.password,
  });

  final int id;
  final String username;
  final String password;

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['usuario'] as String,
      password: map['senha'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'usuario': username,
      'senha': password,
    };
  }
}
