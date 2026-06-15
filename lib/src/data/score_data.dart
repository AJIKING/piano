import '../domain/score/note.dart';
import '../domain/score/piece.dart';

/// 収録曲データ本体(ADR 0003: 同梱 Dart コード)。
///
/// すべてパブリックドメイン(著作権切れ)の名曲。譜面は**主旋律の簡易アレンジ**で、
/// このアプリの制約に合わせている:
/// - 音名は ♯ のみ(♭ は使わない。例: B♭ → A♯、E♭ → D♯)。
/// - 音価は 16分(0.25)/ 8分(0.5)/ 4分(1)/ 付点4分(1.5)/ 2分(2)/ 付点2分(3)の
///   6 種。全音符は無いため、長い音は最大 3 拍で近似する。
/// - 音域は鍵盤(C3〜B5)に収める。三連符・装飾・左手伴奏は持たない。
/// - 拍子・既定テンポは曲ごとに [Piece.beatsPerMeasure] / [Piece.defaultBpm] で持つ。
///
/// 旋律主体の曲(エリーゼ/メヌエット/歓喜の歌/朝/エンターテイナー 等)はほぼ忠実、
/// 分散和音・速い走句・左手が本質の曲(月光/幻想即興曲/カノン/BWV846 等)は
/// 主旋律1本への簡略版になる。contract test が音名・音価・音域・id 一意を守る。
///
/// 並び順は 初級 → 中級 → 上級(ライブラリはこの順のフラット一覧)。

// ───────────────────── 初級 ─────────────────────

// エリーゼのために(ベートーヴェン)イ短調。featured(看板曲)。
const List<Note> _furElise = [
  Note(pitch: 'E5', beat: 0, duration: 0.5),
  Note(pitch: 'D#5', beat: 0.5, duration: 0.5),
  Note(pitch: 'E5', beat: 1, duration: 0.5),
  Note(pitch: 'D#5', beat: 1.5, duration: 0.5),
  Note(pitch: 'E5', beat: 2, duration: 0.5),
  Note(pitch: 'B4', beat: 2.5, duration: 0.5),
  Note(pitch: 'D5', beat: 3, duration: 0.5),
  Note(pitch: 'C5', beat: 3.5, duration: 0.5),
  Note(pitch: 'A4', beat: 4, duration: 1),
  Note(pitch: 'C4', beat: 5, duration: 0.5),
  Note(pitch: 'E4', beat: 5.5, duration: 0.5),
  Note(pitch: 'A4', beat: 6, duration: 0.5),
  Note(pitch: 'B4', beat: 6.5, duration: 1),
  Note(pitch: 'E4', beat: 7.5, duration: 0.5),
  Note(pitch: 'G#4', beat: 8, duration: 0.5),
  Note(pitch: 'B4', beat: 8.5, duration: 0.5),
  Note(pitch: 'C5', beat: 9, duration: 1),
  Note(pitch: 'E5', beat: 10, duration: 0.5),
  Note(pitch: 'D#5', beat: 10.5, duration: 0.5),
  Note(pitch: 'E5', beat: 11, duration: 0.5),
  Note(pitch: 'D#5', beat: 11.5, duration: 0.5),
  Note(pitch: 'E5', beat: 12, duration: 0.5),
  Note(pitch: 'B4', beat: 12.5, duration: 0.5),
  Note(pitch: 'D5', beat: 13, duration: 0.5),
  Note(pitch: 'C5', beat: 13.5, duration: 0.5),
  Note(pitch: 'A4', beat: 14, duration: 2),
];

// メヌエット ト長調(ペツォールト、旧 J.S.バッハ作)ト長調・3/4。
const List<Note> _minuet = [
  Note(pitch: 'D5', beat: 0, duration: 1),
  Note(pitch: 'G4', beat: 1, duration: 0.5),
  Note(pitch: 'A4', beat: 1.5, duration: 0.5),
  Note(pitch: 'B4', beat: 2, duration: 0.5),
  Note(pitch: 'C5', beat: 2.5, duration: 0.5),
  Note(pitch: 'D5', beat: 3, duration: 1),
  Note(pitch: 'G4', beat: 4, duration: 1),
  Note(pitch: 'G4', beat: 5, duration: 1),
  Note(pitch: 'E5', beat: 6, duration: 1),
  Note(pitch: 'C5', beat: 7, duration: 0.5),
  Note(pitch: 'D5', beat: 7.5, duration: 0.5),
  Note(pitch: 'E5', beat: 8, duration: 0.5),
  Note(pitch: 'F#5', beat: 8.5, duration: 0.5),
  Note(pitch: 'G5', beat: 9, duration: 1),
  Note(pitch: 'G4', beat: 10, duration: 1),
  Note(pitch: 'G4', beat: 11, duration: 1),
  Note(pitch: 'C5', beat: 12, duration: 1),
  Note(pitch: 'B4', beat: 13, duration: 1),
  Note(pitch: 'A4', beat: 14, duration: 1),
  Note(pitch: 'G4', beat: 15, duration: 1),
  Note(pitch: 'A4', beat: 16, duration: 1),
  Note(pitch: 'D5', beat: 17, duration: 2),
];

