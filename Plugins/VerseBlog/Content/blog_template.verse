using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# ブログテンプレート用のログチャンネル
blog_template_log := class(log_channel){}

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

# コース全体の設定クラス
CourseBaseSetting := class<concrete>():
    @editable
    var AreaSetting : []CourseAreaSetting = array{}
    @editable
    var TargetSetting : CourseTargetSetting = CourseTargetSetting{}
    @editable
    var GameStartTeleporter : teleporter_device = teleporter_device{}
    @editable
    var GameEndTeleporter : teleporter_device = teleporter_device{}

# コース内の各エリア設定クラス
CourseAreaSetting := class<concrete>():
    @editable
    var AreaStartTeleporter : teleporter_device = teleporter_device{}
    @editable
    var TargetPositions : []vector3 = array{}
    @editable
    var ResetExplosiveDevices : []explosive_device = array{}

# コース共通のターゲット設定クラス
CourseTargetSetting := class<concrete>():
    # 1. セントリータイプのターゲット
    @editable
    var TargetSentry : []sentry_device = array{}
    # 2. 移動NPCタイプ(攻撃なし)のターゲット
    @editable
    var TargetMoveNPC : []npc_spawner_device = array{}
    # 3. ガードタイプ(攻撃あり)のターゲット
    @editable
    var TargetGuardNPC : []npc_spawner_device = array{}

blog_template := class(creative_device):
    @editable
    CourseList : []CourseBaseSetting = array{}

    # # ターゲットハンドラー
    # var TargetHandler : TargetControlHandler = TargetControlHandler{}

    Logger:log = log{Channel := blog_template_log}

    OnBegin<override>()<suspends>:void=
        Logger.Print("--------------------------------")
        Logger.Print("------- New Game Start!! -------")
        Logger.Print("--------------------------------")


        # 各コースの初期化
        for (Index := 0..CourseList.Length - 1):
            if:
                CourseId := Index
                CourseSetting := CourseList[Index]
            then:
                # コース制御ハンドラーの作成
                CourseControl := CourseControlHandler{
                    CourseId := Index,
                    CourseSetting := CourseSetting
                }
                # コース開始イベントの登録
                CourseControl.CourseSetting.GameStartTeleporter.EnterEvent.Subscribe(CourseControl.HandleCourseStart)
 

        # for (Index := 0..Course1.AreaSetting.Length - 1):
        #     if (Area := Course1.AreaSetting[Index]):
        #         Area.AreaStartTeleporter.TeleportedEvent.Subscribe(OnCourse1Start)



################################################################
# クラス定義
################################################################

# コースの制御ハンドラー
CourseControlHandler := class:
    var Logger : log = log{Channel := blog_template_log}
    var CourseSetting : CourseBaseSetting = CourseBaseSetting{}

    var CourseId : int = 0
    var CurrentAreaIndex : int = 0
    var Player : ?agent = false

    # コース開始時の処理
    HandleCourseStart(Agent : agent) : void =
        Logger.Print("コース{CourseId + 1}: 開始")

        # 入場したAgentをPlayerに設定
        set Player = option{Agent}
    
    # 各エリア完了時の処理
    HandleAreaComplete(Agent : agent) : void =
        set CurrentAreaIndex += 1
        if (Area := CourseSetting.AreaSetting[CurrentAreaIndex]):
            Area.AreaStartTeleporter.Teleport(Agent)
        else:
            # 全エリア完了
            CourseSetting.GameEndTeleporter.Teleport(Agent)
            set Player = false
    
    # コース完了時の処理
    HandleCourseComplete(Agent : agent) : void =
        CourseSetting.GameEndTeleporter.Teleport(Agent)
        set Player = false

