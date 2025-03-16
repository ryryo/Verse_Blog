## Verseコードスタイルガイドライン

### 命名規則
- 命名パターン:
  - `IsX`: ロジック変数（質問形式）
  - `OnX`: フレームワークで呼び出されるオーバーロード可能な関数
  - `SubscribeX`: Xという名前のフレームワークイベントにサブスクライブ
  - `MakeX`: コンストラクタをオーバーロードせずにインスタンス作成
  - `CreateX`: ライフタイム開始を含むインスタンス作成
  - `DestroyX`: ロジックライフタイムを終了
  - `X:x`: クラスxの単一インスタンスの場合、「X」と呼ぶ

### 失敗コンテキスト
#### 大原則
- Verseでは、失敗する可能性のある操作はすべて、その失敗を適切に処理できる「失敗コンテキスト」内で実行する必要があります
- 失敗する可能性のある操作（`<decides>`エフェクトを持つ操作）は、失敗した場合の動作が明確に定義されたコンテキスト内でのみ許可されます
- 以下の操作は`<decides>`エフェクトを持ち、失敗コンテキスト内でのみ実行可能です：
  - 配列やマップのインデックスアクセス（範囲外や存在しないキーの場合に失敗）
  - オプション型からの値の取得（値がない場合に失敗）
  - `<decides>`エフェクト指定子を持つ関数の呼び出し
  - 一部のデバイスメソッド（例：`GetFortCharacter[]`）
  - マップへの代入操作（例：`map[key] = value`）

- 失敗コンテキストとして機能するVerseの構文：
  1. `if`文の条件節
  2. `or`演算子の左オペランド
  3. `and`演算子の左オペランド
  4. `for`ループの条件節
  5. `logic`マクロの節

- 失敗コンテキスト内では、操作が失敗した場合の処理が明確に定義されています：
  - `if`文では条件が偽になる
  - `or`演算子では右オペランドが評価される
  - `and`演算子では式全体が偽になる
  - `for`ループではそのイテレーションがスキップされる

#### スタイルガイドライン
- 単一行での失敗可能な式は3つまでに抑える
```verse
if (Damage > 10, Player := FindRandomPlayer[], Player.GetFortCharacter[].IsAlive[]):
    EliminatePlayer(Player)
```
- 各式で3単語以上使用する場合は、式の数を2つまでにする
```verse
if (Player := FindAlivePlayer[GetPlayspace().GetPlayers()], Team := FindEmptyTeam[GetPlayspace().GetTeamCollection().GetTeams()]):
    AddPlayerToTeam(Player, Team)
```
- 「9単語より多い」場合は複数行の形式を使用
- 依存する失敗可能な式はグループ化する
```verse
if:
    Player := FindRandomPlayer[]
    Character := Player.GetFortCharacter[]
    Character.GetHealth() < 10
then:
    EliminatePlayer(Player)
```
- 複数の失敗可能な条件は`<decides>`関数にグループ化して再利用を検討
```verse
GetRandomPlayerToEliminate()<decides><transacts>:player=
    Player := FindRandomPlayer[]
    IsAlive[Player]
    not IsInvulnerable[Player]
    Character := Player.GetFortCharacter[]
    Character.GetHealth < 10
    Player

if (Player := GetRandomPlayerToEliminate[]):
    Eliminate(Player)
```
- 同様のガイドラインが`for`ループ内の式にも適用
```verse
set Lights = for:
    ActorIndex -> TaggedActor : TaggedActors
    LightDevice := customizable_light_device[TaggedActor]
    ShouldLightBeOn := LightsState[ActorIndex]
do:
    if (ShouldLightBeOn?) then LightDevice.TurnOn() else LightDevice.TurnOff()
    LightDevice
```
- 各失敗を個別に処理する場合は失敗コンテキストを分割も可能
```verse
if (Player := FindPlayer[]):
    if (Player.IsVulnerable[]?):
        EliminatePlayer(Player)
    else:
        Print("Player is invulnerable, can't eliminate.")
else:
    Print("Can't find player. This is a setup error.")
```