// ピアノソナタ K.545 第1楽章(モーツァルト)ハ長調・4/4。簡易アレンジ。
const List<Note> _sonataFacile = [
  Note(pitch: 'C5', beat: 0, duration: 1),
  Note(pitch: 'E5', beat: 1, duration: 1),
  Note(pitch: 'G5', beat: 2, duration: 1),
  Note(pitch: 'B4', beat: 3, duration: 0.5),
  Note(pitch: 'C5', beat: 3.5, duration: 0.5),
  Note(pitch: 'A4', beat: 4, duration: 1),
  Note(pitch: 'D5', beat: 5, duration: 1),
  Note(pitch: 'B4', beat: 6, duration: 0.5),
  Note(pitch: 'C5', beat: 6.5, duration: 0.5),
  Note(pitch: 'D5', beat: 7, duration: 1),
  Note(pitch: 'E5', beat: 8, duration: 1),
  Note(pitch: 'G5', beat: 9, duration: 1),
  Note(pitch: 'F5', beat: 10, duration: 0.5),
  Note(pitch: 'E5', beat: 10.5, duration: 0.5),
  Note(pitch: 'D5', beat: 11, duration: 1),
  Note(pitch: 'C5', beat: 12, duration: 2),
];

// ジムノペディ 第1番(サティ)ニ長調・3/4。簡易アレンジ。
const List<Note> _gymnopedie = [
  Note(pitch: 'F#5', beat: 0, duration: 3),
  Note(pitch: 'G5', beat: 3, duration: 2),
  Note(pitch: 'F#5', beat: 5, duration: 1),
  Note(pitch: 'E5', beat: 6, duration: 3),
  Note(pitch: 'D5', beat: 9, duration: 2),
  Note(pitch: 'C#5', beat: 11, duration: 1),
  Note(pitch: 'B4', beat: 12, duration: 3),
  Note(pitch: 'A4', beat: 15, duration: 2),
  Note(pitch: 'B4', beat: 17, duration: 1),
  Note(pitch: 'C#5', beat: 18, duration: 3),
  Note(pitch: 'D5', beat: 21, duration: 3),
];

// 歓喜の歌(第九 / ベートーヴェン)ハ長調・4/4。
const List<Note> _odeToJoy = [
  Note(pitch: 'E4', beat: 0, duration: 1),
  Note(pitch: 'E4', beat: 1, duration: 1),
  Note(pitch: 'F4', beat: 2, duration: 1),
  Note(pitch: 'G4', beat: 3, duration: 1),
  Note(pitch: 'G4', beat: 4, duration: 1),
  Note(pitch: 'F4', beat: 5, duration: 1),
  Note(pitch: 'E4', beat: 6, duration: 1),
  Note(pitch: 'D4', beat: 7, duration: 1),
  Note(pitch: 'C4', beat: 8, duration: 1),
  Note(pitch: 'C4', beat: 9, duration: 1),
  Note(pitch: 'D4', beat: 10, duration: 1),
  Note(pitch: 'E4', beat: 11, duration: 1),
  Note(pitch: 'E4', beat: 12, duration: 1.5),
  Note(pitch: 'D4', beat: 13.5, duration: 0.5),
  Note(pitch: 'D4', beat: 14, duration: 2),
  Note(pitch: 'E4', beat: 16, duration: 1),
  Note(pitch: 'E4', beat: 17, duration: 1),
  Note(pitch: 'F4', beat: 18, duration: 1),
  Note(pitch: 'G4', beat: 19, duration: 1),
  Note(pitch: 'G4', beat: 20, duration: 1),
  Note(pitch: 'F4', beat: 21, duration: 1),
  Note(pitch: 'E4', beat: 22, duration: 1),
  Note(pitch: 'D4', beat: 23, duration: 1),
  Note(pitch: 'C4', beat: 24, duration: 1),
  Note(pitch: 'C4', beat: 25, duration: 1),
  Note(pitch: 'D4', beat: 26, duration: 1),
  Note(pitch: 'E4', beat: 27, duration: 1),
  Note(pitch: 'D4', beat: 28, duration: 1.5),
  Note(pitch: 'C4', beat: 29.5, duration: 0.5),
  Note(pitch: 'C4', beat: 30, duration: 2),
];

