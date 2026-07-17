enum AskIntent {
  whyPromoted,
  missingEvidence,
  disagreement,
  observeNext,
  unsupported,
}

final class AskIntentRouter {
  const AskIntentRouter();

  AskIntent route(String question) {
    final value = question.trim().toLowerCase();
    if (value.isEmpty || value.length > 180) return AskIntent.unsupported;
    if (value.contains('diagnos') ||
        value.contains('treatment') ||
        value.contains('medicine') ||
        value.contains('prescription') ||
        value.contains('medication') ||
        value.contains('ignore previous') ||
        value.contains('system prompt') ||
        value.contains('full timeline') ||
        value.contains('all my data') ||
        value.contains('calendar title') ||
        value.contains('calendar account') ||
        value.contains('email address') ||
        value.contains('phone number')) {
      return AskIntent.unsupported;
    }
    if (value.contains('disagree') || value.contains('counter')) {
      return AskIntent.disagreement;
    }
    if (value.contains('missing') || value.contains('weaken')) {
      return AskIntent.missingEvidence;
    }
    if (value.contains('observe') || value.contains('next')) {
      return AskIntent.observeNext;
    }
    if (value.contains('why') || value.contains('promot')) {
      return AskIntent.whyPromoted;
    }
    return AskIntent.unsupported;
  }
}
