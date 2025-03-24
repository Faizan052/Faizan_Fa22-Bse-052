// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'7cd30c9640ca952d1bcf1772c709fc45dc47c8b3';

/// See also [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider =
AutoDisposeFutureProvider<SharedPreferences>.internal(
  sharedPreferences,
  name: r'sharedPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = AutoDisposeFutureProviderRef<SharedPreferences>;
String _$settingsHash() => r'4354412e47400826428517024f0816a5210a8ce8';

/// See also [Settings].
@ProviderFor(Settings)
final settingsProvider =
AutoDisposeAsyncNotifierProvider<Settings, SettingsState>.internal(
  Settings.new,
  name: r'settingsProvider',
  debugGetCreateSourceHash:
  const bool.fromEnvironment('dart.vm.product') ? null : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Settings = AutoDisposeAsyncNotifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package