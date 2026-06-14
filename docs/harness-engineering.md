# Flutter プロジェクト向けハーネスエンジニアリング設計

## 目的

この文書は、新しい Flutter プロジェクトを立ち上げるときのハーネスエンジニアリング方針を定義する。

ここでいうハーネスとは、アプリ本体の外側にある再現可能な実行環境のこと。プロジェクト生成、依存解決、静的解析、テスト、端末実行、テストデータ、CI、失敗時の証跡までを含む。

ハーネスの目的は、品質確認を属人化させず、壊れたときに「どこで、なぜ、どう壊れたか」を追える状態を最初のコミットから作ること。

## 関連ドキュメント

- `docs/product-spec.md`: 今回開発するピアノ練習＆楽譜エディタ「Étude」の仕様(プロトタイプ `docs/prototype/etude-piano-app.html` 準拠)。
- `docs/architecture.md`: Flutter アーキテクチャとフォルダ構成(レイヤー、差し替え境界の配置、依存ルール)。
- `docs/test-plan.md`: この方針を本アプリに適用した具体的なテスト計画(何をどの層で守るか、差し替え境界の具体化)。
- `CLAUDE.md`: 日常コマンドと開発規約の要約。

## ゴール

- ローカルと CI の実行結果をできるだけ一致させる。
- 安い層のテストで先に回帰を捕まえる。
- テストデータ、アプリ設定、端末条件を明示する。
- 失敗時にログ、スクリーンショット、差分、レポートから原因を追えるようにする。
- 新しい開発者が暗黙知なしでテストを追加できるようにする。
- モバイル固有のリスク、つまり端末差分、権限、ライフサイクル、音声出力、ローカライズ、Platform Channel を扱えるようにする。

## 非ゴール

- プロダクト機能そのものは定義しない。
- アプリ全体の最終アーキテクチャはこの文書だけでは決めない。
- リリース戦略、監視設計、詳細なテストケース一覧の代替にはしない。

## ハーネスのレイヤー

ハーネスは次の 5 層に分けて設計する。

## 1. プロジェクトブートストラップ

クリーンチェックアウトから同じ状態を再現できるようにする層。

必要なもの:

- Flutter SDK バージョンの固定。
- Dart / Flutter の対応バージョン明記。
- 依存関係を解決するコマンド。
- 静的解析を実行するコマンド。
- デフォルトのテストを実行するコマンド。
- ローカルと CI の環境変数テンプレート。

初期コマンド候補:

```sh
flutter pub get
flutter analyze
flutter test
```

初期判断:

- FVM を採用するか。
- 生成ファイルをコミット対象にするか。
- build flavor を最初から導入するか、環境差分が出てから導入するか。

推奨:

- Flutter SDK は FVM で固定する。
- バージョンの単一の真実は `.fvmrc`。CI(`.github/workflows/check.yml`)は `flutter-version` をハードコードしているため、バージョン更新時は必ず両方を同時に変更する。片方だけ更新された状態を検知できないことが既知のリスク。
- flavor は必要になるまで増やさない。
- まずは `dev` と `test` の設定差分だけを明示する。

## 2. テスト実行ハーネス

テストをどの粒度で持ち、どのタイミングで実行するかを決める層。

テスト種別:

- Unit test: 純粋な Dart ロジック、バリデーション、フォーマット、変換処理。
- Widget test: UI 状態、表示分岐、ナビゲーション境界、semantics。
- Golden test: 共有コンポーネントや壊れやすい画面の視覚差分。
- Integration test: アプリ起動、画面遷移、保存、音声再生、Platform 連携を含むユーザージャーニー。
- Contract test: データスキーマ、Repository、シリアライズ、fixture 互換性。

初期方針:

- Pull Request では unit test と widget test を必須にする。
- UI 基盤やデザイン変更を含む PR では golden test を実行する。
- integration test は main branch、release branch、手動検証で実行する。
- 遅いテストや flaky なテストは黙って除外せず、分類して追跡する。

コマンド候補:

```sh
flutter test
flutter test test/widget
flutter test --update-goldens
flutter test integration_test
```

