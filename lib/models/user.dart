class User {
  int? id;
  String fullName;
  String email;
  String studentId;
  String? gender;
  int? level;
  String password;
  String? profileImage;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.studentId,
    this.gender,
    this.level,
    required this.password,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'studentId': studentId,
      'gender': gender,
      'level': level,
      'password': password,
      'profileImage': profileImage,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      studentId: map['studentId'],
      gender: map['gender'],
      level: map['level'],
      password: map['password'],
      profileImage: map['profileImage'],
    );
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? studentId,
    String? gender,
    int? level,
    String? password,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      gender: gender ?? this.gender,
      level: level ?? this.level,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