// アラベスク(ブルクミュラー 25の練習曲 Op.100-2)イ短調・2/4。
const List<Note> _burgmullerArabesque = [
  Note(pitch: 'A4', beat: 0, duration: 0.25),
  Note(pitch: 'C5', beat: 0.25, duration: 0.25),
  Note(pitch: 'B4', beat: 0.5, duration: 0.25),
  Note(pitch: 'A4', beat: 0.75, duration: 0.25),
  Note(pitch: 'G#4', beat: 1, duration: 0.25),
  Note(pitch: 'A4', beat: 1.25, duration: 0.25),
  Note(pitch: 'B4', beat: 1.5, duration: 0.25),
  Note(pitch: 'C5', beat: 1.75, duration: 0.25),
  Note(pitch: 'D5', beat: 2, duration: 0.25),
  Note(pitch: 'C5', beat: 2.25, duration: 0.25),
  Note(pitch: 'B4', beat: 2.5, duration: 0.25),
  Note(pitch: 'A4', beat: 2.75, duration: 0.25),
  Note(pitch: 'G#4', beat: 3, duration: 0.5),
  Note(pitch: 'E5', beat: 3.5, duration: 0.5),
  Note(pitch: 'A4', beat: 4, duration: 0.25),
  Note(pitch: 'C5', beat: 4.25, duration: 0.25),
  Note(pitch: 'B4', beat: 4.5, duration: 0.25),
  Note(pitch: 'A4', beat: 4.75, duration: 0.25),
  Note(pitch: 'G#4', beat: 5, duration: 0.25),
  Note(pitch: 'A4', beat: 5.25, duration: 0.25),
  Note(pitch: 'B4', beat: 5.5, duration: 0.25),
  Note(pitch: 'C5', beat: 5.75, duration: 0.25),
  Note(pitch: 'E5', beat: 6, duration: 0.5),
  Note(pitch: 'D5', beat: 6.5, duration: 0.5),
  Note(pitch: 'C5', beat: 7, duration: 0.5),
  Note(pitch: 'B4', beat: 7.5, duration: 0.5),
  Note(pitch: 'A4', beat: 8, duration: 1),
];

// ───────────────────── 中級 ─────────────────────

// 月光 第1楽章(ベートーヴェン)嬰ハ短調・4/4。分散和音の簡易版(三連符は8分で近似)。
const List<Note> _moonlight1 = [
  Note(pitch: 'C#4', beat: 0, duration: 0.5),
  Note(pitch: 'E4', beat: 0.5, duration: 0.5),
  Note(pitch: 'G#4', beat: 1, duration: 0.5),
  Note(pitch: 'C#4', beat: 1.5, duration: 0.5),
  Note(pitch: 'E4', beat: 2, duration: 0.5),
  Note(pitch: 'G#4', beat: 2.5, duration: 0.5),
  Note(pitch: 'C#4', beat: 3, duration: 0.5),
  Note(pitch: 'E4', beat: 3.5, duration: 0.5),
  Note(pitch: 'C#4', beat: 4, duration: 0.5),
  Note(pitch: 'E4', beat: 4.5, duration: 0.5),
  Note(pitch: 'G#4', beat: 5, duration: 0.5),
  Note(pitch: 'C#4', beat: 5.5, duration: 0.5),
  Note(pitch: 'E4', beat: 6, duration: 0.5),
  Note(pitch: 'G#4', beat: 6.5, duration: 0.5),
  Note(pitch: 'C#4', beat: 7, duration: 0.5),
  Note(pitch: 'E4', beat: 7.5, duration: 0.5),
  Note(pitch: 'G#4', beat: 8, duration: 1.5),
  Note(pitch: 'G#4', beat: 9.5, duration: 0.5),
  Note(pitch: 'G#4', beat: 10, duration: 1),
  Note(pitch: 'A4', beat: 11, duration: 1),
  Note(pitch: 'G#4', beat: 12, duration: 2),
  Note(pitch: 'E4', beat: 14, duration: 2),
];