### 関数の効果と制約
- `no_rollback`エフェクトを持つ関数は条件式内で直接呼び出せない
```verse
# 以下はエラーになる
if (Device := GetDevice()):
    Device.Spawn()

# 代わりに例えば以下のように書く
Device := GetDevice()
if (Device?):
    Device.Spawn()
```
- `no_rollback`エフェクトを持つ関数は、条件式の外で呼び出し、その結果を変数に格納してから条件式で使用する
- デバイスのメソッド呼び出しや、状態を変更する関数は通常`no_rollback`エフェクトを持つ

### 関数
- 暗黙的な戻り値を優先（最後の式が戻り値）
```verse
Sqr(X:int):int =
    X * X # 暗黙的な戻り値
```
- GetX関数は失敗可能性がある場合`<decides><transacts>`でマーク
```verse
GetX()<decides><transacts>:x
```
- 拡張メソッドを優先（`Normalize(Vector)`より`Vector.Normalize()`）

### 演算
- 算術演算子
  - 基本演算: `+`（加算）、`-`（減算）、`*`（乗算）、`/`（除算）
  - `/` は整数除算のみ（小数点以下切り捨て）
  - `%`（モジュロ）演算子は使用不可。代わりにmod関数を利用：
```verse
# 例: mod関数を使用した剰余演算
if (C := Mod[A, B]):
    Print("{A} % {B} = {C}")
    if (C = 0):
        Print("{A} は偶数です！")
    else:
        Print("{A} は奇数です！")
```

- 比較演算子
  - `=`（等しい）、`<>`（等しくない）
  - `<`（未満）、`>`（より大きい）
  - `<=`（以下）、`>=`（以上）

- 論理演算子
  - `and`（論理積）、`or`（論理和）、`not`（否定）
  - 短絡評価あり（左から右に評価）

- 代入演算子
  - `:=` 変数への代入（一度のみ）
  - `set` キーワードで再代入

- 演算子の優先順位
  1. 括弧 `()`
  2. 単項演算子 `-`（負号）、`not`
  3. 乗除算 `*`、`/`
  4. 加減算 `+`、`-`
  5. 比較演算子 `=`、`<>`、`<`、`>`、`<=`、`>=`
  6. `and`
  7. `or`

### カプセル化
- クラスよりインターフェースを優先
- メンバーは`<private>`で保護し、必要に応じて`<internal>`を使用

### 型と属性
- 戻り値の型を明示的に注釈 (`: void`, `: int`)
- サスペンド関数は `<suspends>` でマーク
- オーバーライドメソッドは `<override>` でマーク
- NULL許容型には `?` サフィックスを使用
- 複数の属性は別々の行に記述

### イベント
- イベント名: サフィックスに`Event`を付ける
- ハンドラ名: プレフィックスに`On`を付ける
```verse
MyDevice.JumpEvent.Subscribe(OnJump)
```

### 非同期処理
#### 基本概念
- Verseの式は「イミディエイト式」と「非同期式」に分類される
  - イミディエイト式：1フレーム内に処理が完了する式
  - 非同期式：複数フレームにまたがる可能性がある式
- 非同期式は`<suspends>`エフェクト指定子を持つ関数内でのみ使用可能
```verse
MyAsyncFunction()<suspends>:void=
    # ここで非同期式が使える
```
- `<suspends>`関数に`Async`などの装飾を施さない
- 内部で発生を待つ`<suspends>`関数には、`Await`プレフィックスを追加可能
```verse
AwaitGameEnd()<suspends>:void=
    # ゲームの終了を待つ前に、別のものを設定
    GameEndEvent.Await()

OnBegin()<suspends>:void =
    race:
        RunGameLoop()
        AwaitGameEnd()
```

#### 非同期式の種類
1. **block**：直列処理
   - 上から順番に処理を実行し、各処理の完了を待ってから次に進む
```verse
block:
    ButtonA.InteractedWithEvent.Await() # ボタンAが押されるまで待機
    AnimationA.Play() # アニメーションAを再生
    Print("Animation A completed") # 完了メッセージ
```

2. **sync**：並行処理（論理積/AND的動作）
   - すべてのサブ表現を並行に実行し、**すべての処理が完了するまで**次に進まない
```verse
sync:
    block:
        ButtonA.InteractedWithEvent.Await()
        AnimationA.Play()
    block:
        ButtonB.InteractedWithEvent.Await()
        AnimationB.Play()
# 両方のブロックが完了した後にここに到達
```

