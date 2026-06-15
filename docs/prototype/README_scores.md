# デフォルト楽譜データ（リクエスト16曲対応・最終版）

リクエスト16曲のうち **14曲を本物のフル尺データで収録**しました（Mutopia ProjectのPDソースから生成）。
未収録は2曲のみです。

## bundled_scores.json 収録曲（全19曲・計23,281音）

### リクエストから収録できた13曲
| 曲 | 音符 | feat |
|---|---|---|
| ソナタ K.545 第1楽章 | 1288 | |
| ノクターン Op.9-2 | 1243 | |
| 月の光 | 1494 | ★ |
| アラベスク第1番（ドビュッシー） | 1458 | |
| ジ・エンターテイナー | 2621 | |
| 幻想即興曲 Op.66 | 3014 | |
| カノン（パッヘルベル） | 138 | |
| 月光ソナタ 第1楽章 | 1144 | ★ |
| 月光ソナタ 第3楽章 | 4469 | |
| アヴェ・マリア（シューベルト） | 2335 | |
| 小犬のワルツ Op.64-1 | 1370 | |
| アラベスク（ブルクミュラー） | 283 | |
| メヌエット ト長調 | 16 | |
| 歓喜の歌 | 30 | |

### 前回からの継続収録（リクエスト外・5曲）
前奏曲ハ長調BWV846 / 前奏曲ホ短調Op.28-4 / エリーゼのために★ / ジムノペディ第1番★ / きらきら星

個別の.jsonは individual_scores.zip にも入れてあります。

## 未収録の2曲と理由

| 曲 | 状況 |
|---|---|
| 朝（グリーグ Morning Mood） | **Mutopia未収録**。IMSLP/MuseScoreはこの作業環境から取得不可 |
| 愛の夢 第3番（リスト） | **Mutopia未収録**（"制作中"記載）。同上 |

この2曲は、IMSLP（ブラウザで簡単にDL可）等のPD .mid を渡してもらえれば即JSON化できます。

## 残り2曲を足す手順（.mid → JSON）

1. IMSLP等でPDの .mid を入手（曲名で検索、ライセンス要確認）
2. `python3 midi_to_score.py 曲.mid --id <id> --title "<曲名>" --composer "<作曲者>" -o out.json`
3. out.json を bundled_scores.json の `pieces` に追加

## データ仕様
```
Piece { id, title, composer, beatsPerMeasure, defaultBpm, featured, isUserCreated:false, notes:[Note] }
Note  { pitch:"C4"/"F#5", beat, duration, velocity }
```
- beat/duration は4分音符=1拍の絶対拍。3/8・6/8・9/8等は beatsPerMeasure が小数（1.5/4.5等）になりますが、
  再生タイミングは全曲4分音符基準で統一。
- 強弱無指定の曲は拍頭アクセント(88/76/68)を自動付与、元の強弱がある曲はそれを保持。
- 注：アヴェ・マリアは原譜のテンポ表記でdefaultBpm=24（大きな拍の刻み）。速く感じる/遅く感じる場合は
  defaultBpmを調整してください。カノンはMutopiaの簡易版のため音符数控えめです。月光第3楽章(Presto)は原MIDIにテンポ指定が無くdefaultBpm=60になっているので、速く演奏したい場合は上げてください。

## ライセンス
Mutopiaの楽譜はPD/CC（多くはPublic DomainまたはCC-BY-SA）。商用配布時、CC-BY-SAのものは
typesetterのクレジット表示が必要。各曲の出典は元.lyのcopyright/maintainer欄で確認できます。