// ノクターン 第2番(ショパン)ハ長調に移調・4/4。簡易アレンジ。
const List<Note> _nocturne = [
  Note(pitch: 'G4', beat: 0, duration: 1),
  Note(pitch: 'E5', beat: 1, duration: 2),
  Note(pitch: 'D5', beat: 3, duration: 1),
  Note(pitch: 'C5', beat: 4, duration: 1),
  Note(pitch: 'E5', beat: 5, duration: 1),
  Note(pitch: 'D5', beat: 6, duration: 1),
  Note(pitch: 'C5', beat: 7, duration: 1),
  Note(pitch: 'B4', beat: 8, duration: 2),
  Note(pitch: 'C5', beat: 10, duration: 1),
  Note(pitch: 'D5', beat: 11, duration: 1),
  Note(pitch: 'C5', beat: 12, duration: 3),
  Note(pitch: 'G4', beat: 15, duration: 1),
  Note(pitch: 'A4', beat: 16, duration: 1),
  Note(pitch: 'C5', beat: 17, duration: 1),
  Note(pitch: 'E5', beat: 18, duration: 1),
  Note(pitch: 'D5', beat: 19, duration: 1),
  Note(pitch: 'C5', beat: 20, duration: 3),
];

// 前奏曲 Op.28-4(ショパン)ホ短調・4/4。ゆっくりした主旋律の簡易版。
const List<Note> _preludeEMinor = [
  Note(pitch: 'B4', beat: 0, duration: 2),
  Note(pitch: 'B4', beat: 2, duration: 1),
  Note(pitch: 'C5', beat: 3, duration: 1),
  Note(pitch: 'B4', beat: 4, duration: 2),
  Note(pitch: 'A4', beat: 6, duration: 1),
  Note(pitch: 'G4', beat: 7, duration: 1),
  Note(pitch: 'A4', beat: 8, duration: 2),
  Note(pitch: 'G4', beat: 10, duration: 1),
  Note(pitch: 'F#4', beat: 11, duration: 1),
  Note(pitch: 'F#4', beat: 12, duration: 2),
  Note(pitch: 'E4', beat: 14, duration: 2),
];

// 月の光(ドビュッシー)ハ長調に移調・3/4。簡易アレンジ。
const List<Note> _clairDeLune = [
  Note(pitch: 'E5', beat: 0, duration: 1.5),
  Note(pitch: 'D5', beat: 1.5, duration: 0.5),
  Note(pitch: 'C5', beat: 2, duration: 1),
  Note(pitch: 'B4', beat: 3, duration: 1.5),
  Note(pitch: 'A4', beat: 4.5, duration: 0.5),
  Note(pitch: 'G4', beat: 5, duration: 1),
  Note(pitch: 'A4', beat: 6, duration: 1),
  Note(pitch: 'B4', beat: 7, duration: 1),
  Note(pitch: 'C5', beat: 8, duration: 1),
  Note(pitch: 'D5', beat: 9, duration: 1.5),
  Note(pitch: 'C5', beat: 10.5, duration: 0.5),
  Note(pitch: 'B4', beat: 11, duration: 1),
  Note(pitch: 'A4', beat: 12, duration: 3),
];

// アラベスク 第1番(ドビュッシー)ホ長調・4/4。分散和音の簡易版。
const List<Note> _debussyArabesque = [
  Note(pitch: 'F#4', beat: 0, duration: 0.5),
  Note(pitch: 'A4', beat: 0.5, duration: 0.5),
  Note(pitch: 'B4', beat: 1, duration: 0.5),
  Note(pitch: 'C#5', beat: 1.5, duration: 0.5),
  Note(pitch: 'B4', beat: 2, duration: 0.5),
  Note(pitch: 'A4', beat: 2.5, duration: 0.5),
  Note(pitch: 'F#4', beat: 3, duration: 0.5),
  Note(pitch: 'A4', beat: 3.5, duration: 0.5),
  Note(pitch: 'B4', beat: 4, duration: 1),
  Note(pitch: 'C#5', beat: 5, duration: 1),
  Note(pitch: 'E5', beat: 6, duration: 0.5),
  Note(pitch: 'C#5', beat: 6.5, duration: 0.5),
  Note(pitch: 'B4', beat: 7, duration: 0.5),
  Note(pitch: 'A4', beat: 7.5, duration: 0.5),
  Note(pitch: 'F#5', beat: 8, duration: 2),
  Note(pitch: 'E5', beat: 10, duration: 1),
  Note(pitch: 'C#5', beat: 11, duration: 1),
  Note(pitch: 'B4', beat: 12, duration: 2),
];

