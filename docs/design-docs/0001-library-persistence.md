# ADR 0001: ライブラリ(ユーザー楽譜・習得度)の永続化方式

- 状態: 採用
- 日付: 2026-06-14

## 決定

ライブラリ状態(ユーザーが作成・編集した楽譜、各曲の習得度・最終練習日時)の永続化は **shared_preferences + 単一 JSON キー + スキーマバージョン付きキー名**(`library_v1`)で行う。実装は `lib/src/data/prefs_library_store.dart` の `PrefsLibraryStore`(`LibraryStore` 境界の本番実装)。収録曲そのものは永続化対象外(同梱データ。ADR 0003)。

## 背景

`docs/product-spec.md` の未確定事項「ユーザー楽譜・習得度の永続化方式とスキーマバージョン」を決める。候補:

| 候補 | 評価 |
| --- | --- |
| shared_preferences | key-value のみ。プラグイン 1 つで Android / iOS 両対応。クエリ不可 |
| sqlite(sqflite 等) | クエリ・トランザクションが使えるが、スキーマ管理と依存が重い |
| hive 等の NoSQL box | 高速だが外部依存とデータ形式のロックインが増える |

## 理由

- 保存するデータは **数曲〜数十曲ぶんの楽譜(音符列)＋習得度の単一スナップショット**で、当面は KB 級。部分更新もクエリも不要で、全読み・全書きで十分。
- 依存を最小にする(`docs/architecture.md` の「必要になるまで複雑にしない」)。sqlite / hive の利点(クエリ、大量データ)は当面使い道がない。
- `LibraryStore` 境界の裏に隠れているため、要件が変わったら(曲数の大幅増、音符列の肥大化、検索)実装ごと差し替えられる。その時点で新しい ADR を書く。

## 結果

- 保存形式: `{"pieces": [{"id","title","composer","stars","masteryPercent","lastPracticedAt","notes":[{"pitch","beat","duration"}...]}...]}` を JSON 文字列 1 本でキー `library_v1` に保存。
- **壊れた JSON・型不一致のデータは例外にせず null を返し、初回起動として扱う**(自作曲が失われるが、アプリは必ず起動できる)。
- **スキーマを変えるときは新キー(`library_v2` …)を切り、旧キーから読み出して移行するコードを書く。** キー名は `PrefsLibraryStore.storageKey` に定数化する。
- 音符列が大きくなり 1 キー JSON が重くなったら、曲ごとのキー分割または sqlite への移行を新しい ADR で検討する。
