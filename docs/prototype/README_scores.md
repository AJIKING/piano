# 収録曲データ(プロトタイプ資料)

アプリの収録曲データの**出典は `songs.json`**。すべて著作権が満了した
**パブリックドメイン**の童謡・唱歌・外国曲(片手・単旋律)で、`lib/src/data/score_data.dart`
に反映している。曲の追加・編集はまず `songs.json` を直し、生成スクリプトで再生成する:

```sh
dart run docs/prototype/gen_score_data.dart   # songs.json → lib/src/data/score_data.dart
dart format lib/src/data/score_data.dart
```

新しい曲を足すときは `gen_score_data.dart` の `_slug` にも id を追加する。

## songs.json 収録曲(全11曲)

featured = きらきら星。以下 10 曲を既定でシードする。

きらきら星 / ちょうちょう / かえるの合唱 / メリーさんの羊 / ロンドン橋 /
ゆかいなまきば / 聖者の行進 / 茶色の小瓶 / アルプス一万尺 / ジングルベル / きよしこの夜

## データ仕様(songs.json)

```
song   { id, title, origin, key, timeSignature, tempo, melody:[note] }
note   { note:"C4"/"F#5", dur }   // dur は4分音符=1.0 とした拍数
```

`score_data.dart` への変換ルール:

- `melody` を順に並べ、**拍位置は元の `dur` で積算**(休符は拍の隙間で表す)。
- 音価はアプリ許容の6種(0.25 / 0.5 / 1 / 1.5 / 2 / 3)のみ。元データの全音符 `4` は
  付点2分 `3`、`2.5` は2分 `2` に丸める(差分は休符)。
- 音域は練習鍵盤の **C3–B5** に収める。
- `id` はスラッグ化(featured=`twinkle-star`、他は曲ごとの英小文字スラッグ)。
  `origin` 先頭(" (" より前)を `composer`、`timeSignature` の分子を `beatsPerMeasure`、
  `tempo` を `defaultBpm` にマッピングする。

不変条件(`test/unit/data/bundled_score_repository_test.dart` の contract test が保証):
音名・音価が妥当 / 拍は非負・整列可能 / `id` 一意 / 既定 11 曲 / `beatsPerMeasure` 2–4 ・
`defaultBpm` 40–160 / 音域が C3–B5 内。

## ライセンス

収録曲はすべてパブリックドメイン(著作権保護期間満了)。曲を足す際も、JASRAC 等の
管理楽曲や保護期間内の曲は対象にしない。

---

旧版(クラシック18曲・Mutopia Project の MIDI 由来データと変換スクリプト
`convert_scores.dart` / `midi_to_score.py` / `bundled_scores.json` / `individual_scores/`)は
童謡データへの移行に伴い削除した。必要な場合は git 履歴から参照できる。

現行の生成スクリプトは `gen_score_data.dart`。
