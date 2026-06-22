import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerService {
  AccelerometerService({
    this.faceDownThreshold = -8.0,
    this.maxSideTilt = 4.0,
    this.samplingPeriod = SensorInterval.normalInterval,
  });

  final double faceDownThreshold;
  final double maxSideTilt;
  final Duration samplingPeriod;

  StreamSubscription<bool>? _subscription;

  Stream<bool> get focusModeStream {
    return accelerometerEventStream(samplingPeriod: samplingPeriod)
        .map(isPhoneFaceDown)
        .distinct();
  }

  Future<void> startListening({
    required void Function(bool isFocusMode) onChanged,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    await stopListening();
    _subscription = focusModeStream.listen(
      onChanged,
      onError: onError,
      cancelOnError: false,
    );
  }

  bool isPhoneFaceDown(AccelerometerEvent event) {
    final hasNegativeZ = event.z <= faceDownThreshold;
    final isFlatEnough =
        event.x.abs() <= maxSideTilt && event.y.abs() <= maxSideTilt;
    return hasNegativeZ && isFlatEnough;
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() {
    return stopListening();
  }
}