# ターゲット管理ハンドラー
TargetControlHandler := class:
    # 設定データ
    @editable
    var TargetSetting : CourseTargetSetting = CourseTargetSetting{}
    
    # 状態管理（コースごと）
    var CourseTargetStates : [int][]TargetState = map{}
    # 状態管理（エリアごと）
    var AreaTargetStates : [int][]TargetState = map{}
    # NPC管理
    var ActiveNPCs : [int][]agent = map{}     # コースIDごとのNPCリスト

    # NPCのスポーン処理を共通化
    SpawnNPC(Target : npc_spawner_device, Position : vector3, CourseId : int) : void =
        if (Target.TeleportTo[Position, Target.GetTransform().Rotation]):
            Target.Spawn()
            var NewState : TargetState = TargetState{}
            set NewState.Position = Position
            set NewState.IsActive = true
            if (set CourseTargetStates[CourseId] = array{NewState}){}
    
    # セントリーのスポーン処理
    SpawnSentry(Sentry : sentry_device, Position : vector3, CourseId : int) : void =
        if (Sentry.TeleportTo[Position, Sentry.GetTransform().Rotation]):
            Sentry.Enable()
            var NewState : TargetState = TargetState{}
            set NewState.Position = Position
            set NewState.IsActive = true
            if (set CourseTargetStates[CourseId] = array{NewState}){}
            
    # ターゲットの基本処理
    HandleSpawn(TargetKind : TargetType, Position : vector3, CourseId : int) : void =
        case (TargetKind):
            TargetType.Sentry => {
                if (Target := TargetSetting.TargetSentry[0]):
                    SpawnSentry(Target, Position, CourseId)
            }
            TargetType.MoveNPC => {
                if (Target := TargetSetting.TargetMoveNPC[0]):
                    SpawnNPC(Target, Position, CourseId)
            }
            TargetType.GuardNPC => {
                if (Target := TargetSetting.TargetGuardNPC[0]):
                    SpawnNPC(Target, Position, CourseId)
            }

    
    HandleElimination(TargetKind : TargetType, CourseId : int, AreaId : int, EliminatedAgent : agent) : void =
        # コースの状態更新
        if (CourseStates := CourseTargetStates[CourseId]):
            if (State := CourseStates[0]):
                set State.EliminationCount += 1
        
        # エリアの状態更新
        if (AreaStates := AreaTargetStates[AreaId]):
            if (State := AreaStates[0]):
                set State.EliminationCount += 1

        # NPCをリストから削除
        RemoveNPC(CourseId, EliminatedAgent)

    # NPC管理メソッド
    AddNPC(CourseId : int, NPC : agent) : void =
        var NewNPCs : []agent = array{NPC}
        if (ExistingNPCs := ActiveNPCs[CourseId]):
            var UpdatedNPCs : []agent = ExistingNPCs + array{NPC}
            var NewMap : [int][]agent = ActiveNPCs
            if (NewMap[CourseId] = UpdatedNPCs):
                set ActiveNPCs = NewMap
        else:
            var NewMap : [int][]agent = ActiveNPCs
            if (NewMap[CourseId] = NewNPCs):
                set ActiveNPCs = NewMap
            
    RemoveNPC(CourseId : int, NPC : agent) : void =
        if (ExistingNPCs := ActiveNPCs[CourseId]):
            # 配列から要素を削除するには、フィルタリングで新しい配列を作成
            var FilteredNPCs : []agent = array{}
            for (ExistingNPC : ExistingNPCs):
                if (ExistingNPC <> NPC):
                    set FilteredNPCs = FilteredNPCs + array{ExistingNPC}
            
            var NewMap : [int][]agent = ActiveNPCs
            if (NewMap[CourseId] = FilteredNPCs):
                set ActiveNPCs = NewMap

    GetNPCs(CourseId : int) : []agent =
        if (NPCs := ActiveNPCs[CourseId]):
            return NPCs
        return array{}
        

# ターゲットタイプ1: セントリーの制御ハンドラー
SentryControlHandler := class:
    @editable
    var Sentry : sentry_device = sentry_device{}

# ターゲットタイプ2: 動くNPCの制御ハンドラー
MoveNPCControlHandler := class:
    @editable
    var MoveNPC : npc_spawner_device = npc_spawner_device{}

# ターゲットタイプ3: ガードNPCの制御ハンドラー
GuardNPCControlHandler := class:
    @editable
    var GuardNPC : npc_spawner_device = npc_spawner_device{}



