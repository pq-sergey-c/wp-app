enum ExternalOrchestratorEnvironment {
  production("production"),
  development("dev"),
  developmentLocal("dev-local");

  final String value;
  const ExternalOrchestratorEnvironment(this.value);

  static ExternalOrchestratorEnvironment? fromString(final String value) {
    try {
      return ExternalOrchestratorEnvironment.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }

  bool get isDevelopment {
    return this == ExternalOrchestratorEnvironment.development ||
        this == ExternalOrchestratorEnvironment.developmentLocal;
  }

  Uri get orchestratorUri {
    final Uri? result = _externalOrchestratorUriByEnvironmentMap[this];
    if (result == null) throw StateError('No URI is found for the current ExternalOrchestratorEnvironment: $value');
    return result;
  }

  Uri get streamUri {
    final Uri? result = _streamsUriByEnvironmentMap[this];
    if (result == null) throw StateError('No URI is found for the current ExternalOrchestratorEnvironment: $value');
    return result;
  }

  Uri get customVoiceoverBaseUri {
    final Uri? result = _customVoiceoversPreviewBaseUrlByEnvironmentMap[this];
    if (result == null) throw StateError('No URI is found for the current ExternalOrchestratorEnvironment: $value');
    return result;
  }

  Uri get freeVoiceoverBaseUri {
    final Uri? result = _freeVoiceoverUriByEnvironmentMap[this];
    if (result == null) throw StateError('No URI is found for the current ExternalOrchestratorEnvironment: $value');
    return result;
  }

  Uri get webAppBaseUri {
    final Uri? result = _webAppBaseUriByEnvironmentMap[this];
    if (result == null) throw StateError('No URI is found for the current ExternalOrchestratorEnvironment: $value');
    return result;
  }
}

// ----------------------------------------------------------------

final Map<ExternalOrchestratorEnvironment, Uri> _externalOrchestratorUriByEnvironmentMap = {
  ExternalOrchestratorEnvironment.developmentLocal: Uri.http("localhost:8080"),
  ExternalOrchestratorEnvironment.development: Uri.https("freud-dev.wavepaths.com"),
  ExternalOrchestratorEnvironment.production: Uri.https("freud.wavepaths.com"),
};

final Map<ExternalOrchestratorEnvironment, Uri> _streamsUriByEnvironmentMap = {
  ExternalOrchestratorEnvironment.developmentLocal: Uri.https("freud-streams-dev.wavepaths.com"),
  ExternalOrchestratorEnvironment.development: Uri.https("freud-streams-dev.wavepaths.com"),
  ExternalOrchestratorEnvironment.production: Uri.https("freud-streams.wavepaths.com"),
};

final Map<ExternalOrchestratorEnvironment, Uri> _customVoiceoversPreviewBaseUrlByEnvironmentMap = {
  ExternalOrchestratorEnvironment.developmentLocal: Uri.http(
    'freud-dev-sampledata.wavepaths.com',
    '/custom_voiceovers',
  ),
  ExternalOrchestratorEnvironment.development: Uri.https('freud-dev-sampledata.wavepaths.com', '/custom_voiceovers'),
  ExternalOrchestratorEnvironment.production: Uri.https('freud-prod-sampledata.wavepaths.com', '/custom_voiceovers'),
};

final Map<ExternalOrchestratorEnvironment, Uri> _freeVoiceoverUriByEnvironmentMap = {
  ExternalOrchestratorEnvironment.developmentLocal: Uri.http(
    'freud-streams-dev.wavepaths.com',
    '/fallback/FreeAccountVOTrimmed.mp3',
  ),
  ExternalOrchestratorEnvironment.development: Uri.https(
    'freud-streams-dev.wavepaths.com',
    '/fallback/FreeAccountVOTrimmed.mp3',
  ),
  ExternalOrchestratorEnvironment.production: Uri.https(
    'freud-streams.wavepaths.com',
    '/fallback/FreeAccountVOTrimmed.mp3',
  ),
};

final Map<ExternalOrchestratorEnvironment, Uri> _webAppBaseUriByEnvironmentMap = {
  // TODO: get the real baseUri for local dev (current one is but a copy-past from orchestratorUri)
  ExternalOrchestratorEnvironment.developmentLocal: Uri.http("localhost:8080"),

  ExternalOrchestratorEnvironment.development: Uri.https("guide-dev.wavepaths.com"),
  ExternalOrchestratorEnvironment.production: Uri.https("guide.wavepaths.com"),
};
