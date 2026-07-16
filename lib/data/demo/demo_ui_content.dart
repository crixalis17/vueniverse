import 'package:flutter/material.dart';
import 'package:why_pulse/domain/models/app_models.dart';

/// Explicitly later capabilities are UI scope metadata, not a live source.
const expansionSources = <SourceData>[
  SourceData(
    id: 'screen',
    name: 'Screen time',
    description: 'Coarse device activity windows',
    contribution: 'Late activity and attention patterns',
    icon: Icons.phone_android_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'strava',
    name: 'Strava',
    description: 'Route-free workout timing and intensity',
    contribution: 'Exercise context and recovery comparisons',
    icon: Icons.directions_bike_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'media',
    name: 'Spotify',
    description: 'Coarse listening sessions',
    contribution: 'Media context around repeated moments',
    icon: Icons.headphones_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'wearables',
    name: 'Rings & wearables',
    description: 'Direct provider integrations',
    contribution: 'Additional physiology and recovery signals',
    icon: Icons.watch_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'fhir',
    name: 'Clinical records',
    description: 'FHIR import with explicit review',
    contribution: 'User-controlled clinical context',
    icon: Icons.medical_information_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'environment',
    name: 'Smart environment',
    description: 'Light, sound and room conditions',
    contribution: 'Environmental context without surveillance',
    icon: Icons.home_work_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
];
