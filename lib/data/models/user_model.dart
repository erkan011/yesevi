/// Kullanıcı modeli (Firebase Auth + Firestore users koleksiyonu)
///
/// Login sonrası Firestore'dan çekilen kurum_id ve role bilgisini
/// de içerir. SaaS izolasyonu için kurum_id kritik önemdedir.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? kurumId;
  final String? role;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.kurumId,
    this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      kurumId: map['kurum_id'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'kurum_id': kurumId,
      'role': role,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? kurumId,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      kurumId: kurumId ?? this.kurumId,
      role: role ?? this.role,
    );
  }
}
