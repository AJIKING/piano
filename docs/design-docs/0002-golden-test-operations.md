# ADR 0002: golden test の基準 platform と baseline 運用

- 状態: 採用
- 日付: 2026-06-14

## 決定

- golden test の**基準 platform は CI と同じ Linux(ubuntu-latest)**とする。
- 非 Linux(Windows / macOS の開発機)では、golden test は `skip: !Platform.isLinux` で**自動 skip** する(`test/golden/golden_setup.dart` の `skipGoldens`)。ローカルの `flutter test` は golden 抜きで全 green を保つ。
- baseline 画像(`test/golden/goldens/`)は、**`.github/workflows/golden.yml`(workflow_dispatch)で生成し、artifact `golden-baselines` をダウンロードしてコミットする**。ローカルで `--update-goldens` した画像はコミットしない。
- golden test には `@Tags(['golden'])` を付け、`.github/workflows/check.yml` の test ステップは `--exclude-tags golden` で除外し、専用 `golden` job で比較する。

## 背景

golden 画像はフォントレンダリング(ヒンティング・アンチエイリアス)が実行 platform に依存し、Windows 開発機と CI(Linux)で同じコードから生成した画像が一致しない。候補:

| 候補 | 評価 |
| --- | --- |
| platform ごとに baseline を持つ | 画像が platform 数だけ増え、更新責任が曖昧になる |
| 許容誤差つき比較(カスタム comparator) | false negative の調整コストが高く、視覚契約が緩む |
| 基準 platform を Linux に固定し、非 Linux は skip | baseline が 1 系統。CI で常に比較できる。ローカルでは見た目検証ができない制約のみ |

`docs/harness-engineering.md` の Golden 方針(基準 platform を CI と同じ Linux に固定する / 運用が難しい場合は tag を付けて CI でのみ比較する)に従い、3 案目を採用する。本プロジェクトの開発機は Windows のため、この運用が必須。

## 理由

- ローカルと CI の品質シグナルを両立する: ローカルは「golden 以外の全テスト green」、CI は「baseline と一致」という明確な責務分担になる。
- baseline の生成経路を workflow に一本化することで、「どの環境で生成した画像か」が常に追跡できる(ハーネス方針の再現可能性)。
- タグ + `--exclude-tags` により、baseline 未コミットの過渡期でも check.yml を赤くしない。

## 結果

- bootstrap 手順: golden.yml を workflow_dispatch で実行 → artifact `golden-baselines` をダウンロード → `test/golden/goldens/` に展開してコミット。
- check.yml の `golden` job(`flutter test --tags golden test/golden`、失敗時は diff を artifact upload)が、`--exclude-tags golden` の test ステップと並走する。
- UI 変更で golden が意図して変わる PR では、同じ手順で baseline を再生成して差分をコミットする。Windows / macOS で生成した画像をコミットした時点でこの運用は壊れるため、レビューで弾く。
- visual regression を release blocker にするかは引き続き `docs/harness-engineering.md` の初期方針(blocker にしない)に従う。