将来的には `tool/test` や `melos`、`just`、`make` などでラップしてもよい。ただし、Flutter 標準コマンドで何が起きているかは隠しすぎない。

## 3. アプリ実行時ハーネス

テスト時のアプリ状態を制御する層。

必要な能力:

- 決定的な seed data(収録曲・自作曲)。
- ローカルストレージのリセット。
- モック可能な音声出力境界(実際に音を鳴らさずに再生・発音を検証できる)。
- 差し替え可能な clock。
- locale の切り替え。
- feature flag の切り替え。
- permission 状態の準備(将来、録音やマイク入力を扱う場合)。
- deep link から特定画面を起動する仕組み。

原則:

テストは、実時間、前回の端末状態、実際のスピーカー出力、外部サービスの気分に依存しない。依存する場合は、そのテストが明示的に end-to-end 検証であると分かる名前と配置にする。

エントリーポイント候補:

- `lib/main.dart`: 通常起動。
- `lib/main_dev.dart`: 開発用設定。
- `lib/main_test.dart`: integration test 用設定。

差し替え対象の候補:

- `Clock`
- `AppConfig`
- `FeatureFlags`
- `AudioEngine`(発音・再生の副作用境界)
- `LibraryStore`(楽譜・習得度の永続化)
- `PermissionGateway`(将来のマイク入力など)

## 4. 端末・プラットフォームハーネス

モバイル固有の差分を扱う層。

対象 platform:

- Android。
- iOS。

最小端末マトリクス:

- 最新寄りの Android emulator。
- サポート下限に近い Android API level。
- 最新寄りの iOS simulator。
- 小さい画面。
- 大きい画面。

記録すべき条件:

- OS version。
- 画面サイズと pixel density。
- locale。
- text scale。
- light / dark mode。
- audio output route(マナーモード / イヤホン / Bluetooth など)。
- audio latency。
- permission state。
- app lifecycle state(バックグラウンドで再生を止めるか)。

初期推奨:

CI の端末マトリクスは小さく始める。端末差分由来のバグが実際に出たら、その種類に合わせて増やす。

音声再生は本アプリの中核機能のため、実発音そのものは `AudioEngine` 境界の fake で自動テストから切り離す(音は鳴らさず、いつ・どの音を鳴らすかだけを検証する)。実際の音色・レイテンシ・OS 側のオーディオセッション挙動は実機 / エミュレータでの手動確認で担保する。マイク入力・録音は初期 scope には含めない。

## 5. 証跡・診断ハーネス

失敗を調査可能にする層。

CI 実行で残すもの:

- machine-readable test report。
- human-readable summary。
- analyzer output。
- integration test 失敗時の screenshot。
- test 名、端末 profile、app flavor、seed を含む log。
- golden test 失敗時の diff artifact。

integration test 失敗時に残すもの:

- 最終 screenshot。
- step log。
- device log。
- fixture version(収録曲データのバージョン)。
- 実行時の app config。

## 推奨ディレクトリ構成

```text
.
├── docs/
│   └── harness-engineering.md
├── lib/
│   ├── main.dart
│   └── src/
├── test/
│   ├── unit/
│   ├── widget/
│   ├── golden/
│   └── fixtures/
├── integration_test/
├── tool/
│   ├── test_harness/
│   └── ci/
└── .github/
    └── workflows/
```

monorepo 化する場合は、各 package にスクリプトを重複させず、workspace 側に orchestration を寄せる。

## 品質ゲート

Pull Request の最低ライン:

- 依存解決が成功する。
- format check が通る。
- static analysis が通る。
- unit test と widget test が通る。
- 意図しない golden 差分が含まれていない。

main branch の推奨ライン:

- Pull Request の最低ライン。
- golden test。
- integration smoke test。
- 対象 platform の build sanity check。

release 前の推奨ライン:

- main branch の推奨ライン。
- expanded integration suite。
- 少なくとも 1 台の実機での exploratory test(実発音・レイテンシ・オーディオセッションを含む)。
- accessibility smoke check。
- 複数 locale を出す場合は localization smoke check。

## Flaky Test ポリシー

flaky test はテストの問題ではなく、ハーネスの欠陥として扱う。

