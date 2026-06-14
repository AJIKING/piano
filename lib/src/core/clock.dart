/// 現在時刻の供給境界。テストでは fake に差し替える。
/// アプリコードで `DateTime.now()` を直接呼ばず、必ずこの境界を経由する。
abstract interface class Clock {
  DateTime now();
}

/// システム時刻を返す本番実装。
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
