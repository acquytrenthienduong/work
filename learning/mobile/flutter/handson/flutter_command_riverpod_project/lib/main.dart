import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';

void main() {
  // Initialize logger
  AppLogger.init();
  
  runApp(
    ProviderScope(
      observers: [
        AppProviderObserver(),
      ],
      child: const MyApp(),
    ),
  );
}

class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.logger.d(
      'Provider ${provider.name ?? provider.runtimeType} updated: '
      '$previousValue -> $newValue',
    );
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.logger.e(
      'Provider ${provider.name ?? provider.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
} 