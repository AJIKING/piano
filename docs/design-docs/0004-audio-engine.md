# ADR 0004: ピアノ音源・再生エンジンの方式

- 状態: 採用(2026-06-15 改訂: 波形シンセ → SoundFont)
- 日付: 2026-06-14 / 改訂 2026-06-15

## 決定

発音・再生は **`AudioEngine` 境界(pure Dart のインターフェース)の裏に隠す**。本番実装は **flutter_midi_pro + SoundFont(.sf2)** を採用する。音名を MIDI ノート番号(`Note.midiOf`)に変換し、ピアノ音色の SoundFont で発音する。本番実装 `lib/src/data/midi_pro_audio_engine.dart`(`MidiProAudioEngine`)はプラグイン呼び出しを薄く委譲するだけのアダプタのため、**自動テストの対象外**(実機確認で担保)。テストでは呼び出しを記録する fake(`RecordingAudioEngine`)に差し替える。

- `AudioEngine` の責務は最小に保つ: 初期化(SoundFont ロード)、単音の発音(音高 + 余韻)、停止。
- **再生スケジュール(旋律 → 各音符の発音タイミング、テンポ追従、メトロノーム)は `PracticeController` が拍ベースで持つ**(`_elapsedBeats` を毎フレーム bpm に応じて進める)。実時間ではなく `fake_async` で `Timer` を進めて検証する。再生中のテンポ変更が即反映される。`AudioEngine` は「いつ鳴らすか」を持たず「鳴らす」だけにする。
- 音色は `assets/audio/piano.sf2` の SoundFont に依存する(置き方は `assets/audio/README.md`)。`.sf2` が無くてもアプリは起動し、発音だけ無音になる。
- **改訂前**(2026-06-14)は flutter_soloud の三角波シンセ(`SoLoudAudioEngine`)だったが、「ピアノ音に聞こえない(純音すぎる)」ため SoundFont 方式へ差し替えた。境界が同じなのでアダプタ 1 ファイルの置き換えで済んだ(`flutter_soloud` 依存は削除)。

## 背景

`docs/product-spec.md`「音源・再生エンジン」の実現方式を決める。プロトタイプは Tone.js(Salamander サンプルピアノ＋フォールバックのシンセ)で、ブラウザの WebAudio に依存している。Flutter での候補:

| 候補 | 評価 |
| --- | --- |
| サンプル音源(音高ごとの録音を再生) | 音が自然。発音は単純な「クリップ再生」で `AudioEngine` 境界に収まる。アセット容量が増える |
| ソフトシンセ(波形合成) | アセット不要だが音色が機械的。実装が重い |
| SoundFont(.sf2)+ シンセ | 1 ファイルで多音色。対応プラグインの成熟度に依存 |

また、Flutter にはオーディオ再生プラグインが複数あり(`just_audio` / `audioplayers` / `soundpool` / `flutter_soundfont` 系)、レイテンシ・同時発音数・プラットフォーム対応に差がある。

## 理由

- まず**アセット不要で実音が出せる**ことを優先した。録音サンプル(Salamander 等)は音が自然だが数 MB のバイナリ同梱が要る。波形シンセは即座に鳴らせ、プロトタイプのフォールバックも三角波シンセだった。音質改善(サンプル化)は境界の裏で後から差し替えられる。
- flutter_soloud を選んだ理由: Android / iOS / desktop に対応し、低レイテンシ・ポリフォニー・波形生成(`loadWaveform` + `setWaveformFreq`)を内蔵する。音高ごとに波形ソースを持てば同時発音できる。
- どのプラグインを選んでも、アプリ側が必要とするのは「この音高を今鳴らす / 止める」という最小操作だけ。これを `AudioEngine` 境界に閉じ込めれば、プラグイン選定や差し替えがアプリ全体に波及しない。
- 再生タイミングを pure Dart のスケジュールロジックに切り出すことで、テンポ・メトロノーム・playhead 同期を**実時間も実発音もなしに決定的にテスト**できる(プロトタイプの `Tone.Transport` 直依存は踏襲しない)。
- プラグインアダプタを自動テスト対象外にするのは、実発音・OS のオーディオセッション・レイテンシが CI で安定検証できないため。これらは実機 / エミュレータの手動確認で担保する。

## 結果

- アプリコード・domain・ui は `AudioEngine` 境界のみに依存する。音源プラグイン(flutter_soloud)を直接 import するのは `soloud_audio_engine.dart` だけ。
- `pubspec.yaml` に `flutter_soloud` を追加した。発音は `SoLoudAudioEngine` が `init()`(初回タップ時に遅延初期化)→ `loadWaveform` で音高ごとの三角波ソースを用意 → `play` + `fadeVolume`(余韻で減衰)+ `scheduleStop` で行う。
- テスト・integration はすべて `RecordingAudioEngine` を注入し、実際の音を鳴らさない。`SoLoudAudioEngine` を import するのは `lib/main.dart` のみで、テストの依存グラフには入らない(FFI 初期化が走らない)。
- **実音・レイテンシは実機 / エミュレータでの確認が必須**(この環境では検証できない)。サンプル音源化する場合は音声アセットを `pubspec.yaml` の `assets:` に登録し、ライセンス(Salamander 等は CC)を明記して本 ADR を改訂する。
- 同時発音数・マナーモード時の挙動など、実機でしか分からない問題が出たらこの ADR を見直す。
