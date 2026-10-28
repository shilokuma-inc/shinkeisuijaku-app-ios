# 絵の SVG と変換

`illustrations.svg` は、Discussion #4「初期開発」の Q1 の回答に添付された 13 種類の絵の原本（手を加えていない）。
アプリはこれを `convert.py` で SwiftUI の `Path` のコードに変換した `Shinkeisuijaku/Illustrations/Generated/` を使う。
SVG をアプリに同梱しない（`Shinkeisuijaku/` の下に置いたファイルはすべてアプリに入るため、原本はここに置く）。

## 書き出し方

```bash
# リポジトリ直下で
python3 Tools/illustrations/convert.py           # Generated/ を書き出し直す
python3 Tools/illustrations/convert.py --check   # Generated/ が SVG と合っているかだけ確かめる（合わなければ終了コード 1）
```

- 絵を直すときは、SVG を差し替えてから書き出し直す。`Generated/` を手で直さない
- 1 つの絵 = `<g id="…">`（cat・dog・rabbit・panda・frog・chick・fox・penguin・apple・strawberry・bear・suika・star）。
  id は `Picture` の case 名と同じ。中の `path`・`circle`・`ellipse` 1 つが `IllustrationPart` 1 つになり、上から順に重ねて描く
- 座標は 1 つの図の枠（108×108。`Metrics.artCanvasSize`）の中の値。SVG の `<g transform="translate(4 4)">` の分を足し、シートの並びの変形は使わない
- 色は `Palette` の絵の色の名前に置き換える。輪郭線の太さ 2.2 は `Metrics.artOutlineWidth`、ほかの線（表情・ヒゲ・くき）の太さは SVG の値のまま書き出す
- 対応している SVG: 要素は `path`・`circle`・`ellipse`、パスの命令は絶対座標の `M`・`L`・`Q`・`C`・`A`（円の弧で回転なし）・`Z`、変形は `ellipse` / `circle` の `rotate(角度 x y)`。
  知らない色・要素・命令があれば書き出さずに止まる（見た目が SVG と変わらないようにするため）
- Python 3 の標準ライブラリだけで動く
