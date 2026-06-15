// ignore_for_file: avoid_print
// もらった bundled_scores.json(両手・自由リズムのフル譜)を、アプリの
// 「簡易・弾ける」制約に後処理して Dart の const Note 配列として出力する一回限りツール。
//
//   dart docs/prototype/convert_scores.dart
//
// 後処理: 上声メロディ抽出(しきい値で左手バスを除外)→ onset/音価を量子化 →
//        音域 C3–B5 に折込み → 約 60 秒に整形。BWV846 は分散和音そのものなので
//        しきい値なし(全音を一列に)で処理する。
import 'dart:convert';
import 'dart:io';

const allowed = <double>[0.25, 0.5, 1, 1.5, 2, 3];
const sharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// ピアノ域(A0=21 〜 C8=108)。これ以外(MIDI 由来の異常音・サブ音)はスキップする。
const int loMidi = 21, hiMidi = 108;

int midiOf(String pitch) {
  final m = RegExp(r'^([A-G])(#?)(-?\d+)$').firstMatch(pitch);
  if (m == null) return -1; // 想定外表記はスキップ対象。
  const base = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final semi = base[m.group(1)]! + (m.group(2) == '#' ? 1 : 0);
  final oct = int.parse(m.group(3)!);
  return (oct + 1) * 12 + semi;
}

String nameOf(int midi) {
  final oct = midi ~/ 12 - 1;
  return '${sharp[midi % 12]}$oct';
}

double snapGrid(double v, double grid) => (v / grid).round() * grid;

double snapDur(double d) {
  var best = allowed.first;
  var bestErr = (d - best).abs();
  for (final a in allowed) {
    final e = (d - a).abs();
    if (e < bestErr) {
      best = a;
      bestErr = e;
    }
  }
  return best;
}

int fold(int midi) {
  var m = midi;
  while (m > 83) {
    m -= 12; // B5
  }
  while (m < 48) {
    m += 12; // C3
  }
  return m;
}

class Cfg {
  Cfg(this.id, this.varName, this.thresholdMidi, this.bpMeas, this.bpm);
  final String id;
  final String varName; // 出力する Dart const 変数名
  final int? thresholdMidi; // null = しきい値なし(全音保持)
  final int bpMeas;
  final int bpm;
}

const double maxGap = 2; // この拍数を超える休符(伴奏のみの区間)は詰める。

