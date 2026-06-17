// songs.json → lib/src/data/score_data.dart の生成スクリプト(純 Dart)。
//
// 使い方(リポジトリ root から):
//   dart run docs/prototype/gen_score_data.dart
//   dart format lib/src/data/score_data.dart
//
// 変換ルール(README_scores.md と一致):
// - melody を順に並べ、拍位置は元の dur で積算(休符は拍の隙間で表す)。
// - 音価はアプリ許容6種(0.25/0.5/1/1.5/2/3)のみ。全音符 4 → 付点2分 3、
//   2.5 → 2分 2 に丸める(差分は休符)。
// - id をスラッグ化、origin 先頭を composer、timeSignature 分子を beatsPerMeasure、
//   tempo を defaultBpm にマッピング。
import 'dart:convert';
import 'dart:io';

const _slug = {
  'きらきら星': 'twinkle-star',
  'ちょうちょう': 'chouchou',
  'かえるの合唱': 'frog-round',
  'メリーさんの羊': 'mary-had-a-little-lamb',
  'ロンドン橋': 'london-bridge',
  'ゆかいなまきば': 'old-macdonald',
  '聖者の行進': 'when-the-saints',
  '茶色の小瓶': 'little-brown-jug',
  'アルプス一万尺': 'alps-ichimanjaku',
  'ジングルベル': 'jingle-bells',
  'きよしこの夜': 'silent-night',
};

double _roundDur(double d) {
  if (d == 4) return 3;
  if (d == 2.5) return 2;
  return d;
}

String _num(double x) =>
    x == x.truncateToDouble() ? x.toInt().toString() : x.toString();

String _constName(String slug) {
  final parts = slug.split('-');
  return '_${parts.first}${parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join()}';
}

void main() {
  final json =
      jsonDecode(File('docs/prototype/songs.json').readAsStringSync())
          as Map<String, Object?>;
  final songs = (json['songs'] as List).cast<Map<String, Object?>>();

  final b = StringBuffer();
  b.writeln("import '../domain/score/note.dart';");
  b.writeln("import '../domain/score/piece.dart';");
  b.writeln();
  b.writeln('/// 収録曲データ本体(ADR 0003: 同梱 Dart コード)。');
  b.writeln('///');
  b.writeln('/// すべて **パブリックドメイン**(著作権保護期間が満了)の童謡・唱歌・外国曲。');
  b.writeln('/// 旋律(`notes`)は手入力の**片手・単旋律**で、音域は練習鍵盤の C3–B5 に収める。');
  b.writeln('/// 両手フル譜面(`fullNotes`)は持たない(単旋律のため「両手のお手本」トグルは出ない)。');
  b.writeln('///');
  b.writeln(
    '/// このファイルは `docs/prototype/gen_score_data.dart` が `songs.json` から生成する。',
  );
  b.writeln('/// 直接編集せず、`songs.json` を直してから再生成する。音価は許容6種(16分=0.25 /');
  b.writeln('/// 8分=0.5 / 4分=1 / 付点4分=1.5 / 2分=2 / 付点2分=3)のみ。元データの全音符(4)は');
  b.writeln('/// 付点2分(3)、2.5 は2分(2)へ丸め、差分は休符(拍の隙間)で表す。拍位置は元の音価で積算。');
  b.writeln('/// contract test が音名・音価・音域・id 一意を守る。');

  final pieceMeta = <Map<String, Object?>>[];

  for (final song in songs) {
    final title = song['title'] as String;
    final slug = _slug[title]!;
    final origin = song['origin'] as String;
    final composer = origin.split(' (').first.trim();
    final ts = song['timeSignature'] as String;
    final bpm = (song['tempo'] as num).toInt();
    final beatsPerMeasure = int.parse(ts.split('/').first);
    final melody = (song['melody'] as List).cast<Map<String, Object?>>();

    final constName = _constName(slug);
    b.writeln();
    b.writeln('// $title($origin)。$ts, tempo=$bpm。');
    b.writeln('const List<Note> $constName = [');
    var beat = 0.0;
    for (final n in melody) {
      final pitch = n['note'] as String;
      final orig = (n['dur'] as num).toDouble();
      final dur = _roundDur(orig);
      b.writeln(
        "  Note(pitch: '$pitch', beat: ${_num(beat)}, duration: ${_num(dur)}),",
      );
      beat += orig; // 休符を保つため拍位置は元の音価で進める。
    }
    b.writeln('];');

    pieceMeta.add({
      'id': song['id'] == 'featured' ? 'twinkle-star' : slug,
      'title': title,
      'composer': composer,
      'beatsPerMeasure': beatsPerMeasure,
      'bpm': bpm,
      'const': constName,
      'featured': song['id'] == 'featured',
    });
  }

  final featured = pieceMeta.firstWhere((m) => m['featured'] == true);
  final samples = pieceMeta.where((m) => m['featured'] != true).toList();

  b.writeln();
  b.writeln('/// 起動時に編集タブの既定で開く代表曲(featured)。');
  b.writeln('Piece buildFeaturedPiece() => Piece(');
  b.writeln("  id: '${featured['id']}',");
  b.writeln("  title: '${featured['title']}',");
  b.writeln("  composer: '${featured['composer']}',");
  b.writeln('  beatsPerMeasure: ${featured['beatsPerMeasure']},');
  b.writeln('  defaultBpm: ${featured['bpm']},');
  b.writeln('  notes: List<Note>.of(${featured['const']}),');
  b.writeln(');');
  b.writeln();
  b.writeln('/// 既定でシードする収録曲(featured を除く)。すべてパブリックドメインの童謡・唱歌。');
  b.writeln('List<Piece> buildSamplePieces() => [');
  for (final m in samples) {
    b.writeln('  Piece(');
    b.writeln("    id: '${m['id']}',");
    b.writeln("    title: '${m['title']}',");
    b.writeln("    composer: '${m['composer']}',");
    b.writeln('    beatsPerMeasure: ${m['beatsPerMeasure']},');
    b.writeln('    defaultBpm: ${m['bpm']},');
    b.writeln('    notes: List<Note>.of(${m['const']}),');
    b.writeln('  ),');
  }
  b.writeln('];');

  File('lib/src/data/score_data.dart').writeAsStringSync(b.toString());
  stdout.writeln('generated lib/src/data/score_data.dart');
}
