import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/typography_preferences.dart';
import '../../services/personal_appearance_service.dart';

class PersonalAppearanceState {
  const PersonalAppearanceState(
      {this.value = TypographyPreferences.defaults,
      this.loading = true,
      this.ready = false,
      this.error});
  final TypographyPreferences value;
  final bool loading, ready;
  final String? error;
}

class PersonalAppearanceNotifier
    extends StateNotifier<PersonalAppearanceState> {
  PersonalAppearanceNotifier(this.userId, this.service)
      : super(const PersonalAppearanceState()) {
    _initialize();
  }
  final String userId;
  final PersonalAppearanceService service;
  String get _cacheKey => 'personal_typography_v1:$userId';
  bool _refreshing = false, _saving = false;
  int _generation = 0;

  Future<void> _initialize() async {
    try {
      final cache =
          (await SharedPreferences.getInstance()).getString(_cacheKey);
      if (mounted && state.loading && !state.ready && cache != null) {
        state = PersonalAppearanceState(
            value: TypographyPreferences.fromJson(
                Map<String, dynamic>.from(jsonDecode(cache) as Map)));
      }
    } catch (_) {/* A corrupt local cache never affects another account. */}
    if (mounted) await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing || _saving || !mounted) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final value = await service.load();
      if (!mounted || generation != _generation) return;
      state =
          PersonalAppearanceState(value: value, loading: false, ready: true);
      await _cache(value);
    } catch (_) {
      if (mounted && generation == _generation) {
        state = PersonalAppearanceState(
            value: state.value,
            loading: false,
            ready: state.ready,
            error: 'Could not sync your text sizes. Please try again.');
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> save(TypographyPreferences value) async {
    if (_saving) throw Exception('Your text sizes are already being saved.');
    _saving = true;
    _generation++;
    try {
      final saved = await service.save(value);
      if (!mounted) return;
      state =
          PersonalAppearanceState(value: saved, loading: false, ready: true);
      await _cache(saved);
    } finally {
      _saving = false;
    }
  }

  Future<void> _cache(TypographyPreferences value) async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_cacheKey, jsonEncode(value.toJson()));
    } catch (_) {/* Server save remains successful if local storage is full. */}
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}

final personalAppearanceServiceProvider = Provider.autoDispose
    .family<PersonalAppearanceService, String>(
        (ref, userId) => PersonalAppearanceService(userId));
final personalAppearanceProvider = StateNotifierProvider.autoDispose
    .family<PersonalAppearanceNotifier, PersonalAppearanceState, String>(
        (ref, userId) => PersonalAppearanceNotifier(
            userId, ref.watch(personalAppearanceServiceProvider(userId))));
