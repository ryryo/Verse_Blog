# Verseにおけるハンドラーパターンの実装ガイド

## なぜハンドラーパターンを使うのか？

### 🎮 ゲーム開発者向けの簡単な説明

ゲーム開発では、「同じような処理を何度も書く」「複数の情報を一緒に扱いたい」「似たような機能をまとめたい」といった場面によく遭遇します。
例えば：

1. **複数のボタンで同じような処理をしたい場合**
   - 10個のボタンがあり、それぞれ押されたときに異なる数字を表示したい
   - 従来の方法: 10個のボタンそれぞれに個別の処理を書く（コードが10倍に！）
   - ハンドラーパターン: 1つの処理にまとめて、ボタンごとの数字だけを変える

2. **NPCの種類ごとに似た動きを設定したい場合**
   - 歩くNPC、走るNPC、ジャンプするNPCがいる
   - 従来の方法: それぞれのNPCタイプごとに移動の処理を書く
   - ハンドラーパターン: 基本の動きをまとめて、NPCごとの特殊な動きだけを追加

3. **プレイヤーの進行状況を管理したい場合**
   - 3つのコースがあり、各コースに3つのエリアがある
   - 従来の方法: コースとエリアごとに個別の進行管理を書く
   - ハンドラーパターン: 進行管理の基本ロジックをまとめて、コース固有の要素だけを変える

### 💡 ハンドラーパターンのメリット

1. **コードの重複を減らせる**
   - 同じような処理を何度も書く必要がない
   - 変更が必要な場合も1箇所を修正するだけでOK

2. **管理が楽になる**
   - 関連する処理をひとまとめにできる
   - バグが発生した時も原因を特定しやすい

3. **機能の追加が簡単**
   - 新しい種類のボタンやNPCを追加する時も、基本の処理は再利用できる
   - テストも効率的に行える

## はじめに
Verseでゲームを開発する際、イベント処理やデータの管理を効率的に行うために「ハンドラーパターン」が重要な役割を果たします。
このガイドでは、ハンドラーパターンの基本的な概念と実装方法について説明します。

## ハンドラーパターンとは
ハンドラーパターンは、特定のイベントや処理を「扱う（handle）」ための設計パターンです。
Verseでは、クラスとして実装され、以下の特徴を持ちます：

1. データのカプセル化
2. イベント処理の集中管理
3. 再利用可能なコードの作成

## 基本的な実装パターン

### 1. シンプルなイベントハンドラー
```verse
MyHandler := class():
    # デバイスへの参照
    Device : my_device
    
    # イベント処理メソッド
    HandleEvent(Agent : agent) : void =
        # イベント発生時の処理
```

### 2. パラメータを持つハンドラー
```verse
CustomHandler := class():
    Device : game_device   
    Parameter : int  

    HandleEvent(Agent : agent) : void =
        Device.ProcessEvent(Parameter)
```

## 実践的な使用例

### 1. ボタンイベントの処理
```verse
ButtonHandler := class():
    Device : game_device
    ButtonId : int

    OnButtonPressed(Agent : agent) : void =
        # ボタンIDに基づいた処理
        Device.HandleButtonPress(ButtonId)

# メインデバイスでの使用
game_device := class(creative_device):
    @editable
    var Button : button_device = button_device{}

    OnBegin<override>()<suspends>:void=
        Button.InteractedWithEvent.Subscribe(
            ButtonHandler{
                Device := Self,
                ButtonId := 1
            }.OnButtonPressed
        )
```

### 2. 非同期処理を含むハンドラー
```verse
AsyncHandler := class():
    Device : game_device
    
    HandleEvent(Agent : agent)<suspends> : void =
        # 非同期処理を実行
        spawn{ Device.LongRunningTask() }
```

## ハンドラーパターンのベストプラクティス

1. **単一責任の原則**
   - 各ハンドラーは特定の種類のイベントや処理のみを担当する
   - 複雑な処理は小さな機能に分割する

2. **状態管理**
   - ハンドラー内で状態を管理する場合は、適切なスコープを設定
   - 共有状態の場合は同期処理に注意

3. **エラーハンドリング**
   - イベント処理中の例外を適切に処理
   - デバッグ情報の出力を活用

4. **再利用性**
   - 汎用的なハンドラーは再利用可能な形で設計
   - パラメータを柔軟に設定できるように構成

## 実際のユースケース

### ターゲットの制御と管理
```verse
# ターゲットの種類を定義
TargetType := enum:
    Sentry    # セントリータイプ
    MoveNPC   # 移動NPCタイプ
    GuardNPC  # ガードタイプ

# ターゲットの状態管理
TargetState := class:
    var IsActive : logic = false
    var Position : vector3 = vector3{}
    var EliminationCount : int = 0

# ターゲット管理ハンドラー
TargetControlHandler := class:
    # 設定データ
    @editable
    var TargetSetting : CourseTargetSetting = CourseTargetSetting{}
    
    # 状態管理（コースごと）
    var CourseTargetStates : [int][]TargetState = map{}
    # 状態管理（エリアごと）
    var AreaTargetStates : [int][]TargetState = map{}
    
    # ターゲットの基本処理
    HandleSpawn(TargetType : TargetType, Position : vector3) : void
    HandleElimination(TargetType : TargetType, Agent : agent) : void
    
    # 統計情報の取得
    GetCourseEliminationCount(CourseId : int) : int
    GetAreaEliminationCount(AreaId : int) : int
    
    # ターゲットタイプごとの特殊な動き
    HandleSentryBehavior(Target : sentry_device) : void
    HandleMoveNPCBehavior(Target : npc_spawner_device) : void
    HandleGuardNPCBehavior(Target : npc_spawner_device) : void
```

このハンドラーの利点：
1. **統一された管理**
   - 異なるタイプのターゲット（セントリー、移動NPC、ガードNPC）を一元管理
   - 撃破数などの統計情報を簡単に取得可能

2. **柔軟な状態管理**
   - コースごと、エリアごとの状態を個別に管理
   - 新しい統計情報の追加が容易

3. **タイプごとの特殊処理**
   - 基本的な処理（スポーン、撃破）は共通化
   - タイプごとの特殊な動きは個別に実装可能

使用例：
```verse
# メインデバイスでの使用
TimeAttackCourse := class(creative_device):
    var TargetHandler : TargetControlHandler = TargetControlHandler{}
    
    # ターゲットの初期化
    InitializeTargets(CourseId : int) : void =
        # セントリーの設定
        TargetHandler.HandleSpawn(TargetType.Sentry, vector3{X := 0.0, Y := 0.0, Z := 0.0})
        # 移動NPCの設定
        TargetHandler.HandleSpawn(TargetType.MoveNPC, vector3{X := 100.0, Y := 0.0, Z := 0.0})
        
    # 撃破時の処理
    OnTargetEliminated(TargetType : TargetType, Agent : agent) : void =
        TargetHandler.HandleElimination(TargetType, Agent)
        # 統計情報の確認
        EliminationCount := TargetHandler.GetCourseEliminationCount(1)
        Print("Course 1 Elimination Count: {EliminationCount}")
```

## まとめ
ハンドラーパターンは、Verseでの開発において以下の利点をもたらします：

1. コードの整理と管理が容易になる
2. イベント処理の一貫性が保たれる
3. 機能の追加や変更が簡単になる
4. テストと保守が容易になる

適切なハンドラーパターンの使用により、より保守性の高い、スケーラブルなコードベースを構築することができます。 