abstract final class SchemaVersions {
  static const database = 2;
  static const normalization = 1;
  static const meetingAnalysis = 5;
  static const promotionPolicy = 2;
  static const demoFixture = 4;
  static const explorerSchema = 1;
  static const explainerSchema = 2;
  static const prompt = 1;
  static const outputGuard = 5;
  static const exportSchema = 1;

  static const values = <String, int>{
    'database_schema_version': database,
    'normalization_version': normalization,
    'meeting_analysis_version': meetingAnalysis,
    'promotion_policy_version': promotionPolicy,
    'demo_fixture_version': demoFixture,
    'explorer_schema_version': explorerSchema,
    'explainer_schema_version': explainerSchema,
    'prompt_version': prompt,
    'output_guard_version': outputGuard,
    'export_schema_version': exportSchema,
  };
}
