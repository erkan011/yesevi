/// Kullanıcı modeli (Firebase Auth'tan gelen bilgiler)
class UserModel {
  final String uid;
  final String email;
  final String displayName;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }
}
