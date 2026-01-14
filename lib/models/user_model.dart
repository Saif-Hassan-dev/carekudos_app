class AppUser {
  final String id;
  final String role;
  final String name;

  AppUser({required this.id, required this.role, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(id: json['id'], role: json['role'], name: json['name']);
  }
}
