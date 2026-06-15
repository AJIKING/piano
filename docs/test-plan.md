# Étude — テスト計画

`docs/harness-engineering.md` の方針を `docs/product-spec.md` の仕様に適用した具体計画。新しい機能を実装するときは、この表に対応する層のテストを同じ PR に含める。

## 差し替え境界の具体化

ハーネス方針の差し替え対象候補を、このアプリでは次のとおり具体化する。

| 境界 | このアプリでの用途 | 既定実装 / テスト実装 |
| --- | --- | --- |
| `Clock` | 「最終練習 昨日」等の相対日付、習得度の更新日時 | システム時刻 / 固定 fake |
| `ScoreRepository` | 収録曲の供給 | 同梱データ / テスト用最小 fixture |
| `LibraryStore` | ユーザー楽譜・習得度・最終練習日時の永続化 | デバイスストレージ / インメモリ fake |
| `AudioEngine` | 発音・再生(Tone.js 相当の副作用) | flutter_midi_pro + SoundFont / 呼び出しを記録するだけの fake(音を鳴らさない) |

通信がないため `ApiClient` は不要。`Random` 依存もない(プロトタイプの旋律はデモ固定で、シャッフル要素がない)。再生のタイミングは実時間ではなく `Clock` / `fake_async` で進める。

## Unit test(`test/unit/`)

| 対象 | 守る振る舞い |
| --- | --- |
| 音符モデル(`Note`) | 音高パース(`C4` / `F#5` 等の妥当/不正)/ diatonic step 計算 / 音価の妥当性 / 同値比較 |
| 譜面ジオメトリ(`ScoreGeometry`) | 拍 → X 座標、音高 → Y 座標、X/Y → スナップした拍・音高(エディタのタップ追加) |
| 再生(`PracticeController`) | 拍ベースで発音時刻を進める / 音価が発音間隔・余韻(sustain)に反映 / 末尾+余韻で停止 / 再生中のテンポ変更が即反映 / 和音(同 beat)を全て発音 / 鳴っている音高(`litPitch`)/ すべて fake_async で実時間を使わない |
| メトロノーム(`PracticeController`) | 1 拍ごとのクリック / 拍頭の強拍判定(3 拍子) |
| 楽譜編集(`EditorController`) | 音符追加で beat 昇順に整列 / 選択音符の音価・♯ 変更 / 削除・全消去 / キャレット前進・末尾へ / 戻る・進む(undo/redo)/ 初期版へ戻す(収録曲のみ)/ ♯ は黒鍵を持つ音名のみ / step→音名(`Note.pitchForStep`) |
| 習得度(`Mastery`) | 練習完了で +practiceStep / 100 で頭打ち |
| 収録曲データ検証 | `pitch` が妥当な音名 / `duration` が許容音価 / `beat` 非負・整列可能 / `id` 一意 / `stars` 0–5(全収録曲に対する contract test) |
| ライブラリ状態(`LibraryController`) | 収録曲+ユーザー曲の結合(featured も一覧に含む)/ 新規作成・編集保存・練習記録が永続化される / 練習完了で習得度+最終練習日時が更新 / snapshot 往復・旧データ互換(featured 補完) |

## Widget test(`test/widget/`)

| 対象 | 守る振る舞い |
| --- | --- |
| ライブラリ | 楽譜一覧(featured 含む)の描画 / 作成ボタンで新規曲が増える / タップで練習画面へ遷移 / 編集ボタンでエディタへ |
| 鍵盤(`PianoKeyboard`) | 白鍵・黒鍵の配置 / タップで `AudioEngine.playNote` が呼ばれる(記録 fake で検証)/ Semantics ラベル / 再生・試聴中は鳴っている鍵をハイライト(`litPitches`) |
| 譜面(`ScoreView`) | 音符・小節線・再生ヘッドの描画(golden 化は後続)/ 再生中ハイライト |
| 練習(`PracticeScreen`) | 再生 / 停止トグル / テンポスライダーの反映 / メトロノーム ON/OFF / 音符タップで選んだ位置から再生(発音は記録 fake で検証、再生中タイマーは fake で進める) |
| エディタ(`EditorScreen`) | 音符追加(譜面タップ / 鍵盤タップ)/ 選択 / 削除 / 音価・♯ ツール / 曲名編集 / 戻る・進む / 試聴(選択位置から・テンポ可変・譜面/鍵盤ハイライト)/ ツールバー表示切替 / 初期版へ戻す |
| Semantics | 鍵盤・音符・主要ボタンに意味ラベルがある |

widget test では animation を `pumpAndSettle` または明示 `pump` で進め、実時間 `sleep` を使わない。再生中の playhead 移動なども fake 化した時間で検証する。

## Golden test(`test/golden/`)

対象(light / dark の両方):

- 鍵盤の 1 オクターブ(`PianoKeyboard`、和音ハイライトあり)。
- 譜面の数小節(`ScoreView`)※今後追加。

固定条件: device size、text scale 1.0、locale ja、同梱フォントをテスト内でロード。基準 platform は CI(Linux)— 詳細は `docs/harness-engineering.md` の Golden 方針と ADR 0002(`docs/design-docs/0002-golden-test-operations.md`)。全画面 snapshot は撮らない。

共通セットアップは `test/golden/golden_setup.dart`。各ファイル `@Tags(['golden'])` 付き、非 Linux では自動 skip。

baseline は `test/golden/goldens/` にコミットする(`golden.yml` で生成した Linux 基準画像)。check.yml の `golden` job が PR / main push ごとに比較する。意図した UI 変更で更新するときは同じ手順で再生成する:

1. `.github/workflows/golden.yml` を workflow_dispatch で実行する(ubuntu-latest 上で `flutter test --update-goldens test/golden`)。
2. artifact `golden-baselines` をダウンロードし、`test/golden/goldens/` に展開してコミットする(ADR 0002)。

golden ハーネス(setup / tag / skip / baseline 運用)は `PianoKeyboard` の golden 1 件で通す。譜面の golden は今後追加する。

## Integration smoke(`integration_test/`)

journey: 起動 → ライブラリに収録曲が表示される → 曲をタップ → 練習画面が開く。

- エントリーポイントは `lib/main_test.dart`。fake clock・インメモリ store・記録 AudioEngine を注入して起動する(実発音しない)。
- 実行はエミュレータ / シミュレータが必要(`flutter test integration_test` は端末上で動く)。CI へは main branch 段階で導入し、PR では必須にしない(`.github/workflows/integration.yml`)。
- 再生機能が実装されたら、再生 → 停止 → 習得度反映までジャーニーを拡張する。

## Fixture(`test/fixtures/`)

- 本番の収録曲データはテストでそのまま検証する(contract test)。
- ロジックテスト用には最小 fixture を別途持つ: 数音符の短い旋律 1 曲、空の自作曲 1 曲。命名は「2 拍の単旋律」のように検証したい振る舞いで付ける。
- 共有 fake: `FakeClock`(固定時刻)、`InMemoryLibraryStore`、`RecordingAudioEngine`(`playNote` 等の呼び出しを記録)。

## 実装順(ハーネス先行)

1. 音符モデル・譜面ジオメトリ + unit test(UI なしで最初の green を作る)。
2. 収録曲データ + contract test。
3. ライブラリ状態(`LibraryController`)+ unit test、ライブラリ画面 + widget test。
4. 鍵盤・譜面ウィジェット + widget / golden test。
5. 再生スケジュール + `AudioEngine` 連携 + unit test(fake_async)、練習画面。
6. 楽譜エディタ + unit / widget test。
7. integration smoke の拡張。