発生時の流れ:

1. 失敗 artifact を保存する。
2. owner を決める。
3. 原因候補を分類する。
4. 修正するか、issue link 付きで quarantine する。
5. 修正後に quarantine を解除する。

分類候補:

- app race。
- test race。
- device instability。
- audio scheduling / timing dependency。
- timeout。
- animation。
- clock。
- platform behavior。

ルール:

- 理由を残さずテストを削除しない。
- 最初の対応として timeout を安易に伸ばさない。
- sleep より明示的な同期を優先する(再生スケジュールの検証は実時間ではなく `fake_async` / fake clock で進める)。

## テストデータと Fixture

fixture は小さく、意図が分かる形で version 管理する。

ルール:

- 読みやすさが上がる小さな fixture は test 内 inline でもよい。
- 再利用する fixture は `test/fixtures` に置く。
- データの素性ではなく、検証したい振る舞いで命名する。
- 本番データ snapshot は原則使わない。使う場合は sanitize と review を必須にする。
- schema 変更時は migration note を残す。

fixture に持たせたい metadata:

- schema version。
- source または generator。
- 想定する検証範囲。
- 既知の制約。

## Audio Harness(本アプリ固有)

発音・再生は `AudioEngine` 境界で制御する。

優先順位:

1. unit / widget test では `AudioEngine` の fake(呼び出しを記録するだけで音を鳴らさない)。
2. 再生スケジュール(音符の発音タイミング・テンポ追従・メトロノーム)は pure Dart のロジックとして切り出し、`fake_async` で実時間なしに検証する。
3. 実音色・レイテンシ・OS のオーディオセッション挙動は実機 / エミュレータでの手動確認。
4. 音源プラグインのアダプタ(`AudioEngine` の本番実装)は `SystemClock` と同様に自動テストの対象外とする(ADR 0004)。

デフォルトのテストスイートは、実際のスピーカー出力や音源アセットのロードに依存させない。

## Golden Test 方針

golden test は、安定した視覚契約を守るために使う。

visual regression とは、意図しない見た目の変化を検出すること。release blocker にするとは、golden test や visual regression test が失敗した場合にリリースを止める運用にする、という意味。

初期方針:

- launch 初期は visual regression を release blocker にしない。
- 共有 UI component と主要画面の見た目が安定してから、release blocker 化を再検討する。
- blocker にする前に、false positive の少なさ、差分確認フロー、更新責任者を決める。

向いている対象:

- 共有コンポーネント(鍵盤・譜面・曲カード)。
- empty / loading / error / success state。
- 密度が高く崩れやすい layout(譜面・鍵盤)。
- responsive behavior が重要な画面。

向いていない対象:

- animation が中心の画面(再生中の playhead 移動など)。
- copy が頻繁に変わる画面。
- remote image が支配的な画面。
- 価値が低い全画面 snapshot。

golden test では次を固定する:

- device size。
- text scale。
- theme。
- locale。
- font loading behavior。

加えて、golden 画像は実行 platform のフォントレンダリングに依存する。開発機(Windows / macOS)と CI(ubuntu-latest)で生成画像が一致しない場合があるため、**基準 platform を CI と同じ Linux に固定する**。

- golden の生成・更新(`--update-goldens`)は基準 platform 上で行う。
- ローカルが基準 platform と異なる OS の場合、platform 差由来の golden 失敗を理由にローカルで golden を更新しない。
- 運用が難しい場合は、golden test に tag を付けて CI でのみ比較する構成に切り替える(ADR 0002 で採用)。

## CI 設計

CI provider は GitHub Actions を使う。

初期 CI:

1. checkout。
2. Flutter SDK install。
3. Pub cache restore。
4. dependency resolution。
5. format check。
6. static analysis。
7. unit / widget test(machine-readable report を `test-results/` に出力する。例: `flutter test --reporter expanded --file-reporter json:test-results/test-results.json`)。
8. 失敗 artifact upload(report を出力していないと upload 対象が空になる点に注意)。

追加候補:

- golden test job。
- Android integration job。
- iOS integration job。
- build job。
- release candidate validation job。

