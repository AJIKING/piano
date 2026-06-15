# ピアノノート(package: etude)

ピアノの練習と楽譜づくりを 1 アプリで行う Flutter アプリ。収録曲・自作曲の譜面を見ながら鍵盤で弾き、テンポ可変で再生し、楽譜エディタで音符を編集する。オフライン完結・バックエンドなし。

## ドキュメント

- 仕様: [docs/product-spec.md](docs/product-spec.md)(プロトタイプ: [docs/prototype/etude-piano-app.html](docs/prototype/etude-piano-app.html))
- アーキテクチャ: [docs/architecture.md](docs/architecture.md)
- テスト計画: [docs/test-plan.md](docs/test-plan.md)
- ハーネス方針: [docs/harness-engineering.md](docs/harness-engineering.md)

## セットアップ

Flutter SDK は **3.44.1**(`.fvmrc` で固定。CI と同一バージョン)。

```sh
flutter pub get
```

## 開発コマンド

CI(`.github/workflows/check.yml`)と同じチェック:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --exclude-tags golden --reporter expanded
```

golden の更新(基準 platform = Linux 上でのみ実行。詳細はハーネス方針の Golden 節 / ADR 0002):

```sh
# Windows / macOS では実行しない。.github/workflows/golden.yml を workflow_dispatch して
# 生成した baseline(artifact golden-baselines)を test/golden/goldens/ にコミットする。
flutter test --update-goldens test/golden
```

integration smoke test(エミュレータ / シミュレータを起動してから実行。CI では `.github/workflows/integration.yml` が main push 時に実行):

```sh
flutter test integration_test -d <device-id>
```

## プロジェクト構成

- `lib/` — アプリ本体(`docs/architecture.md` のレイヤー構成に従う)。
- `test/` — unit / widget / golden(`lib/src/` をミラー)。
- `integration_test/` — 起動 smoke journey。
- `docs/` — 仕様・アーキテクチャ・テスト計画・ハーネス方針・ADR・プロトタイプ。
