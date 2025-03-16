# TimeAttackCourse建築管理システムの設計

## 背景と目的
TimeAttackCourseにおいて、エリアごとの建築の設置・リセットを効率的に管理する必要があります。
CourseSetupのBuildSpawnEventHandlerV2を参考に、cinematic_sequence_deviceを用いた建築管理システムを実装し、
エリアごとの建築の設置とリセットを適切なタイミングで行うことを目的とします。

## 基本事項
- チェックリストの使い方：タスクが完了したら `-[x]` のように `x` を追加してマークします
    -[x] 完了時
    -[ ] 未完了時
- コード実装時は、各関数に適切なコメントを追加してください

## 対象ファイル
- `Plugins/VerseBlog/Content/TimeAttackCourse.verse`

## 参考ファイル
- `Plugins/VerseBlog/Content/CourseSetup.verse`

## 要件定義

### 1. 建築管理の基本機能
- TimeAttackAreaBuildSettingを利用した建築の設置とリセット
- エリアごとの建築管理（設置エリアと非設置エリアの区別）
- BuildOnSequences/BuildOffSequencesの制御
- ResetExplosiveDevicesを用いたユーザー設置建築の破壊

### 2. 建築の設置タイミング
- エリア開始時に建築を設置
- 周回ごとに建築をリセット
- エリア終了時に建築をリセット

### 3. シーケンス制御の仕様
- 建築リセット/設置の順序：
  1. ResetExplosiveDevicesによるユーザー設置建築の破壊
  2. BuildOffSequencesによる既存建築の消去
  3. BuildOnSequencesによる新規建築の設置（ランダム選択）
- BuildOffSequences：すべて実行
- BuildOnSequences：ランダムに1つ選択して実行

### 4. 命名規則とログ出力
- 関数パラメータ名はクラスメンバー変数と区別するために異なる名前を使用
  - 例：`CurrentAreaIndex`（メンバー変数）と`AreaIndex`（パラメータ）
- ログ出力は「エリア{インデックス+1}」の形式に統一
  - 内部的には0から始まるインデックスを使用するが、表示上は1から始まる番号を使用

## 詳細設計

### 概略
TimeAttackAreaBuildSettingを活用し、エリアごとの建築管理を行います。
建築の設置とリセットのタイミングを適切に制御し、シーケンスデバイスを効率的に使用します。
また、ResetExplosiveDevicesを用いてユーザーが設置した建築も適切に破壊します。

### 機能
1. 建築管理関数群
   - SetupAreaBuilding：エリアの建築設置
   - ResetAreaBuilding：エリアの建築リセット
   - ResetExplosiveDevicesInArea：エリア内の爆発デバイスを起動

2. 既存機能の拡張
   - TeleportToAreaStart：エリア開始時の建築設置
   - CompleteAreaLap：周回完了時の建築リセット

### クラス構成

```verse
TimeAttackAreaBuildSetting := class<concrete>():
    @editable
    var BuildOnSequences : []cinematic_sequence_device = array{}
    @editable
    var BuildOffSequences : []cinematic_sequence_device = array{}

# 新規追加関数
SetupAreaBuilding(AreaIndex:int)<suspends>:void
ResetAreaBuilding(AreaIndex:int)<suspends>:void
ResetExplosiveDevicesInArea(AreaIndex:int)<suspends>:void

# 修正関数
TeleportToAreaStart():void
CompleteAreaLap():void
```

## ToDoリスト

### 実装
1. 建築管理関数の実装
   - [x] SetupAreaBuilding関数の実装
   - [x] ResetAreaBuilding関数の実装
   - [x] ResetExplosiveDevicesInArea関数の実装

2. 既存関数の修正
   - [x] TeleportToAreaStart関数の修正
   - [x] CompleteAreaLap関数の修正
   - [x] CourseEnd関数の修正
   - [x] CourseAbort関数の修正

3. 命名規則とログ出力の統一
   - [x] 関数パラメータ名をクラスメンバー変数と区別
   - [x] ログ出力を「エリア{インデックス+1}」の形式に統一