void main() {
  final raw = File('docs/prototype/bundled_scores.json').readAsStringSync();
  final data = jsonDecode(raw) as Map<String, Object?>;
  final pieces = (data['pieces'] as List).cast<Map<String, Object?>>();

  // (giftId, 変数名, 単旋律抽出しきい値(MIDI; null=全音保持), 拍子(整数), 既定BPM)
  final cfgs = [
    Cfg('fuer_elise', '_furElise', 60, 3, 76),
    Cfg('minuet_g', '_minuet', 60, 3, 120),
    Cfg('mozart_k545_1', '_sonataFacile', 60, 4, 120),
    Cfg('gymnopedie_1', '_gymnopedie', 67, 3, 66),
    Cfg('ode_to_joy', '_odeToJoy', 60, 4, 100),
    Cfg('burgmuller_arabesque', '_burgmullerArabesque', 60, 2, 108),
    Cfg('beethoven_moonlight_1', '_moonlight1', 67, 4, 52),
    Cfg('chopin_nocturne_9_2', '_nocturne', 62, 4, 56),
    Cfg('chopin_prelude_e_minor', '_preludeEMinor', 68, 4, 56),
    Cfg('debussy_clair_de_lune', '_clairDeLune', 60, 3, 56),
    Cfg('debussy_arabesque_1', '_debussyArabesque', 60, 4, 92),
    Cfg('pachelbel_canon', '_canon', 60, 4, 80),
    Cfg('bach_prelude_c', '_bwv846', null, 4, 72),
    Cfg('schubert_ave_maria', '_aveMaria', 64, 4, 56),
    Cfg('joplin_entertainer', '_entertainer', 64, 2, 90),
    Cfg('chopin_fantaisie_impromptu', '_fantaisieImpromptu', 64, 4, 80),
    Cfg('chopin_minute_waltz', '_minuteWaltz', 64, 3, 126),
    Cfg('beethoven_moonlight_3', '_moonlight3', 60, 4, 120),
  ];

  for (final cfg in cfgs) {
    final piece = pieces.firstWhere((p) => p['id'] == cfg.id);
    final notes = (piece['notes'] as List).cast<Map<String, Object?>>();

    // 1) しきい値で左手バスを除外し、(snappedOnset -> 最高音)に集約。
    final byOnset = <double, ({int midi, double dur})>{};
    for (final n in notes) {
      final midi = midiOf(n['pitch'] as String);
      if (midi < loMidi || midi > hiMidi) continue; // 域外/異常音はスキップ。
      if (cfg.thresholdMidi != null && midi < cfg.thresholdMidi!) continue;
      final onset = snapGrid((n['beat'] as num).toDouble(), 0.25);
      final dur = snapDur((n['duration'] as num).toDouble());
      final cur = byOnset[onset];
      if (cur == null || midi > cur.midi) {
        byOnset[onset] = (midi: fold(midi), dur: dur);
      }
    }

    // 2) 約 60 秒 = bpm 拍ぶんに整形(小節頭で切る)。
    final targetBeats = (cfg.bpm.toDouble() / cfg.bpMeas).floor() * cfg.bpMeas;
    final onsets = byOnset.keys.where((b) => b < targetBeats).toList()..sort();

    // 3) 先頭を 0 に寄せ、長い休符(伴奏のみの区間)を maxGap に詰めて連続的に。
    final buf = StringBuffer();
    var lo = 200, hi = 0, count = 0;
    double cursor = 0;
    double? prevIn;
    for (final inBeat in onsets) {
      final e = byOnset[inBeat]!;
      if (prevIn != null) {
        var gap = inBeat - prevIn;
        if (gap > maxGap) gap = maxGap;
        cursor += gap;
      }
      prevIn = inBeat;
      final out = (cursor / 0.25).round() * 0.25;
      final beatStr = out == out.roundToDouble()
          ? out.toInt().toString()
          : '$out';
      buf.writeln(
        "  Note(pitch: '${nameOf(e.midi)}', beat: $beatStr, duration: ${e.dur}),",
      );
      if (e.midi < lo) lo = e.midi;
      if (e.midi > hi) hi = e.midi;
      count++;
    }
    print(
      '// ${cfg.id}: $count notes, ${nameOf(lo)}-${nameOf(hi)}, '
      'beatsPerMeasure=${cfg.bpMeas}, defaultBpm=${cfg.bpm}',
    );
    print('const List<Note> ${cfg.varName} = [');
    print(buf.toString().trimRight());
    print('];');
    print('');
  }

  // 両手フル版(_xxxFull): しきい値・音域折込みなしで全音を保持(大譜表/両手再生用)。
  for (final cfg in cfgs) {
    final piece = pieces.firstWhere((p) => p['id'] == cfg.id);
    final notes = (piece['notes'] as List).cast<Map<String, Object?>>();
    final targetBeats = (cfg.bpm.toDouble() / cfg.bpMeas).floor() * cfg.bpMeas;
    final seen = <String>{};
    final full = <({double beat, int midi, double dur})>[];
    for (final n in notes) {
      final onset = snapGrid((n['beat'] as num).toDouble(), 0.25);
      if (onset >= targetBeats) continue;
      final midi = midiOf(n['pitch'] as String);
      if (midi < loMidi || midi > hiMidi) continue; // 域外/異常音はスキップ。
      final dur = snapDur((n['duration'] as num).toDouble());
      if (seen.add('$onset:$midi')) {
        full.add((beat: onset, midi: midi, dur: dur));
      }
    }
    full.sort((a, b) {
      final c = a.beat.compareTo(b.beat);
      return c != 0 ? c : a.midi.compareTo(b.midi);
    });
    final shift = full.isEmpty ? 0.0 : full.first.beat;
    var lo = 200, hi = 0;
    final body = StringBuffer();
    for (final e in full) {
      final b = e.beat - shift;
      final bs = b == b.roundToDouble() ? b.toInt().toString() : '$b';
      body.writeln(
        "  Note(pitch: '${nameOf(e.midi)}', beat: $bs, duration: ${e.dur}),",
      );
      if (e.midi < lo) lo = e.midi;
      if (e.midi > hi) hi = e.midi;
    }
    print(
      '// ${cfg.id} full: ${full.length} notes, ${nameOf(lo)}-${nameOf(hi)}',
    );
    print('const List<Note> ${cfg.varName}Full = [');
    print(body.toString().trimRight());
    print('];');
    print('');
  }
}
