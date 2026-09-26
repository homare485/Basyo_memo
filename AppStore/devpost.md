# Devpost 提出用テキスト（Basyo Memo）

Devpost は英語で書くのが基本です。下に日本語の訳も付けています。
---------------------------------------------------------------

## Tagline（一言・80字以内）

Put your to-dos where they actually happen.

（訳: やることを、それをする場所に置こう。）

## Elevator pitch（短い紹介文）

Basyo Memo turns your to-do list into a place you walk through. Choose a place,
see its floor plan, step into a room, and deal with what is waiting there.

（訳: Basyo Memo は、ToDo リストを「歩いて回れる場所」に変えるアプリです。
場所を選び、間取りを開き、部屋に入って、そこにあるやることを片付けます。）

## Inspiration

Every to-do app I tried gave me the same thing: one long vertical list. "Restock
trash bags", "Check the detergent", "Return the library book" — all stacked on top
of each other, even though they happen in completely different places.

But that is not how I remember my own tasks. I remember them as places. The kitchen
is where the trash bags are. The bathroom is where the shampoo runs out. A list
flattens that. I wanted the place itself to be the interface.

（訳: どのToDoアプリも、やることを縦一列に並べるだけでした。でも人は、やることを
「場所」として覚えています。リストはその感覚を潰してしまう。場所そのものを
インターフェースにしたい、というのが出発点です。）

## What it does

Basyo Memo organizes tasks in three layers: Place → Space → Task.

- Pick a place — home, campus, work — and its floor plan appears.
- Tap a room and you see only what is waiting in that room.
- Finish a task and it leaves the room. The space gets quieter.
- Dots in each room show what is still waiting, so one glance tells you where
  things are piling up.
- Build your own floor plan: add rooms in three sizes and they pack themselves in.
- Everything stays on the device. No account, no cloud, works offline.

（訳: PLACE → SPACE → TASK の3階層。場所を選ぶと間取りが現れ、部屋に入ると
そこのやることだけが見えます。終わらせると部屋から消え、空間が片付いていきます。
部屋は大中小から選んで自分で足せます。データは端末の中だけです。）

## How I built it

- SwiftUI and SwiftData on iOS 26, built entirely with Apple's own frameworks.
- The floor plan is not stored as coordinates. Each room only knows its size
  (small, medium, large) and the order it was added. The layout is computed every
  time by packing rooms into a two-column grid, so a broken layout cannot exist.
- The house keeps a fixed outer wall and squeezes rooms as they are added, then
  grows downward once rooms hit a minimum readable height.
- Navigation uses SwiftUI's zoom transitions, so pressing a place expands it into
  its floor plan, and a room expands into its tasks — you feel like you are moving
  inward rather than switching screens.
- RevenueCat powers a single non-consumable purchase that lifts the limit of five
  places.
- Localized into English, Japanese and Traditional Chinese.

（訳: SwiftUI と SwiftData のみで構築。間取りは座標を保存せず、大きさと順番から
毎回計算するため、崩れた状態が存在し得ません。家は外壁を保ったまま部屋を詰め、
限界に達すると下に伸びます。画面遷移はズームで「奥に入っていく」感覚にしました。
課金は RevenueCat の買い切り1つ。3言語対応です。）

## Challenges I ran into

- Making a floor plan feel like a home, not a grid of tiles. The answer was to give
  rooms different sizes, draw shared walls instead of gaps, and put the room name at
  the bottom so the eye travels into the room.
- Adding rooms without ever breaking the layout. I prototyped the packing rules
  before writing any Swift, then kept the rule "positions are computed, never stored".
- Keeping the app readable on the smallest supported iPhone. Narrow rooms now drop
  their icon automatically instead of shrinking their name.

（訳: 「タイルの集まり」ではなく「家」に見せること、部屋を足しても絶対に間取りが
崩れないこと、小さい iPhone でも読めること。この3つが難所でした。）

## Accomplishments that I'm proud of

Completing a task does not just check a box — it removes an object from a room, and
the room visibly gets cleaner. The feeling of tidying a space, inside a to-do app.

（訳: やることを終わらせると、チェックが付くだけでなく「部屋から物が消える」。
ToDoアプリの中で、空間が片付いていく感覚を作れたことが誇りです。）

## What I learned

This was my first iOS app and my first App Store submission. I learned SwiftUI and
SwiftData by building one screen at a time, confirming each on a real simulator
before moving on. I also learned how much of shipping is not code: privacy
manifests, store metadata, localization, purchase configuration, review notes.

（訳: 初めての iOS アプリで、初めての App Store 提出でした。1画面ずつ作っては
確認する進め方で SwiftUI と SwiftData を学びました。出す作業のほとんどはコード
以外だった、というのも大きな学びです。）

## What's next for Basyo Memo

- Rearranging rooms by dragging, and editing a room's name, size and icon.
- Floor plan templates so a new place starts closer to a real home.
- Completed-task history, so you can look back at what a place has been through.

（訳: 部屋のドラッグ並び替え、名前・大きさ・アイコンの変更、間取りテンプレート、
完了したやることの履歴。）

## Built with

swift, swiftui, swiftdata, ios, xcode, revenuecat, storekit

## Try it

- App Store: https://apps.apple.com/app/id6815061856
- Support & privacy: https://homare485.github.io/basyo-memo-site/
- Judges: use the offer code below to unlock Pro for free.
  （承認後に発行したコードを貼る）

---------------------------------------------------------------

# デモ動画の字幕（英語・各カット5〜8秒）

00:00  Every to-do app gives you one long list.
00:05  Basyo Memo gives you a place.
00:11  Choose where you are.
00:17  Your floor plan appears.
00:23  Step into the kitchen — only kitchen tasks are here.
00:31  Finish one, and it leaves the room.
00:38  The room gets quieter. So does the whole house.
00:45  Add the places you actually go.
00:50  Basyo Memo. Put your to-dos where they happen.

（訳）
00:00 どのToDoアプリも、長い1本のリストを渡してくる
00:05 Basyo Memo が渡すのは「場所」
00:11 いまどこにいるかを選ぶ
00:17 間取りが現れる
00:23 キッチンに入る。ここにはキッチンのやることだけ
00:31 ひとつ終わらせると、部屋から消える
00:38 部屋が静かになる。家ぜんたいも
00:45 自分がよく行く場所を足していく
00:50 Basyo Memo. やることを、それをする場所に。
