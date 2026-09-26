# Devpost「Additional info」の回答案

必須（*）と、応募する賞の欄だけ埋める。それ以外は空欄でよい。
--------------------------------------------------------------

## 必須・基本項目

| 質問 | 回答 |
|---|---|
| 1024×1024 のアイコンを添付したか | **Yes**（Basyo_memo/Assets.xcassets/AppIcon.appiconset/AppIcon.png） |
| 端末の枠なしスクリーンショットを添付したか | **Yes**（AppStore/shipaton/01〜05.png） |
| 初版を 2026/8/1〜9/30 に App Store 等でリリースしたか | **Yes**（承認・公開され次第。9/30 までに公開されていることが条件） |
| RevenueCat または スポンサーの従業員か | **No** |
| 作ったアプリの種類 | **iOS (iPhone and/or iPad)** |
| App Store の URL | https://apps.apple.com/app/id6815061856 （公開後に有効になる） |
| Google Play / Galaxy Store の URL | 空欄 |
| RevenueCat project ID | RevenueCat の Project settings からコピーして貼る |
| プレミアム機能を解除するコード | 承認後に発行するオファーコードを貼る |
| Growth Fund に興味があるか | Yes（資金提供の検討対象になるだけで、義務は生じない） |

## Next Gen Award（学生部門）— 応募する場合のみ

| 質問 | 回答 |
|---|---|
| 公開リポジトリの URL | https://github.com/homare485/Basyo_memo |
| 学生用メールアドレス | 大学のメールアドレス |
| 未成年に関する確認 | 18歳以上なら「該当なし」として確認にチェック |

--------------------------------------------------------------

## 応募する賞の回答（英語）

### HAMM Award（収益化）

Basyo Memo uses a single non-consumable in-app purchase: "Basyo Pro", ¥500 (about $3), bought once and kept forever. There is no subscription and no advertising.

The free tier is not a trial. It includes five places with unlimited rooms and unlimited tasks, so the entire core experience — choosing a place, opening its floor plan, stepping into a room and clearing what is waiting there — is fully usable without paying. The paywall appears at exactly one moment: when a user who already has five places taps "New place". That is the moment a user has decided the app is worth keeping, so the ask lands when the value is already proven rather than at first launch.

Why buy-once rather than a subscription: the app stores everything on the device, has no server and no account, and provides no ongoing service that would justify a recurring fee. Charging a subscription for something that keeps working offline forever would be dishonest, and users notice. A single small purchase matches what the app actually is.

RevenueCat manages the purchase, the entitlement and restoration across devices. The app never talks to StoreKit directly; a single class exposes "is this user Pro" to the interface, which keeps the paywall logic in one place.

The app is awaiting App Store approval at the time of submission, so no conversion data is available yet.

### RevenueCat Design Award

Please look at the floor plan screen. It is the heart of the app and the reason it exists.

- Tasks are not a list. A place opens as a simple floor plan, rooms have different sizes, and the tasks waiting in each room appear as small dots. One glance tells you which room is piling up.
- Completing a task does not just check a box. The task leaves the room, and the room visibly becomes emptier. The reward is a tidier space, not a strikethrough.
- Navigation uses zoom transitions, so a place expands into its floor plan and a room expands into its tasks. You feel like you are moving inward rather than switching screens. Coming back, the room you were in stays highlighted, so you know where you came from.
- Rooms are drawn as a real plan: shared walls, no gaps between rooms, the room name at the bottom so the eye travels into the room, and the icon dropped automatically when a room is too small to hold it.
- The floor plan is never stored as coordinates. Each room knows only its size (small, medium, large) and the order it was added; the layout is recomputed every time. A broken or overlapping plan cannot exist. The house keeps its outer wall and squeezes rooms as they are added, then grows downward once rooms reach a minimum readable height.
- The whole app is black, white and grey with generous space, so the only things that carry colour and weight are your own rooms and tasks.

### RevenueCat Peace Prize

Basyo Memo is a small, quiet tool rather than a cause, but it was built around one idea: a to-do list that grows without end makes people feel worse, while a room that visibly becomes tidier makes them feel better.

Tasks are shown only where they belong, so the user is never confronted with everything they have failed to do. Finishing one task empties a room a little. Nothing is gamified, there are no streaks to break, no notifications pressing the user, no account, no social comparison, and no data leaves the device.

For people who find long lists paralysing, being able to deal with only "what is waiting in this room" is a gentler way to start.

### Influencer Award — Productivity (Christopher Lawley)

Basyo Memo fits the productivity category as a focused, Apple-native tool rather than a feature-heavy organiser.

It is built entirely with SwiftUI and SwiftData, works fully offline, needs no account, and follows the platform's own conventions: zoom navigation transitions, context menus, haptics, Dynamic Type-friendly layouts, light and dark appearance, and localisation in English, Japanese and Traditional Chinese.

Its single opinionated idea — organise tasks by the place where they happen, and let the space become tidier as you work — is the kind of focused, well-made, distinctly Apple-platform app that this category is looking for.

### 審査員への補足（Additional notes for judges）

Basyo Memo is my first iOS app and my first App Store submission. It was designed and built during Shipaton, one screen at a time.

The app is currently in App Store review. The purchase flow has been verified end to end in the sandbox, and a recording of the full flow, including the purchase and the restore, was provided to App Review.

If the offer code is missing from this submission, the app was still in review at the time of writing; please contact me and I will provide one immediately.

--------------------------------------------------------------

## 空欄でよい賞

Build in Public / Grand Prize（成長実績）/ Catvertising（RevenueCat Ads）/
Best Game / Ship Kotlin Everywhere / Most Viral（Noise）/ Best App for Galaxy /
Idea to Income（Replit）/ Keep Them Coming Back（OneSignal）/
The Growth Loop（Layers）/ Funnel Vision（Stripe）