3. **race**：並行処理（論理和/OR的動作）
   - すべてのサブ表現を並行に実行し、**いずれかの処理が完了したら**他の処理をキャンセルして次に進む
   - 複数のイベントのいずれかを待つ場合に使用する（例：複数のボタンのいずれかが押されるのを待つ）
```verse
race:
    block:
        ButtonA.InteractedWithEvent.Await()
        Print("Button A was pressed first")
    block:
        ButtonB.InteractedWithEvent.Await()
        Print("Button B was pressed first")
# どちらかのボタンが押された後にここに到達
```

4. **spawn**：非同期タスクの生成
   - 新しい非同期タスクを生成し、完了を待たずに次の処理に進む
```verse
spawn{LongRunningTask()} # 完了を待たずに次の処理へ
Print("This runs immediately")
```

5. **rush**：非同期タスクの優先実行
   - 新しい非同期タスクを生成し、そのタスクが完了するまで他のタスクを一時停止する
```verse
rush{HighPriorityTask()}
Print("This runs after HighPriorityTask completes")
```

6. **branch**：条件分岐付き非同期タスク
   - 条件に基づいて異なる非同期タスクを実行する
```verse
branch:
    condition1 then Task1()
    condition2 then Task2()
    default then DefaultTask()
```

#### Subscribeからawait+非同期式への移行
- Subscribeを使用したイベント駆動型コードは状態管理が複雑になりがち
- 代わりに`Await`と非同期式を使用することで、より直感的なフロー制御が可能
```verse
# Subscribeを使用した場合
ButtonA.InteractedWithEvent.Subscribe(OnButtonPressed)
# 別の関数で処理
OnButtonPressed(Agent:agent):void=
    Animation.Play()
    # アニメーション完了の検出が難しい

# Awaitを使用した場合
block:
    ButtonA.InteractedWithEvent.Await()
    Animation.Play()
    Animation.CompletedEvent.Await() # 完了を直接待機
    Print("Animation completed")
```

#### 複合的な非同期処理の例
```verse
AwaitGameSequence()<suspends>:void=
    loop:
        # ゲーム開始を待つ
        StartButton.InteractedWithEvent.Await()
        Print("Game started")
        
        # プレイヤーに2つの選択肢を提示し、どちらかが選ばれるまで待つ
        race:
            block:
                PathAButton.InteractedWithEvent.Await()
                HandlePathA()
            block:
                PathBButton.InteractedWithEvent.Await()
                HandlePathB()
        
        # 両方のタスクが完了するまで待つ
        sync:
            block:
                Task1()
            block:
                Task2()
        
        # ゲーム終了
        Print("Game completed")
        
        # リセットボタンが押されるまで待つ
        ResetButton.InteractedWithEvent.Await()
        ResetGame()
```

#### 非同期処理のベストプラクティス
- 可能な限りSubscribeよりAwait+非同期式を使用する
- 複雑な状態管理が必要な場合は非同期式で処理フローを表現する
- 長時間実行される処理は`spawn`で非同期に実行し、UIをブロックしない
- 重要な処理順序は`block`で明示的に表現する
- 複数の非同期処理の完了を待つ場合は`sync`を使用する
- 複数の非同期処理のいずれかの完了を待つ場合は`race`を使用する

- **配列操作の注意点**：
  - 配列の要素を変更する場合も同様に失敗コンテキスト内で行う
  - ❌ `array += newElement` という操作はVerseでは使用できない
  - ❌ `.Append(element)`メソッドは存在しない（他の言語との混同に注意）
  - ❌ `.RemoveElement[element]`メソッドも存在しない（他の言語との混同に注意）
  - ✅ 正しい使い方（配列を結合する場合）：
    ```verse
    # 2つの配列を結合
    var Combined : []int = array1 + array2
    
    # 新しい要素の追加（新しい配列を作成）
    var NewArray : []int = OldArray + array{NewElement}
    ```
  - ✅ 配列から要素を削除する場合（フィルタリングで新しい配列を作成）：
    ```verse
    # 特定の要素を除外した新しい配列を作成
    var FilteredArray : []T = array{}
    for (Element : OriginalArray):
        if (Element <> ElementToRemove):
            set FilteredArray = FilteredArray + array{Element}
    ```
