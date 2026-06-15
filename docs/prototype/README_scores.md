# デフォルト楽譜データ 一式（フル尺対応版）

ピアノアプリ用のデフォルト楽譜データと、曲を追加するための変換ツールです。
収録曲のうち4曲は **Mutopia Project のパブリックドメイン楽譜から実データを生成** した
フル尺（または曲の自然な区切りまで）の本物です。

## 収録7曲

| id | 曲 | 出典 | 音符数 | 長さ | featured |
|---|---|---|---|---|---|
| `twinkle` | きらきら星 | 手打ち | 42 | 12小節 | |
| `ode_to_joy` | 歓喜の歌（第九より） | 手打ち | 30 | 8小節 | |
| `minuet_g` | メヌエット ト長調 | 手打ち | 16 | 4小節 | |
| `gymnopedie_1` | ジムノペディ 第1番 | Mutopia(全曲) | 282 | 47小節 | ★ |
| `bach_prelude_c` | 前奏曲 ハ長調 BWV846 | Mutopia(全曲) | 549 | 35小節 | |
| `chopin_prelude_e_minor` | 前奏曲 ホ短調 Op.28-4 | Mutopia(全曲) | 600 | 25小節 | |
| `fuer_elise` | エリーゼのために | Mutopia(全曲ABACA) | 905 | — | ★ |

- 上3曲は初級用の短い主旋律アレンジ（音高は正確、リズムは簡略）。
- 下4曲はMutopiaのLilyPondソースからMIDIを生成→JSON化した本物のフル尺。
- 強弱が楽譜に無い曲（Bach・エリーゼ）は、拍頭88・拍76・細分68で軽くアクセントを付与済み。
  Satie・Chopinは元の強弱がそのまま入っているので、7層サンプルの表情が出ます。

## データ仕様

```
Piece { id, title, composer, beatsPerMeasure, defaultBpm, featured, isUserCreated:false, notes:[Note] }
Note  { pitch:"C4"/"F#5", beat, duration, velocity(0-127) }
```

- `beat`/`duration` は **4分音符 = 1拍** の絶対拍。`defaultBpm` も4分音符基準。
- `pitch` はシャープ表記、MIDI 60 = "C4"。
- 補足：3/8拍子の曲（エリーゼ）は `beatsPerMeasure` が **1.5**（4分音符換算）。
  小節グルーピング用の値で、再生タイミング自体は他曲と同じ4分音符基準なので問題ありません。

## 曲を追加する（実際に使った手順）

この一式は以下のパイプラインで作りました。同じ手順で20曲まで増やせます。

```bash
# 1) MutopiaのGitHubから .ly ソースを取得（曲ごとのパスはサイトで確認）
base=https://raw.githubusercontent.com/MutopiaProject/MutopiaProject/master/ftp
curl -o piece.ly "$base/ChopinFF/O28/Chop-28-7/Chop-28-7.ly"

# 2) 古い構文を現行LilyPondへ更新し、MIDIを生成
convert-ly -e piece.ly
lilypond -o piece piece.ly        # .ly内に \midi {} があればMIDIが出る

# 3) 本ツールでアプリのJSONスキーマへ変換
python3 midi_to_score.py piece.midi \
    --id chopin_28_7 --title "前奏曲 イ長調 Op.28-7" --composer "F. Chopin" -o out.json
```

出力された各曲JSONを `bundled_scores.json` の `pieces` 配列に足すだけです。
全曲が長すぎる場合は、自然な区切りの拍位置で `notes` を切ればOK（小節頭＝
`beat % beatsPerMeasure == 0` の位置で切ると綺麗）。

### ライセンス
Mutopia Project の楽譜はパブリックドメイン版に基づき、CC（Public Domain / CC-BY-SA）で
配布されています。今回使った4曲はいずれもソース内に Public Domain / CC 表記あり。
商用アプリに載せる場合、CC-BY-SAのものは帰属表示（typesetterのクレジット）を忘れずに。
各 .ly の `copyright` / `maintainer` 欄を控えておいてください。

### 変換ツールのオプション
- `--channel N` … 右手だけ等、特定MIDIチャンネルのみ抽出
- `--octave-offset -1` … 音源が60をC3扱いする場合の補正
- `--bpm N` … 検出テンポを上書き
