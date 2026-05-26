class AiseeApiAuth {
  const AiseeApiAuth._();

  static String bearer(String accessToken) {
    final String trimmed = accessToken.trim();
    if (trimmed.startsWith('Bearer ')) {
      return trimmed;
    }
    return 'Bearer $trimmed';
  }
}
