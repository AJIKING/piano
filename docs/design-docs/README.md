# design-docs(ADR)

将来覆す可能性のある設計上の決定を Architecture Decision Record(ADR)として記録する。

- 1 決定 = 1 ファイル。連番 + 内容がわかるファイル名(`NNNN-topic.md`)。
- 各 ADR は「決定 / 背景(検討した候補)/ 理由 / 結果(決定がもたらす制約・運用)」を簡潔に書く。
- 決定を覆すときは、旧 ADR を書き換えるのではなく新しい ADR を追加して旧 ADR から参照する(経緯を残す)。

## 一覧

| 番号 | タイトル | 状態 |
| --- | --- | --- |
| [0001](0001-library-persistence.md) | ライブラリ(ユーザー楽譜)の永続化方式 | 採用 |
| [0002](0002-golden-test-operations.md) | golden test の基準 platform と baseline 運用 | 採用 |
| [0003](0003-score-data-supply.md) | 収録曲データの供給方法 | 採用 |
| [0004](0004-audio-engine.md) | ピアノ音源・再生エンジンの方式 | 採用 |
