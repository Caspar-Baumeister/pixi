import 'package:flutter/material.dart';

import '../core/theme.dart';

/// One selectable level of a map ("schlecht", "okay", "super" ...).
class MapLevel {
  const MapLevel({required this.label, required this.color});

  /// Either a localisation key (starts with `@`) or free text.
  final String label;
  final Color color;

  MapLevel copyWith({String? label, Color? color}) =>
      MapLevel(label: label ?? this.label, color: color ?? this.color);

  Map<String, dynamic> toJson() => {'label': label, 'color': colorToInt(color)};

  factory MapLevel.fromJson(Map<String, dynamic> j) => MapLevel(
        label: j['label'] as String,
        color: colorFromInt(j['color'] as int),
      );
}

/// A "map" is one thing the user tracks: mood, dreams, training ...
class PixMap {
  const PixMap({
    required this.id,
    required this.title,
    required this.question,
    required this.baseColor,
    required this.levels,
    this.catId = 'pixi',
    this.templateId = 'custom',
    this.category = 'custom',
    required this.createdAt,
  });

  final String id;

  /// Either a localisation key (`@mood`) or free text.
  final String title;

  /// Either a localisation key (`@q_mood`) or free text.
  final String question;

  /// Colour used for the glow behind the grid and the circle.
  final Color baseColor;
  final List<MapLevel> levels;
  final String catId;
  final String templateId;
  final String category;
  final DateTime createdAt;

  PixMap copyWith({
    String? title,
    String? question,
    Color? baseColor,
    List<MapLevel>? levels,
    String? catId,
    String? templateId,
    String? category,
  }) =>
      PixMap(
        id: id,
        title: title ?? this.title,
        question: question ?? this.question,
        baseColor: baseColor ?? this.baseColor,
        levels: levels ?? this.levels,
        catId: catId ?? this.catId,
        templateId: templateId ?? this.templateId,
        category: category ?? this.category,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'question': question,
        'baseColor': colorToInt(baseColor),
        'levels': levels.map((l) => l.toJson()).toList(),
        'catId': catId,
        'templateId': templateId,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PixMap.fromJson(Map<String, dynamic> j) => PixMap(
        id: j['id'] as String,
        title: j['title'] as String,
        question: j['question'] as String,
        baseColor: colorFromInt(j['baseColor'] as int),
        levels: (j['levels'] as List)
            .map((e) => MapLevel.fromJson(e as Map<String, dynamic>))
            .toList(),
        catId: (j['catId'] as String?) ?? 'pixi',
        templateId: (j['templateId'] as String?) ?? 'custom',
        category: (j['category'] as String?) ?? 'custom',
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}

/// User settings persisted with the data.
class Settings {
  const Settings({
    this.name = '',
    this.reminderHour = 8,
    this.reminderMinute = 30,
    this.remindersEnabled = false,
    this.onboardingDone = false,
    this.premium = false,
    this.feedbackAfterMapShown = false,
    this.feedbackAfterCheckinShown = false,
    this.lastCheckinDate = '',
    this.checkinCount = 0,
    this.reviewAfterStreakShown = false,
  });

  final String name;
  final int reminderHour;
  final int reminderMinute;
  final bool remindersEnabled;
  final bool onboardingDone;
  final bool premium;
  final bool feedbackAfterMapShown;
  final bool feedbackAfterCheckinShown;
  final String lastCheckinDate;
  final int checkinCount;

  /// The "how do you like Pixi" prompt after the first 3-day streak.
  final bool reviewAfterStreakShown;

  Settings copyWith({
    String? name,
    int? reminderHour,
    int? reminderMinute,
    bool? remindersEnabled,
    bool? onboardingDone,
    bool? premium,
    bool? feedbackAfterMapShown,
    bool? feedbackAfterCheckinShown,
    String? lastCheckinDate,
    int? checkinCount,
    bool? reviewAfterStreakShown,
  }) =>
      Settings(
        name: name ?? this.name,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        premium: premium ?? this.premium,
        feedbackAfterMapShown:
            feedbackAfterMapShown ?? this.feedbackAfterMapShown,
        feedbackAfterCheckinShown:
            feedbackAfterCheckinShown ?? this.feedbackAfterCheckinShown,
        lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
        checkinCount: checkinCount ?? this.checkinCount,
        reviewAfterStreakShown: reviewAfterStreakShown ?? this.reviewAfterStreakShown,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'remindersEnabled': remindersEnabled,
        'onboardingDone': onboardingDone,
        'premium': premium,
        'feedbackAfterMapShown': feedbackAfterMapShown,
        'feedbackAfterCheckinShown': feedbackAfterCheckinShown,
        'lastCheckinDate': lastCheckinDate,
        'checkinCount': checkinCount,
        'reviewAfterStreakShown': reviewAfterStreakShown,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        name: (j['name'] as String?) ?? '',
        reminderHour: (j['reminderHour'] as int?) ?? 8,
        reminderMinute: (j['reminderMinute'] as int?) ?? 30,
        remindersEnabled: (j['remindersEnabled'] as bool?) ?? false,
        onboardingDone: (j['onboardingDone'] as bool?) ?? false,
        premium: (j['premium'] as bool?) ?? false,
        feedbackAfterMapShown: (j['feedbackAfterMapShown'] as bool?) ?? false,
        feedbackAfterCheckinShown:
            (j['feedbackAfterCheckinShown'] as bool?) ?? false,
        lastCheckinDate: (j['lastCheckinDate'] as String?) ?? '',
        checkinCount: (j['checkinCount'] as int?) ?? 0,
        reviewAfterStreakShown: (j['reviewAfterStreakShown'] as bool?) ?? false,
      );
}

/// Whole persisted state.
class AppData {
  const AppData({
    required this.maps,
    required this.entries,
    required this.settings,
  });

  factory AppData.empty() =>
      const AppData(maps: [], entries: {}, settings: Settings());

  final List<PixMap> maps;

  /// mapId -> (yyyy-MM-dd -> level index)
  final Map<String, Map<String, int>> entries;
  final Settings settings;

  AppData copyWith({
    List<PixMap>? maps,
    Map<String, Map<String, int>>? entries,
    Settings? settings,
  }) =>
      AppData(
        maps: maps ?? this.maps,
        entries: entries ?? this.entries,
        settings: settings ?? this.settings,
      );

  Map<String, int> entriesFor(String mapId) => entries[mapId] ?? const {};

  Map<String, dynamic> toJson() => {
        'version': 1,
        'maps': maps.map((m) => m.toJson()).toList(),
        'entries': entries,
        'settings': settings.toJson(),
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final rawEntries = (j['entries'] as Map<String, dynamic>?) ?? {};
    final entries = <String, Map<String, int>>{};
    rawEntries.forEach((mapId, v) {
      final inner = <String, int>{};
      (v as Map<String, dynamic>).forEach((d, lvl) {
        inner[d] = (lvl as num).toInt();
      });
      entries[mapId] = inner;
    });
    return AppData(
      maps: ((j['maps'] as List?) ?? [])
          .map((e) => PixMap.fromJson(e as Map<String, dynamic>))
          .toList(),
      entries: entries,
      settings: Settings.fromJson(
          (j['settings'] as Map<String, dynamic>?) ?? const {}),
    );
  }
}