// カノン(パッヘルベル)ニ長調・4/4。よく知られた主旋律(2分音符)。
const List<Note> _canon = [
  Note(pitch: 'F#5', beat: 0, duration: 2),
  Note(pitch: 'E5', beat: 2, duration: 2),
  Note(pitch: 'D5', beat: 4, duration: 2),
  Note(pitch: 'C#5', beat: 6, duration: 2),
  Note(pitch: 'B4', beat: 8, duration: 2),
  Note(pitch: 'A4', beat: 10, duration: 2),
  Note(pitch: 'B4', beat: 12, duration: 2),
  Note(pitch: 'C#5', beat: 14, duration: 2),
  Note(pitch: 'D5', beat: 16, duration: 2),
  Note(pitch: 'A4', beat: 18, duration: 2),
  Note(pitch: 'B4', beat: 20, duration: 2),
  Note(pitch: 'F#4', beat: 22, duration: 2),
  Note(pitch: 'G4', beat: 24, duration: 2),
  Note(pitch: 'D4', beat: 26, duration: 2),
  Note(pitch: 'G4', beat: 28, duration: 2),
  Note(pitch: 'A4', beat: 30, duration: 2),
];

// 前奏曲 ハ長調 BWV846(バッハ 平均律1巻)ハ長調・4/4。分散和音。
const List<Note> _bwv846 = [
  Note(pitch: 'C4', beat: 0, duration: 0.5),
  Note(pitch: 'E4', beat: 0.5, duration: 0.5),
  Note(pitch: 'G4', beat: 1, duration: 0.5),
  Note(pitch: 'C5', beat: 1.5, duration: 0.5),
  Note(pitch: 'E5', beat: 2, duration: 0.5),
  Note(pitch: 'G4', beat: 2.5, duration: 0.5),
  Note(pitch: 'C5', beat: 3, duration: 0.5),
  Note(pitch: 'E5', beat: 3.5, duration: 0.5),
  Note(pitch: 'C4', beat: 4, duration: 0.5),
  Note(pitch: 'D4', beat: 4.5, duration: 0.5),
  Note(pitch: 'A4', beat: 5, duration: 0.5),
  Note(pitch: 'D5', beat: 5.5, duration: 0.5),
  Note(pitch: 'F5', beat: 6, duration: 0.5),
  Note(pitch: 'A4', beat: 6.5, duration: 0.5),
  Note(pitch: 'D5', beat: 7, duration: 0.5),
  Note(pitch: 'F5', beat: 7.5, duration: 0.5),
  Note(pitch: 'B3', beat: 8, duration: 0.5),
  Note(pitch: 'D4', beat: 8.5, duration: 0.5),
  Note(pitch: 'G4', beat: 9, duration: 0.5),
  Note(pitch: 'D5', beat: 9.5, duration: 0.5),
  Note(pitch: 'F5', beat: 10, duration: 0.5),
  Note(pitch: 'G4', beat: 10.5, duration: 0.5),
  Note(pitch: 'D5', beat: 11, duration: 0.5),
  Note(pitch: 'F5', beat: 11.5, duration: 0.5),
  Note(pitch: 'C4', beat: 12, duration: 0.5),
  Note(pitch: 'E4', beat: 12.5, duration: 0.5),
  Note(pitch: 'G4', beat: 13, duration: 0.5),
  Note(pitch: 'C5', beat: 13.5, duration: 0.5),
  Note(pitch: 'E5', beat: 14, duration: 0.5),
  Note(pitch: 'G4', beat: 14.5, duration: 0.5),
  Note(pitch: 'C5', beat: 15, duration: 0.5),
  Note(pitch: 'E5', beat: 15.5, duration: 0.5),
];

// 朝(グリーグ「ペール・ギュント」)ハ長調に移調・3/4(6/8 を 3 拍で表現)。
const List<Note> _morning = [
  Note(pitch: 'G4', beat: 0, duration: 0.5),
  Note(pitch: 'E4', beat: 0.5, duration: 0.5),
  Note(pitch: 'D4', beat: 1, duration: 0.5),
  Note(pitch: 'C4', beat: 1.5, duration: 0.5),
  Note(pitch: 'D4', beat: 2, duration: 0.5),
  Note(pitch: 'E4', beat: 2.5, duration: 0.5),
  Note(pitch: 'G4', beat: 3, duration: 0.5),
  Note(pitch: 'E4', beat: 3.5, duration: 0.5),
  Note(pitch: 'D4', beat: 4, duration: 0.5),
  Note(pitch: 'C4', beat: 4.5, duration: 0.5),
  Note(pitch: 'D4', beat: 5, duration: 0.5),
  Note(pitch: 'E4', beat: 5.5, duration: 0.5),
  Note(pitch: 'G4', beat: 6, duration: 0.5),
  Note(pitch: 'A4', beat: 6.5, duration: 0.5),
  Note(pitch: 'G4', beat: 7, duration: 0.5),
  Note(pitch: 'E4', beat: 7.5, duration: 0.5),
  Note(pitch: 'D4', beat: 8, duration: 0.5),
  Note(pitch: 'C4', beat: 8.5, duration: 0.5),
  Note(pitch: 'D4', beat: 9, duration: 1),
  Note(pitch: 'E4', beat: 10, duration: 1),
  Note(pitch: 'C4', beat: 11, duration: 1),
];

