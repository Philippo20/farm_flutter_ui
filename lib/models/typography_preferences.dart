import 'package:flutter/material.dart';

/// Multipliers keep the shared font scale and the device's accessibility sizes.
@immutable
class TypographyPreferences {
  const TypographyPreferences(
      {this.headings = 1, this.titles = 1, this.body = 1, this.labels = 1});
  final double headings, titles, body, labels;
  static const defaults = TypographyPreferences();

  factory TypographyPreferences.fromJson(Map<String, dynamic> json) {
    double value(String key) {
      final number = json[key];
      return number is num && number.isFinite && number >= .85 && number <= 1.35
          ? number.toDouble()
          : 1;
    }

    return TypographyPreferences(
        headings: value('headings'),
        titles: value('titles'),
        body: value('body'),
        labels: value('labels'));
  }
  Map<String, dynamic> toJson() =>
      {'headings': headings, 'titles': titles, 'body': body, 'labels': labels};
  TypographyPreferences withValue(String key, double value) =>
      TypographyPreferences.fromJson({...toJson(), key: value});
  double factor(double fontSize) => fontSize >= 24
      ? headings
      : fontSize >= 16
          ? titles
          : fontSize > 12
              ? body
              : labels;
  @override
  bool operator ==(Object other) =>
      other is TypographyPreferences &&
      headings == other.headings &&
      titles == other.titles &&
      body == other.body &&
      labels == other.labels;
  @override
  int get hashCode => Object.hash(headings, titles, body, labels);
}

class PersonalTextScaler extends TextScaler {
  const PersonalTextScaler(this.preferences, this.system);
  final TypographyPreferences preferences;
  final TextScaler system;
  @override
  double scale(double fontSize) =>
      system.scale(fontSize) * preferences.factor(fontSize);
  @override
  double get textScaleFactor => scale(14) / 14;
  @override
  bool operator ==(Object other) =>
      other is PersonalTextScaler &&
      preferences == other.preferences &&
      system == other.system;
  @override
  int get hashCode => Object.hash(preferences, system);
}

TextScaler systemTextScalerOf(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  return scaler is PersonalTextScaler ? scaler.system : scaler;
}
