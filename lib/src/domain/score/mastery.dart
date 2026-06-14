/// 習得度(0–100)の更新ルール(pure Dart)。
///
/// プロトタイプは固定値表示のみだった。本実装では「1 回弾き切るごとに一定値ずつ
/// 上がり、100 で頭打ち」という単純な規則にする。要件が詳細化したら見直す。
abstract final class Mastery {
  /// 1 回の練習完了で上がる習得度。
  static const int practiceStep = 12;

  /// 練習を 1 回弾き切ったあとの習得度。
  static int afterPractice(int current) =>
      (current + practiceStep).clamp(0, 100);
}