// アヴェ・マリア(シューベルト)ハ長調に移調・4/4。簡易アレンジ。
const List<Note> _aveMaria = [
  Note(pitch: 'G4', beat: 0, duration: 1),
  Note(pitch: 'C5', beat: 1, duration: 1.5),
  Note(pitch: 'C5', beat: 2.5, duration: 0.5),
  Note(pitch: 'C5', beat: 3, duration: 1),
  Note(pitch: 'D5', beat: 4, duration: 1),
  Note(pitch: 'C5', beat: 5, duration: 1),
  Note(pitch: 'B4', beat: 6, duration: 1),
  Note(pitch: 'C5', beat: 7, duration: 1),
  Note(pitch: 'E5', beat: 8, duration: 2),
  Note(pitch: 'D5', beat: 10, duration: 1),
  Note(pitch: 'C5', beat: 11, duration: 1),
  Note(pitch: 'D5', beat: 12, duration: 1),
  Note(pitch: 'G4', beat: 13, duration: 1),
  Note(pitch: 'C5', beat: 14, duration: 2),
];

// エンターテイナー(ジョプリン)ハ長調・2/4。ラグタイム。
// 原曲は高い C(C6)が E の上に跳ねるのが特徴。鍵盤上限(B5)に収めるため
// 全体を 1 オクターブ下げ、「C は E の上(6度上)」という輪郭を保つ。
const List<Note> _entertainer = [
  Note(pitch: 'D4', beat: 0, duration: 0.25),
  Note(pitch: 'D#4', beat: 0.25, duration: 0.25),
  Note(pitch: 'E4', beat: 0.5, duration: 0.5),
  Note(pitch: 'C5', beat: 1, duration: 0.5),
  Note(pitch: 'E4', beat: 1.5, duration: 0.5),
  Note(pitch: 'C5', beat: 2, duration: 0.5),
  Note(pitch: 'E4', beat: 2.5, duration: 0.5),
  Note(pitch: 'C5', beat: 3, duration: 1),
  Note(pitch: 'C5', beat: 4, duration: 0.5),
  Note(pitch: 'D5', beat: 4.5, duration: 0.5),
  Note(pitch: 'D#5', beat: 5, duration: 0.5),
  Note(pitch: 'E5', beat: 5.5, duration: 0.5),
  Note(pitch: 'C5', beat: 6, duration: 0.5),
  Note(pitch: 'D5', beat: 6.5, duration: 0.5),
  Note(pitch: 'E5', beat: 7, duration: 0.5),
  Note(pitch: 'C5', beat: 7.5, duration: 0.5),
  Note(pitch: 'D5', beat: 8, duration: 1),
  Note(pitch: 'C5', beat: 9, duration: 1),
];

// ───────────────────── 上級 ─────────────────────

// 幻想即興曲(ショパン)中間部の旋律をハ長調に移調・4/4。簡易アレンジ。
const List<Note> _fantaisieImpromptu = [
  Note(pitch: 'G4', beat: 0, duration: 1.5),
  Note(pitch: 'A4', beat: 1.5, duration: 0.5),
  Note(pitch: 'G4', beat: 2, duration: 1),
  Note(pitch: 'E4', beat: 3, duration: 1),
  Note(pitch: 'C5', beat: 4, duration: 1.5),
  Note(pitch: 'B4', beat: 5.5, duration: 0.5),
  Note(pitch: 'C5', beat: 6, duration: 1),
  Note(pitch: 'G4', beat: 7, duration: 1),
  Note(pitch: 'A4', beat: 8, duration: 1.5),
  Note(pitch: 'G4', beat: 9.5, duration: 0.5),
  Note(pitch: 'F4', beat: 10, duration: 1),
  Note(pitch: 'E4', beat: 11, duration: 1),
  Note(pitch: 'D4', beat: 12, duration: 2),
];

