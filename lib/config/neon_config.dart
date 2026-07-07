class NeonConfig {
  const NeonConfig._();

  static const String connectionUrl = String.fromEnvironment(
    'NEON_DATABASE_URL',
    defaultValue:
        'postgresql://neondb_owner:npg_7pX3VeCbUyjP@ep-square-mouse-acko72j3-pooler.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require',
  );

  static String get driverConnectionUrl {
    final uri = Uri.parse(connectionUrl);
    final queryParameters = Map<String, String>.from(uri.queryParameters)
      ..remove('channel_binding');

    return uri
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        )
        .toString();
  }
}
