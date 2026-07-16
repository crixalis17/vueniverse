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
    if (value.isEmpty) return AskIntent.unsupported;
    if (value.contains('diagnos') ||
        value.contains('treatment') ||
        value.contains('medicine') ||
        value.contains('prescription') ||
        value.contains('medication')) {
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
