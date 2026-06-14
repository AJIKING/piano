# 音源アセット(SoundFont)

ピアノ音を鳴らすには **SoundFont (.sf2)** をこのフォルダに置く。

## 置き方
1. ピアノ音色の SoundFont を入手する（例）:
   - **Salamander Grand Piano**（CC ライセンス。各所で `.sf2` 配布あり）
   - **soundfonts4u** の Steinway（無料配布の Grand Piano 系 `.sf2`）
   - その他、General MIDI のピアノ（program 0 = Acoustic Grand Piano）を含む `.sf2`
2. ファイル名を **`piano.sf2`** にして、このフォルダ（`assets/audio/piano.sf2`）に置く。
3. `flutter pub get` → `flutter run`。

`pubspec.yaml` は `assets/audio/` をディレクトリ宣言しているので、`piano.sf2` を置くだけで自動的に同梱される（pubspec の編集は不要）。

## 仕組み
- 読み込みと発音は `lib/src/data/midi_pro_audio_engine.dart`（`AudioEngine` 境界の本番実装）が `flutter_midi_pro` 経由で行う。
- `Note.midiOf(pitch)` で音名 → MIDI ノート番号に変換して `playNote`、余韻後に `stopNote`。
- `.sf2` が未配置でもアプリは起動する（発音だけ無音になる）。テストは記録 fake を使うため音源に依存しない。

## ライセンス注意
SoundFont は配布元のライセンス（多くは無償・再配布条件あり）に従うこと。容量が大きい（数MB〜数十MB）ので、リポジトリにコミットするか配布物に同梱するかは運用方針に合わせる。
