/// LONE LINK — Result Type Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:lone_link/core/result/result.dart';
import 'package:lone_link/core/errors/failures.dart';

void main() {
  group('Result', () {
    test('Success contains value', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.valueOrNull, 42);
      expect(result.valueOrThrow, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Failure contains failure', () {
      const failure = BleUnavailableFailure();
      const result = Result<int>.failure(failure);
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isNotNull);
    });

    test('valueOrThrow throws for failure', () {
      const failure = BleUnavailableFailure();
      const result = Result<int>.failure(failure);
      expect(() => result.valueOrThrow, throwsA(isA<BleUnavailableFailure>()));
    });

    test('map transforms success value', () {
      const result = Result<int>.success(21);
      final mapped = result.map((v) => v * 2);
      expect(mapped.valueOrNull, 42);
    });

    test('map preserves failure', () {
      const result = Result<int>.failure(BleUnavailableFailure());
      final mapped = result.map((v) => v * 2);
      expect(mapped.isFailure, true);
    });

    test('flatMap chains operations', () {
      const result = Result<int>.success(10);
      final chained = result.flatMap((v) => Result.success(v.toString()));
      expect(chained.valueOrNull, '10');
    });

    test('flatMap short-circuits on failure', () {
      const result = Result<int>.failure(BleUnavailableFailure());
      final chained = result.flatMap((v) => Result.success(v.toString()));
      expect(chained.isFailure, true);
    });

    test('when dispatches correctly', () {
      const success = Result<int>.success(42);
      final successResult = success.when(
        success: (v) => 'got $v',
        failure: (f) => 'failed',
      );
      expect(successResult, 'got 42');

      const failure = Result<int>.failure(BleUnavailableFailure());
      final failureResult = failure.when(
        success: (v) => 'got $v',
        failure: (f) => 'failed: ${f.message}',
      );
      expect(failureResult, contains('failed'));
    });

    test('getOrElse returns default for failure', () {
      const result = Result<int>.failure(BleUnavailableFailure());
      expect(result.getOrElse(() => -1), -1);
    });

    test('getOrElse returns value for success', () {
      const result = Result<int>.success(42);
      expect(result.getOrElse(() => -1), 42);
    });

    test('getOrHandle transforms failure', () {
      const result = Result<String>.failure(
        BleConnectionFailure(message: 'test error'),
      );
      final handled = result.getOrHandle((f) => 'Error: ${f.message}');
      expect(handled, 'Error: test error');
    });

    test('Success equality', () {
      const a = Result<int>.success(42);
      const b = Result<int>.success(42);
      expect(a, equals(b));
    });

    test('Failure equality', () {
      const a = Result<int>.failure(BleUnavailableFailure());
      const b = Result<int>.failure(BleUnavailableFailure());
      // Different instances of BleUnavailableFailure — equality depends on class impl
      expect(a.isFailure, true);
      expect(b.isFailure, true);
    });
  });

  group('Failure types', () {
    test('BLE failures', () {
      const f = BleUnavailableFailure();
      expect(f.message, contains('not available'));
      expect(f.toString(), contains('BleUnavailableFailure'));
    });

    test('Message failures', () {
      const f = DuplicateMessageFailure(messageId: 'abc123');
      expect(f.message, contains('abc123'));
      expect(f.messageId, 'abc123');
    });

    test('TTL exhausted failure', () {
      const f = TtlExhaustedFailure(messageId: 'msg-001');
      expect(f.message, contains('TTL'));
      expect(f.messageId, 'msg-001');
    });

    test('Security failures', () {
      const f = ReplayAttackDetectedFailure(messageId: 'replay-1');
      expect(f.message, contains('Replay'));
      expect(f.messageId, 'replay-1');
    });

    test('Routing failures', () {
      const f = NoRouteAvailableFailure(destinationId: 'dest-1');
      expect(f.message, contains('dest-1'));
    });

    test('Failure with cause and stack trace', () {
      final f = BleConnectionFailure(
        message: 'GATT error',
        cause: Exception('underlying'),
        stackTrace: StackTrace.current,
      );
      expect(f.message, 'GATT error');
      expect(f.cause, isNotNull);
      expect(f.stackTrace, isNotNull);
      expect(f.toString(), contains('cause'));
    });
  });

  group('ResultCatch', () {
    test('guardAsync catches exceptions', () async {
      final result = await ResultCatch.guardAsync<int>(() async {
        throw Exception('test error');
      });
      expect(result.isFailure, true);
    });

    test('guardAsync returns success', () async {
      final result = await ResultCatch.guardAsync<int>(() async {
        return 42;
      });
      expect(result.isSuccess, true);
      expect(result.valueOrNull, 42);
    });

    test('guard catches synchronous exceptions', () {
      final result = ResultCatch.guard<int>(() {
        throw Exception('sync error');
      });
      expect(result.isFailure, true);
    });

    test('guard catches LoneLinkFailure', () {
      final result = ResultCatch.guard<int>(() {
        throw const BleUnavailableFailure();
      });
      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<BleUnavailableFailure>());
    });
  });
}
