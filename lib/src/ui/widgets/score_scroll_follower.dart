import 'package:flutter/widgets.dart';

/// 譜面の横スクロールと「再生ヘッド追従」をまとめて扱うヘルパ。
///
/// 再生/試聴中は再生ヘッドが見切れたら中央へ自動スクロールする。ただし
/// ユーザーが手動でドラッグしたら追従を一時停止し([wrap] が検知)、次の
/// 再生/試聴開始で [resume] により復帰する。練習画面・エディタ試聴の両方が使う。
class ScoreScrollFollower {
  /// 譜面の横スクロール制御。`SingleChildScrollView` などへ渡す。
  final ScrollController controller = ScrollController();

  /// ユーザーの手動スクロールで追従を一時停止しているか。
  bool _paused = false;
  bool _disposed = false;

  /// 再生/試聴の開始時に呼ぶ。手動スクロールで止めた追従を復帰させる。
  void resume() => _paused = false;

  void dispose() {
    _disposed = true;
    controller.dispose();
  }

  /// スクロール領域 [child] を包み、手動ドラッグを検知して追従を止める。
  /// 開始通知で取りこぼす端末もあるため、ドラッグ中の更新通知でも拾う。
  Widget wrap(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (isUserDrag(n)) _paused = true;
        return false;
      },
      child: child,
    );
  }

  /// 再生ヘッド([targetX] の x)が見切れていれば中央へスクロールして追従する。
  /// [isActive] が false・手動スクロール中・破棄後は何もしない。予約後に状態が
  /// 変わる(手動スクロール・停止)ことがあるため postFrame でも再判定する。
  void follow({
    required bool Function() isActive,
    required double Function() targetX,
  }) {
    if (_disposed || _paused || !isActive()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || _paused || !isActive() || !controller.hasClients) return;
      final x = targetX();
      final pos = controller.position;
      if (x < pos.pixels + 40 || x > pos.pixels + pos.viewportDimension - 40) {
        controller.animateTo(
          (x - pos.viewportDimension * 0.5).clamp(0.0, pos.maxScrollExtent),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ユーザーの手動ドラッグ由来のスクロール通知か(プログラムの追従は除く)。
  /// `dragDetails` はユーザー操作でのみ非 null。開始/更新の両方で見る。
  static bool isUserDrag(ScrollNotification n) =>
      (n is ScrollStartNotification && n.dragDetails != null) ||
      (n is ScrollUpdateNotification && n.dragDetails != null);
}
