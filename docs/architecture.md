# Étude — Flutter アーキテクチャとフォルダ構成

`docs/product-spec.md` の仕様と `docs/test-plan.md` の差し替え境界を実現するためのアプリ構造を定義する。判断基準はハーネス方針(`docs/harness-engineering.md`)と同じ: **決定的にテストできること、必要になるまで複雑にしないこと。**

## 全体像

4 層のレイヤードアーキテクチャ。依存は必ず上から下への一方向。

```text
ui           画面・ウィジェット・テーマ(Flutter)
  ↓
application  画面をまたぐ状態と操作(ChangeNotifier)
  ↓
domain       モデル・譜面ジオメトリ・再生スケジュール(pure Dart)
  ↓ (インターフェースのみ)
data         domain のインターフェース実装(永続化・収録曲供給・音源)
```

- **domain は pure Dart**。`dart:ui` / `package:flutter` を import しない。音符モデル・譜面ジオメトリ・再生スケジュールのロジックが最速の unit test で守れる。
- **data は domain が定義したインターフェースを実装する**(依存性逆転)。domain は data を知らない。
- **ui は application を通じて状態を読む**。ui から domain のモデルを参照するのは可(表示のため)、data を直接触るのは不可。

## 主要な設計判断

| 判断 | 採用 | 理由 |
| --- | --- | --- |
| 状態管理 | `ChangeNotifier` + `ListenableBuilder`(Flutter 標準のみ) | 4 画面・通信なしの規模に外部フレームワークは過剰。依存ゼロでテストも素直。状態の組み合わせが増えて破綻し始めたら Riverpod への移行を再検討する |
| DI | composition root でのコンストラクタ注入(DI コンテナなし) | 差し替え境界が 4 つしかない。`main_*.dart` で全部組み立てれば十分 |
| ナビゲーション | `NavigationRail`(左レール)で 4 画面を切替。`AppShell` が編集状態と現在曲を所有しタブ間で共有 | 横画面前提で縦を鍵盤に回すため左レール。deep link 要件が出たら go_router を検討 |
| 不変モデル | `Note` / `Piece` は immutable(`copyWith`) | 状態変化の追跡を application 層に限定する |
| 再生 | スケジュールは pure Dart、発音は `AudioEngine` 境界 | 実時間・実発音に依存せずタイミングを検証できる(プロトタイプの `Tone.Transport` 直叩きは踏襲しない) |
| 譜面ジオメトリ | pure Dart の関数群(音高↔step、拍↔X) | UI から切り離して unit test する |

## 差し替え境界とエントリーポイント

domain / core にインターフェース、data に本番実装、テストに fake を置く。

| 境界 | インターフェースの場所 | 本番実装 | テスト実装 |
| --- | --- | --- | --- |
| `Clock` | `core/` | システム時刻(`SystemClock`) | 固定 fake |
| `ScoreRepository` | `domain/score/` | 同梱 Dart データ(`BundledScoreRepository`) | 最小 fixture |
| `LibraryStore` | `domain/library/` | shared_preferences(`PrefsLibraryStore`) | インメモリ fake |
| `AudioEngine` | `domain/audio/` | SoundFont シンセ(`MidiProAudioEngine`、flutter_midi_pro、テスト対象外) | 呼び出し記録 fake |

composition root は 3 つ。組み立てロジックは共通化し、差分(clock / store / audio)だけを変える。

- `lib/main.dart` — 本番構成。
- `lib/main_dev.dart` — 開発用(デバッグ向け設定があれば。初期は未作成)。
- `lib/main_test.dart` — integration test 用。fake clock・インメモリ store・記録 AudioEngine で起動。

## フォルダ構成

