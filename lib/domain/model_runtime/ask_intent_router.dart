enum AskIntent {
  whyPromoted,
  missingEvidence,
  disagreement,
  observeNext,
  unsupported,
}

final class AskIntentRouter {
  const AskIntentRouter();

  static const _blockedFragments = <String>[
    // Diagnosis, treatment, and health-action requests stay outside the
    // evidence-scoped Ask surface even when they also contain words such as
    // "why" or "next" that would otherwise match a supported intent.
    'diagnos',
    'treatment',
    'medicine',
    'prescription',
    'medication',
    'aspirin',
    'ibuprofen',
    'paracetamol',
    'acetaminophen',
    'dosage',
    'dose ',
    'doctor',
    'clinician',
    'therapist',
    'therapy',
    'disorder',
    'disease',
    'symptom',
    'emergency',
    'hospital',
    'panic attack',
    'heart attack',
    'should i take',
    'can i take',
    'what should i take',
    'lower my heart rate',
    'reduce my heart rate',
    'raise my heart rate',
    'cure ',
    'prevent ',

    // Prompt extraction and instruction override attempts.
    'ignore previous',
    'ignore all',
    'override instructions',
    'system prompt',
    'developer prompt',
    'developer message',
    'hidden instructions',
    'reveal instructions',
    'jailbreak',

    // Raw timeline and identity disclosure requests.
    'full timeline',
    'all my data',
    'calendar title',
    'calendar account',
    'email address',
    'phone number',
  ];

  AskIntent route(String question) {
    final value = question.trim().toLowerCase();
    if (value.isEmpty || value.length > 180) return AskIntent.unsupported;
    if (_blockedFragments.any(value.contains)) {
      return AskIntent.unsupported;
    }
    if (value.contains('disagree') ||
        value.contains('counter') ||
        value.contains('how much disagreement') ||
        value.contains('not match') ||
        value.contains("doesn't match") ||
        value.contains('did not match')) {
      return AskIntent.disagreement;
    }
    if (value.contains('missing') ||
        value.contains('left out') ||
        value.contains('excluded') ||
        value.contains('weaken')) {
      return AskIntent.missingEvidence;
    }
    if (value.contains('observe') ||
        value.contains('track') ||
        value.contains('next') ||
        value.contains('make this result change')) {
      return AskIntent.observeNext;
    }
    if (value.contains('why') ||
        value.contains('promot') ||
        value.contains('numbers support')) {
      return AskIntent.whyPromoted;
    }
    return AskIntent.unsupported;
  }
}
