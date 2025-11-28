import '../models/user_model.dart';

const String kAdminIdentifier = 'admin1';
const String kAdminEmailDomain = 'gmail.com';

String normalizeAdminEmailInput(String emailOrUsername) {
  final trimmed = emailOrUsername.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains('@')) return trimmed;
  if (trimmed.toLowerCase() == kAdminIdentifier.toLowerCase()) {
    return '$kAdminIdentifier@$kAdminEmailDomain';
  }
  return trimmed;
}

bool isAdminEmail(String? email) {
  if (email == null || email.isEmpty) return false;
  final normalized = normalizeAdminEmailInput(email);
  final localPart = normalized.split('@').first.toLowerCase();
  return localPart == kAdminIdentifier.toLowerCase();
}

bool shouldRouteToAdmin(UserModel? userModel, String? email) {
  if (userModel?.isAdmin == true) return true;
  if (isAdminEmail(email)) return true;
  return false;
}
