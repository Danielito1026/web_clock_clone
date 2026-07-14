/// Thrown by FeatureConfigRepository.fetchConfig() when the backend
/// doesn't recognize the company code — distinct from ConfigException,
/// which means the company WAS found but its config is structurally invalid.
class CompanyCodeNotFoundException implements Exception {
  final String companyCode;
  final String message;

  const CompanyCodeNotFoundException(
    this.companyCode, {
    this.message = 'Company code not recognized.',
  });

  @override
  String toString() => message;
}
