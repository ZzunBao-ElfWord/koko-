/// Session / auth model
class Session {
  final String id;
  final String userId;
  final String token;
  final String name;

  const Session({
    required this.id,
    required this.userId,
    required this.token,
    required this.name,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['user_id'] ?? '',
        token: json['token'] ?? '',
        name: json['name'] ?? 'Unknown Device',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'token': token,
        'name': name,
      };
}

class LoginRequest {
  final String email;
  final String password;
  final String? friendlyName;
  final String? captcha;

  const LoginRequest({
    required this.email,
    required this.password,
    this.friendlyName,
    this.captcha,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (friendlyName != null) 'friendly_name': friendlyName,
        if (captcha != null) 'captcha': captcha,
      };
}

class RegisterRequest {
  final String email;
  final String password;
  final String? username;
  final String? invite;
  final String? captcha;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.username,
    this.invite,
    this.captcha,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (username != null) 'username': username,
        if (invite != null) 'invite': invite,
        if (captcha != null) 'captcha': captcha,
      };
}