CI はフィードバック速度で分割する。速い job は、遅い emulator job を待たずに結果が返るようにする。

GitHub Actions では、まず `.github/workflows/check.yml` に format、analysis、unit / widget test を置く。Android / iOS の emulator job は、integration smoke test を追加する段階で別 job として分離する。

## ローカル開発体験

ローカルハーネスは次の問いにすぐ答えられる必要がある。

- この checkout は正常か。
- CI と同じチェックを走らせるには何を実行するか。
- golden を更新するには何を実行するか。
- integration test の失敗をどう再現するか。
- artifact はどこに出るか。
- app state をどうリセットするか。

将来のコマンド候補:

```sh
tool/check
tool/test
tool/test_golden
tool/test_integration
tool/doctor
```

Windows をサポートするため、PowerShell 版を用意するか、Dart 製の cross-platform tool に寄せる。

## 初期決定事項

| Topic | 推奨 | 理由 |
| --- | --- | --- |
| Target platforms | Android と iOS | 両 platform を launch scope として扱う |
| Backend authentication | 初期 scope では不要 | 認証前提の test harness を先に作り込まない |
| Offline support | オフライン完結(通信しない) | 収録曲・自作曲はすべて端末内。sync harness を持たない |
| Locale | 単一 locale(日本語) | localization harness は過剰に作らない |
| Audio | `AudioEngine` 境界 + サンプル音源プラグイン | 発音・再生を fake 可能にし、実音は実機確認に寄せる(ADR 0004) |
| Flutter version | FVM で固定 | ローカルと CI を揃える |
| State reset | test entry point に明示 API を置く | 端末状態への依存を避ける |
| Audio test | fake AudioEngine + fake_async でスケジュール検証 | flaky と実発音依存を減らす |
| Golden test | 共有 component(鍵盤・譜面・曲カード)から開始 | メンテナンスコストを抑える |
| Visual regression blocker | 初期 release blocker にはしない | UI が安定する前に blocker 化すると false positive が重くなる |
| Integration test | smoke journey から開始 | 起動と画面遷移を早期に保証する |
| CI artifact | 失敗時に upload | remote debugging を可能にする |
| Flaky handling | issue link 付き quarantine のみ許可 | 静かな coverage loss を防ぐ |
| Score data supply | 同梱 Dart コード(`ScoreRepository` 境界) | パース失敗系を増やさない(ADR 0003) |
| Library persistence | shared_preferences + JSON(`LibraryStore` 境界) | KB 級の単一スナップショット。複雑化しない(ADR 0001) |
| Extra platform capability | 不要(マイク入力・録音は初期 scope 外) | audio 出力以外の permission harness は初期 scope から外す |
| CI provider | GitHub Actions | repository 内の workflow として管理しやすい |
| Monorepo tool | 使わない想定 | 単一 Flutter app として始め、必要になるまで導入しない |

## 未決質問

現時点の主要なハーネス方針は決定済み。次に未決化する項目は、実 feature の要求が出た時点で追加する。具体的な音源プラグインの選定(サンプル再生 vs ソフトシンセ)は ADR 0004 の方針の範囲で、再生実装に着手する時点で確定する。

## 最初の実装マイルストーン

1. Flutter app skeleton を作る。
2. Flutter / Dart version を固定する。
3. baseline analysis options を追加する。
4. `test/unit` と `test/widget` を作る。
5. smoke widget test を追加する。
6. 決定的な app config interface(差し替え境界)を追加する。
7. format、analysis、test の CI を追加する。
8. 失敗 artifact upload を追加する。
9. integration smoke test を追加する。
10. 共有 UI primitive(鍵盤・譜面・曲カード)ができた段階で golden test を追加する。

## レビュータイミング

この文書は次のタイミングで見直す。

- project skeleton 作成後。
- 最初の実 feature 実装後。
- integration test を CI に入れる前。
- 初回 beta release 前。
- 同じ種類の flaky failure が繰り返された後。

ハーネスエンジニアリングはプロダクトと一緒に育てる。ただし、約束は変えない。誰でも再現でき、誰でも診断でき、チームが品質シグナルを信頼できる状態を保つ。
