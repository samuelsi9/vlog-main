class AppleLoginResponse {
  final String accessToken;
  final String tokenType;
  final String message;
  final Map<String, dynamic> user;

  AppleLoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.message,
    required this.user,
  });

  factory AppleLoginResponse.fromMap(Map<String, dynamic> map) {
    return AppleLoginResponse(
      accessToken: map['access_token']?.toString() ?? '',
      tokenType: map['token_type']?.toString() ?? 'Bearer',
      message: map['message']?.toString() ?? '',
      user: map['user'] is Map<String, dynamic>
          ? map['user'] as Map<String, dynamic>
          : map['user'] is Map
              ? Map<String, dynamic>.from(map['user'] as Map)
              : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'message': message,
      'user': user,
    };
  }
}