// 愛の夢 第3番(リスト)ハ長調に移調・3/4。簡易アレンジ。
const List<Note> _liebestraum = [
  Note(pitch: 'G4', beat: 0, duration: 1),
  Note(pitch: 'C5', beat: 1, duration: 2),
  Note(pitch: 'B4', beat: 3, duration: 1),
  Note(pitch: 'C5', beat: 4, duration: 1),
  Note(pitch: 'D5', beat: 5, duration: 1),
  Note(pitch: 'E5', beat: 6, duration: 2),
  Note(pitch: 'D5', beat: 8, duration: 1),
  Note(pitch: 'C5', beat: 9, duration: 1),
  Note(pitch: 'D5', beat: 10, duration: 1),
  Note(pitch: 'E5', beat: 11, duration: 1),
  Note(pitch: 'F5', beat: 12, duration: 1),
  Note(pitch: 'E5', beat: 13, duration: 1),
  Note(pitch: 'D5', beat: 14, duration: 1),
  Note(pitch: 'C5', beat: 15, duration: 2),
];

// 小犬のワルツ(ショパン Op.64-1)ハ長調に移調・3/4。簡易アレンジ。
const List<Note> _minuteWaltz = [
  Note(pitch: 'G4', beat: 0, duration: 0.5),
  Note(pitch: 'A4', beat: 0.5, duration: 0.5),
  Note(pitch: 'B4', beat: 1, duration: 0.5),
  Note(pitch: 'C5', beat: 1.5, duration: 0.5),
  Note(pitch: 'B4', beat: 2, duration: 0.5),
  Note(pitch: 'A4', beat: 2.5, duration: 0.5),
  Note(pitch: 'G4', beat: 3, duration: 0.5),
  Note(pitch: 'A4', beat: 3.5, duration: 0.5),
  Note(pitch: 'B4', beat: 4, duration: 0.5),
  Note(pitch: 'C5', beat: 4.5, duration: 0.5),
  Note(pitch: 'D5', beat: 5, duration: 0.5),
  Note(pitch: 'E5', beat: 5.5, duration: 0.5),
  Note(pitch: 'D5', beat: 6, duration: 1),
  Note(pitch: 'B4', beat: 7, duration: 1),
  Note(pitch: 'G4', beat: 8, duration: 1),
  Note(pitch: 'C5', beat: 9, duration: 2),
];

// 月光 第3楽章(ベートーヴェン)嬰ハ短調・4/4。上昇分散和音の簡易版。
const List<Note> _moonlight3 = [
  Note(pitch: 'C#4', beat: 0, duration: 0.25),
  Note(pitch: 'E4', beat: 0.25, duration: 0.25),
  Note(pitch: 'G#4', beat: 0.5, duration: 0.25),
  Note(pitch: 'C#5', beat: 0.75, duration: 0.25),
  Note(pitch: 'E5', beat: 1, duration: 0.25),
  Note(pitch: 'G#5', beat: 1.25, duration: 0.25),
  Note(pitch: 'E5', beat: 1.5, duration: 0.25),
  Note(pitch: 'C#5', beat: 1.75, duration: 0.25),
  Note(pitch: 'B4', beat: 2, duration: 0.25),
  Note(pitch: 'D#5', beat: 2.25, duration: 0.25),
  Note(pitch: 'F#5', beat: 2.5, duration: 0.25),
  Note(pitch: 'B5', beat: 2.75, duration: 0.25),
  Note(pitch: 'F#5', beat: 3, duration: 0.25),
  Note(pitch: 'D#5', beat: 3.25, duration: 0.25),
  Note(pitch: 'B4', beat: 3.5, duration: 0.25),
  Note(pitch: 'F#4', beat: 3.75, duration: 0.25),
  Note(pitch: 'G#4', beat: 4, duration: 0.25),
  Note(pitch: 'C#5', beat: 4.25, duration: 0.25),
  Note(pitch: 'E5', beat: 4.5, duration: 0.25),
  Note(pitch: 'G#5', beat: 4.75, duration: 0.25),
  Note(pitch: 'C#5', beat: 5, duration: 1),
  Note(pitch: 'C#5', beat: 6, duration: 1),
];

/// 起動時に編集タブの既定として開く看板曲。
Piece buildFeaturedPiece() => Piece(
  id: 'fur-elise',
  title: 'エリーゼのために',
  composer: 'L.v. ベートーヴェン',
  beatsPerMeasure: 3,
  defaultBpm: 76,
  notes: List<Note>.of(_furElise),
);

