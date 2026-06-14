import 'package:etude/src/core/clock.dart';

/// 固定時刻から手動でのみ進む clock。テストで実時間に依存させないために使う。
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// 時刻を進める。
  void advance(Duration duration) => _now = _now.add(duration);

  /// 時刻を任意の値にセットする。
  void set(DateTime value) => _now = value;
}
