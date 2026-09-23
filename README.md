# Basyo Memo（場所メモ）

やることを、それをする場所に置く iOS アプリ。

普通の ToDo アプリはやることを縦一列に並べますが、Basyo Memo は
**PLACE → SPACE → TASK** の3階層で、場所そのものをインターフェースにします。

場所を選ぶと間取りが現れ、部屋に入るとそこのやることだけが見えます。
終わらせると、やることは部屋から消え、空間が少しずつ片付いていきます。

- App Store: 審査中（2026-09-24 提出）
- サポート / プライバシー: https://homare485.github.io/basyo-memo-site/
- RevenueCat Shipaton 2026 への提出作品

## 技術

| | |
|---|---|
| UI | SwiftUI（iOS 26.0 以上・iPhone 縦向き専用） |
| データ | SwiftData（端末内のみ。アカウント・サーバーなし） |
| 課金 | RevenueCat（買い切りの Pro。無料は場所3つまで） |
| 対応言語 | 日本語・英語・繁体字中国語（対応外の言語は英語） |

## 構成

```
Basyo_memo/
├── MyApp.swift              起動時の準備（DB・課金の初期化）
├── ContentView.swift        NavigationStack
├── Models/
│   ├── Place.swift          場所
│   ├── Space.swift          部屋（大きさ RoomSize）
│   ├── TaskItem.swift       やること
│   └── SampleData.swift     初回のサンプル
├── Purchases/
│   ├── PurchaseConfig.swift APIキー・権利ID・無料の上限
│   └── ProAccess.swift      Pro の判定・購入・復元
├── Views/
│   ├── PlaceHomeView.swift      画面1: 場所を選ぶ
│   ├── SpatialView.swift        画面2: 間取り
│   ├── SpaceDetailView.swift    画面3: 部屋の中
│   ├── AddTaskView.swift        やることを置く
│   ├── AddRoomView.swift        部屋をつくる
│   ├── AddPlaceView.swift       場所をつくる
│   ├── ProPaywallView.swift     Pro の案内
│   └── FloorPlanLayout.swift    間取りの配置計算
└── Localizable.xcstrings    3言語の文言（64件）
```

## 間取りの考え方

部屋の位置は**保存していません**。各部屋が持つのは「大きさ（小・中・大）」と
「追加した順番」だけで、配置は毎回 `FloorPlanLayout` が計算します。

- 横2列のマス目に、追加順で「上から見て最初に入る場所」へ置く
- 入らなかったマスは空きとして残り、そこから部屋を追加できる
- 家は外壁の大きさを保ったまま部屋を詰め、1段が64ptに達したら下に伸びる

位置を保存しないので、部屋が重なったりはみ出したりする状態が存在しません。

## AppStore/

提出用の素材を置いています（スクリーンショット、掲載文、Devpost 用テキスト）。