/// 既定でシードする収録曲(featured を除く 19 曲。初級 → 中級 → 上級の順)。
/// すべてパブリックドメイン。
List<Piece> buildSamplePieces() => [
  // ── 初級 ──
  Piece(
    id: 'minuet-g',
    title: 'メヌエット ト長調',
    composer: 'C. ペツォールト',
    beatsPerMeasure: 3,
    defaultBpm: 120,
    notes: List<Note>.of(_minuet),
  ),
  Piece(
    id: 'sonata-facile',
    title: 'ソナタ・ファチレ K.545',
    composer: 'W.A. モーツァルト',
    beatsPerMeasure: 4,
    defaultBpm: 120,
    notes: List<Note>.of(_sonataFacile),
  ),
  Piece(
    id: 'gymnopedie-1',
    title: 'ジムノペディ 第1番',
    composer: 'E. サティ',
    beatsPerMeasure: 3,
    defaultBpm: 66,
    notes: List<Note>.of(_gymnopedie),
  ),
  Piece(
    id: 'ode-to-joy',
    title: '歓喜の歌(第九)',
    composer: 'L.v. ベートーヴェン',
    beatsPerMeasure: 4,
    defaultBpm: 100,
    notes: List<Note>.of(_odeToJoy),
  ),
  Piece(
    id: 'burgmuller-arabesque',
    title: 'アラベスク(25の練習曲)',
    composer: 'F. ブルクミュラー',
    beatsPerMeasure: 2,
    defaultBpm: 108,
    notes: List<Note>.of(_burgmullerArabesque),
  ),
  // ── 中級 ──
  Piece(
    id: 'moonlight-1',
    title: '月光 第1楽章',
    composer: 'L.v. ベートーヴェン',
    beatsPerMeasure: 4,
    defaultBpm: 52,
    notes: List<Note>.of(_moonlight1),
  ),
  Piece(
    id: 'nocturne-2',
    title: 'ノクターン 第2番',
    composer: 'F. ショパン',
    beatsPerMeasure: 4,
    defaultBpm: 60,
    notes: List<Note>.of(_nocturne),
  ),
  Piece(
    id: 'prelude-e-minor',
    title: '前奏曲 Op.28-4',
    composer: 'F. ショパン',
    beatsPerMeasure: 4,
    defaultBpm: 56,
    notes: List<Note>.of(_preludeEMinor),
  ),
  Piece(
    id: 'clair-de-lune',
    title: '月の光',
    composer: 'C. ドビュッシー',
    beatsPerMeasure: 3,
    defaultBpm: 56,
    notes: List<Note>.of(_clairDeLune),
  ),
  Piece(
    id: 'debussy-arabesque',
    title: 'アラベスク 第1番',
    composer: 'C. ドビュッシー',
    beatsPerMeasure: 4,
    defaultBpm: 92,
    notes: List<Note>.of(_debussyArabesque),
  ),
  Piece(
    id: 'canon',
    title: 'カノン',
    composer: 'J. パッヘルベル',
    beatsPerMeasure: 4,
    defaultBpm: 80,
    notes: List<Note>.of(_canon),
  ),
  Piece(
    id: 'bwv846',
    title: '前奏曲 ハ長調 BWV846',
    composer: 'J.S. バッハ',
    beatsPerMeasure: 4,
    defaultBpm: 72,
    notes: List<Note>.of(_bwv846),
  ),
  Piece(
    id: 'morning',
    title: '朝(ペール・ギュント)',
    composer: 'E. グリーグ',
    beatsPerMeasure: 3,
    defaultBpm: 72,
    notes: List<Note>.of(_morning),
  ),
  Piece(
    id: 'ave-maria-schubert',
    title: 'アヴェ・マリア',
    composer: 'F. シューベルト',
    beatsPerMeasure: 4,
    defaultBpm: 60,
    notes: List<Note>.of(_aveMaria),
  ),
  Piece(
    id: 'entertainer',
    title: 'エンターテイナー',
    composer: 'S. ジョプリン',
    beatsPerMeasure: 2,
    defaultBpm: 90,
    notes: List<Note>.of(_entertainer),
  ),
  // ── 上級 ──
  Piece(
    id: 'fantaisie-impromptu',
    title: '幻想即興曲',
    composer: 'F. ショパン',
    beatsPerMeasure: 4,
    defaultBpm: 80,
    notes: List<Note>.of(_fantaisieImpromptu),
  ),
  Piece(
    id: 'liebestraum',
    title: '愛の夢 第3番',
    composer: 'F. リスト',
    beatsPerMeasure: 3,
    defaultBpm: 76,
    notes: List<Note>.of(_liebestraum),
  ),
  Piece(
    id: 'minute-waltz',
    title: '小犬のワルツ',
    composer: 'F. ショパン',
    beatsPerMeasure: 3,
    defaultBpm: 126,
    notes: List<Note>.of(_minuteWaltz),
  ),
  Piece(
    id: 'moonlight-3',
    title: '月光 第3楽章',
    composer: 'L.v. ベートーヴェン',
    beatsPerMeasure: 4,
    defaultBpm: 120,
    notes: List<Note>.of(_moonlight3),
  ),
];