```text
lib/
├── main.dart                 # 本番 composition root
├── main_test.dart            # integration test 用 composition root
└── src/
    ├── app.dart              # MaterialApp・テーマ適用(home=AppShell)
    ├── core/
    │   └── clock.dart        # Clock インターフェースと SystemClock
    ├── domain/
    │   ├── score/
    │   │   ├── note.dart              # Note(pitch/beat/duration)・音高パース・diatonic step
    │   │   ├── piece.dart             # Piece(曲・習得度・最終練習日時)
    │   │   ├── score_geometry.dart    # 拍↔X、音高↔Y などの譜面ジオメトリ(pure Dart)
    │   │   └── score_repository.dart  # 収録曲供給インターフェース
    │   ├── library/
    │   │   └── library_store.dart     # ユーザー楽譜・習得度の永続化インターフェース
    │   └── audio/
    │       └── audio_engine.dart      # 発音・再生インターフェース(pure Dart)
    ├── data/
    │   ├── score_data.dart                 # 収録曲データ本体(旋律)
    │   ├── bundled_score_repository.dart    # ScoreRepository の同梱実装
    │   ├── prefs_library_store.dart         # LibraryStore の永続化実装
    │   └── midi_pro_audio_engine.dart       # AudioEngine の本番実装(flutter_midi_pro + SoundFont。テスト対象外)
    ├── application/
    │   ├── dependencies.dart        # 差し替え境界の束(composition root が生成)
    │   ├── library_controller.dart  # 曲一覧・現在曲・新規作成(ChangeNotifier)
    │   ├── practice_controller.dart # 再生・テンポ・メトロノーム・playhead(ChangeNotifier)
    │   └── editor_controller.dart   # 音符の追加/削除/選択・ツール状態・曲名・戻る/進む・初期版リセット(ChangeNotifier)
    └── ui/
        ├── app_shell.dart          # NavigationRail シェル(4画面切替・編集状態と現在曲を所有)
        ├── theme/
        │   └── etude_theme.dart    # デザイントークン(色・フォント・spacing・dark 基調)
        ├── library/
        │   ├── library_screen.dart
        │   └── now_practicing_card.dart  # 「今練習中」カード
        ├── practice/
        │   └── practice_screen.dart      # 譜面+鍵盤+再生(実装済み)
        ├── editor/
        │   └── editor_screen.dart        # 楽譜エディタ(実装済み)
        ├── free/
        │   └── free_screen.dart          # 自由演奏(実装済み)
        └── widgets/
            ├── piano_keyboard.dart  # 横スクロール鍵盤(白鍵・黒鍵)
            └── score_view.dart      # 五線譜描画(CustomPainter)
```

スケルトン以降、4 画面・主要ウィジェット・再生・編集まで実装済み。1 ファイルが肥大したら同じフォルダ内で分割してよいが、**フォルダの責務と依存方向は変えない**。

## テストのミラー構成

`test/` は `lib/src/` をミラーし、層ごとのフォルダに置く(`docs/test-plan.md` の対応表に従う)。

```text
test/
├── unit/
│   ├── score/             # 音符パース・ジオメトリ・再生スケジュール
│   ├── application/       # ライブラリ/練習/エディタの状態
│   └── data/              # 収録曲の contract test
├── widget/
│   ├── library/
│   ├── practice/
│   └── editor/
├── golden/                # 曲カード・鍵盤・譜面
├── fixtures/              # 最小曲セット・fake 実装(fake_clock, in_memory_library_store, recording_audio_engine)
integration_test/
└── smoke_test.dart        # 起動→ライブラリ→練習画面
```

fake は fixture と同様に共有資産として `test/fixtures/` に置き、各テストで重複定義しない。

## 依存ルールの守り方

- domain のファイルに `package:flutter` を import しない。違反は `/harness-review` のレビュー観点に含まれる。
- ui から `data/` を import しない。必要な操作はすべて application の controller を経由する。
- 発音は必ず `AudioEngine` 境界を経由する。ui / domain から音源プラグインを直接呼ばない。
- 再生タイミングは実時間に依存させない。`DateTime.now()` の直叩きや `sleep` / 固定 `Future.delayed` による同期を書かない(`Clock` と再生スケジュールのロジックを使う)。
- 境界インターフェースにメソッドを足すときは、本番実装と fake の両方を同じ PR で更新する。

## このドキュメントの見直し時期

- 最初の 4 画面が実装された後(構成が実態と合っているか)。
- 再生エンジン / 楽譜エディタの実装で domain ロジックが膨らんだとき。
- 状態管理が `ChangeNotifier` で苦しくなったとき(Riverpod 移行判断)。
- MIDI・録音など新しい platform 要件が入るとき。
