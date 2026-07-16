import 'package:flutter/material.dart';

enum AppMode { live, demo }

enum FeatureTier { core, preview, later }

enum SourceStatus { connected, available, limited, paused, unavailable }

enum ExperimentStatus { draft, active, paused, completed, invalidated }

enum ExperimentOutcome { strengthened, weakened, unchanged, inconclusive }

class SourceData {
  const SourceData({
    required this.id,
    required this.name,
    required this.description,
    required this.contribution,
    required this.icon,
    required this.status,
    required this.tier,
    this.lastSync,
    this.completeness = 0,
  });

  final String id;
  final String name;
  final String description;
  final String contribution;
  final IconData icon;
  final SourceStatus status;
  final FeatureTier tier;
  final String? lastSync;
  final int completeness;

  SourceData copyWith({
    SourceStatus? status,
    String? lastSync,
    int? completeness,
  }) {
    return SourceData(
      id: id,
      name: name,
      description: description,
      contribution: contribution,
      icon: icon,
      status: status ?? this.status,
      tier: tier,
      lastSync: lastSync ?? this.lastSync,
      completeness: completeness ?? this.completeness,
    );
  }
}

class CheckInData {
  const CheckInData({
    required this.id,
    required this.when,
    required this.context,
    required this.detail,
    required this.icon,
  });

  final String id;
  final DateTime when;
  final String context;
  final String detail;
  final IconData icon;
}

class ChatMessageData {
  const ChatMessageData({
    required this.text,
    required this.fromUser,
    this.evidence = const [],
    this.uncertainty,
  });

  final String text;
  final bool fromUser;
  final List<String> evidence;
  final String? uncertainty;
}

class HistoryItemData {
  const HistoryItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.icon,
    required this.accent,
    this.invalidated = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String status;
  final IconData icon;
  final Color accent;
  final bool invalidated;
}

class EvidenceFact {
  const EvidenceFact({
    required this.label,
    required this.value,
    required this.detail,
    required this.source,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final String source;
  final Color accent;
}
