-- ========================================== 
-- BYPASS SYSTEMS (ULTRA AGGRESSIVE - ZERO DETECTION)
-- ========================================== 
local function nop() return true end
local function retFalse() return false end
local function retTrue() return true end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end

local function InitializeBypass()
    pcall(function()
        -- Disable signature checks
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "r.EnableDataDrivenShaders 0")
            console.ExecuteConsoleCommand(nil, "r.ShaderPipelines 0")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.VerifyFileIntegrity = retTrue
        end
        
        -- Higgs Boson full kill
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive", "ReportItemID", "ShowSecurityAlert", "ServerReportAvatar", "CheckMHActive", "ReportViolation"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.bMHActive = false
        end
        
        -- Subsystem massacre
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ShootVerifySubSystemClient", "FileCheckSubsystem", "MemoryCheckSubsystem", "AvatarExceptionSubsystem", "AFKReportorSubsystem"}
            for _, name in ipairs(toKill) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Verify") or k:find("Check") or k:find("Scan") or k:find("Validate")) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                end
            end
        end
        
        -- Network packet block (extended)
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                "ReportAttackFlow", "ReportHitFlow", "ReportSecAttackFlow", "ReportMrpcsFlow",
                "PlayerSecurityInfo", "SwiftHawk", "CoronaLabReport", "ReportAimFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportPlayerBehavior", "ReportTeammatHurt",
                "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute",
                "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow",
                "ReportParachuteData", "ReportEquipmentFlow", "ReportHeavyWeaponBoxSpawnFlow",
                "ReportHeavyWeaponBoxActivationFlow", "ReportHeavyWeaponBoxOpenPlayerFlow",
                "ReportHeavyWeaponBoxItemFlow", "ReportPlayersPing", "ReportPlayerIP",
                "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
                "ReportDSNetRate", "ReportCircleFlow", "ReportDSCircleFlow", "ReportJumpFlow",
                "ReportAIStrategyInfo", "ReportDailyTaskInfo", "ReportMatchRoomData",
                "ReportIDCardProduceFlow", "ReportIDCardPickUpFlow", "ReportIDCardDestroyFlow",
                "ReportRevivalFlow", "ReportGameSetting", "ReportGameSettingNew",
                "ReportAntsVoiceTeamCreate", "ReportAntsVoiceTeamQuit", "ReportCommonInfo",
                "ReportLightweightStat", "SendSecTLog", "SendDataMiningTLog", "SendActivityTLog",
                "tss_sdk_report", "report_memory_exception", "report_avatar_exception",
                "report_ui_state", "report_hit_reg_fail", "report_character_state",
                "report_vehicle_exception", "report_camera_exception", "ReportPlayerControllerStateChanged",
                "ReportAvatarFlow", "OnDSPlayerStateChanged", "OnPlayerNetConnectionClosed",
                "OnPlayerActorChannelError", "OnPlayerRPCValidateFailed", "OnPlayerSpectateException",
                "OnShutdownAfterError"
            }
            NetUtil.SendPacket = function(packetName, ...)
                for _, b in ipairs(blocked) do if packetName == b then return nil end end
                return orig(packetName, ...)
            end
        end
        
        -- Anti-debug and integrity
        local Kismet = import("KismetSystemLibrary")
        if Kismet then
            Kismet.IsDebuggerPresent = retFalse
            Kismet.IsRunningUnderDebugger = retFalse
            Kismet.DisablePakSignatureCheck = nop
        end
        
        local FileHelper = import("FileHelper")
        if FileHelper then
            FileHelper.FileExists = retTrue
            FileHelper.FileSize = retZero
            FileHelper.GetFileMD5Hash = function() return "00000000000000000000000000000000" end
        end
        
        local AntiCheat = import("AntiCheat")
        if AntiCheat then
            AntiCheat.CheckMemoryIntegrity = retTrue
            AntiCheat.CheckCodeIntegrity = retTrue
            AntiCheat.ReportCheat = nop
            AntiCheat.GetCheatDetectCount = retZero
        end
        
        -- TSS SDK block
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            for _, f in ipairs({"ReportData", "ReportString", "ReportInt", "ReportFloat", "OnRecvData", "ScanMemory"}) do
                if TssSdk[f] then TssSdk[f] = nop end
            end
            TssSdk.ScanMemory = retTrue
        end
        
        -- Memory utils block
        local MemoryUtils = import("MemoryUtils")
        if MemoryUtils then
            MemoryUtils.ReadProcessMemory = retNil
            MemoryUtils.WriteProcessMemory = retFalse
            MemoryUtils.ScanMemoryRegion = retEmpty
        end
        
        -- Crash report block
        local CrashReport = import("CrashReport")
        if CrashReport then
            CrashReport.ReportException = nop
            CrashReport.ReportAssert = nop
        end
        
        -- Environment spoof
        if os and os.getuid then os.getuid = function() return 999999 end end
        if os and os.getpid then os.getpid = function() return 999999 end end
        if os and os.getenv then
            local orig_getenv = os.getenv
            os.getenv = function(name)
                if name == "LD_PRELOAD" or name == "ANDROID_ROOT" or name == "PATH" then
                    return orig_getenv(name)
                end
                return nil
            end
        end
        
        print("[BYPASS] Complete - Ultra Aggressive")
    end)
end
-- ========================================== 
-- INIT BYPASS
-- ========================================== 

-- ========================================== 
-- =========== COMPLETE BYPASS SYSTEM ========== 
-- ========================================== 

-- ========================================== 
-- BYPASS 1: CLIENT REPORT SUBSYSTEM
-- ========================================== 
function _G.JINSHI_BYPASS_INSTALL()
pcall(function()
local paths = { "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
local ClientReport = nil
for _, path in ipairs(paths) do
if package.loaded[path] then ClientReport = package.loaded[path] break end
local status, lib = pcall(require, path)
if status and lib then ClientReport = lib break end
end
if ClientReport then
ClientReport.OnInit = function(self) return end
ClientReport._OnPlayerKilledOtherPlayer = function() return end
ClientReport._RecordFatalDamager = function() return end
ClientReport._OnDeathReplayDataWhenFatalDamaged = function() return end
ClientReport._RecordMurdererFromDeathReplayData = function() return end
ClientReport._RecordTeammatePlayerInfo = function() return end
ClientReport._OnBattleResult = function() return end
ClientReport._OnShowQuickReportMutualExclusiveUI = function() return end
ClientReport.GetFatalDamagerMap = function() return {} end
ClientReport.GetCachedTeammateName2InfoMap = function() return {} end
ClientReport.GetTeammateName2InfoMapDuringBattle = function() return {} end
ClientReport.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
ClientReport.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
end
end)

pcall(function()
local paths = { "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
local DSReport = nil
for _, path in ipairs(paths) do
if package.loaded[path] then DSReport = package.loaded[path] break end
local status, lib = pcall(require, path)
if status and lib then DSReport = lib break end
end
if DSReport then
DSReport.OnInit = function(self) return end
DSReport._OnNearDeathOrRescued = function() return end
DSReport._OnCharacterDied = function() return end
DSReport._OnTeammateDamage = function() return end
DSReport._OnPlayerSettlementStart = function() return end
DSReport._AddKnockDownerToBattleResult = function() return end
DSReport._AddKillerToBattleResult = function() return end
DSReport._AddTeammateMurderToBattleResult = function() return end
DSReport._AddFatalDamagerMapToBattleResult = function() return end
DSReport._AddMLKillerUIDToBattleResult = function() return end
DSReport._SaveHistoricalTeammateInfo = function() return end
DSReport._RecordFatalDamager = function() return end
DSReport._RecordTeammateMurderer = function() return end
end
end)

pcall(function()
local ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
if ReportPlayerUtils then
ReportPlayerUtils.RecordFatalDamager = function() return end
ReportPlayerUtils.IsUsingHistoricalTeammateInfo = function() return false end
ReportPlayerUtils.IsCharacterDeliverAI = function() return false end
end
end)

pcall(function()
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
if SecurityCommonUtils then
SecurityCommonUtils.ExtractPlayerBasicInfo = function() return {} end
SecurityCommonUtils.LogIf = function() return false end
end
end)

pcall(function()
local QuickReport = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
if QuickReport then
QuickReport.OnShowMutualExclusiveUI = function() return end
QuickReport.OnHideMutualExclusiveUI = function() return end
end
end)
end

-- ========================================== 
-- BYPASS 2: HIGGS BOSON DISABLE
-- ========================================== 
function _G.DisableHiggsBoson()
local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if not PlayerController or not slua.isValid(PlayerController) then return end
if PlayerController.HiggsBoson then
PlayerController.HiggsBoson.bMHActive = false
PlayerController.HiggsBoson.bCallPreReplication = false
end
if PlayerController.HiggsBosonComponent then
PlayerController.HiggsBosonComponent.bMHActive = false
PlayerController.HiggsBosonComponent:ControlMHActive(0)
end
end

-- ========================================== 
-- BYPASS 3: HIGGS BOSON HOOKS
-- ========================================== 
function _G.JINSHI_BYPASS_HOOK()
pcall(function()
local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
end
end)

if _G.AvatarCheckCallback then
_G.AvatarCheckCallback.StartAvatarCheck = function(HiggsBosonComponent) end
_G.AvatarCheckCallback.OnReportItemID = function(HiggsBosonComponent) end
_G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
PlayerController.HiggsBosonComponent:ControlMHActive(0)
PlayerController.HiggsBosonComponent.bMHActive = false
end
end
end

pcall(function()
local SecurityModule = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if SecurityModule and SecurityModule.BlackList then
for k in pairs(SecurityModule.BlackList) do SecurityModule.BlackList[k] = nil end
end
end)

_G.BlackList = {}

pcall(function()
_G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
_G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
mt.__newindex = function(t, k, v) end
setmetatable(_G.GlobalPlayerCoronaData, mt)
end)

pcall(function()
if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
_G.GameSafeCallbacks.RecordStrategyTimestampInReplay = function(...) end
_G.GameSafeCallbacks.DoAttackFlowStrategy = function() end
_G.GameSafeCallbacks.GetScriptReportContent = function() return "" end
end
end)

pcall(function()
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
if USTExtraBlueprintFunctionLibrary then
USTExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end
end
end)
end

-- ========================================== 
-- BYPASS 4: GAMEPLAY CALLBACKS ISLAND
-- ========================================== 
function _G.JINSHI_BYPASS_ISLAND()
pcall(function()
if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end

local GC = _G.GameplayCallbacks

local original_OnDSPlayerStateChanged = GC.OnDSPlayerStateChanged
GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
if original_OnDSPlayerStateChanged then return original_OnDSPlayerStateChanged(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
end

local function BlockFunc() return end
local function BlockRetEmpty() return {} end
local function BlockRetNil() return nil end

GC.ReportAttackFlow = BlockFunc
GC.ReportSecAttackFlow = BlockFunc
GC.ReportHurtFlow = BlockFunc
GC.ReportFireArms = BlockFunc
GC.ReportVerifyInfoFlow = BlockFunc
GC.ReportMrpcsFlow = BlockFunc
GC.ReportPlayerBehavior = BlockFunc
GC.ReportTeammatHurt = BlockFunc
GC.ReportMisKillByTeammate = BlockFunc
GC.ReportForbitPick = BlockFunc
GC.ReportPlayerMoveRoute = BlockFunc
GC.ReportPlayerPosition = BlockFunc
GC.ReportVehicleMoveFlow = BlockFunc
GC.ReportSecTgameMovingFlow = BlockFunc
GC.ReportParachuteData = BlockFunc
GC.SendTssSdkAntiDataToLobby = BlockFunc
GC.SendDSErrorLogToLobby = BlockFunc
GC.SendDSErrorLogToLobbyOnece = BlockFunc
GC.SendDSHawkEyePatrolLogToLobby = BlockFunc
GC.ReportEquipmentFlow = BlockFunc
GC.ReportAimFlow = BlockFunc
GC.GetWeaponReport = BlockRetEmpty
GC.GetOneWeaponReport = BlockRetEmpty
GC.ReportHeavyWeaponBoxSpawnFlow = BlockFunc
GC.ReportHeavyWeaponBoxActivationFlow = BlockFunc
GC.ReportHeavyWeaponBoxOpenPlayerFlow = BlockFunc
GC.ReportHeavyWeaponBoxItemFlow = BlockFunc
GC.ReportPlayersPing = BlockFunc
GC.ReportPlayerIP = BlockFunc
GC.ReportPlayerFramePingRecord = BlockFunc
GC.OnDSConnectionSaturated = BlockFunc
GC.ReportDSNetSaturation = BlockFunc
GC.ReportNetContinuousSaturate = BlockFunc
GC.ReportDSNetRate = BlockFunc
GC.SendClientStats = BlockFunc
GC.SendServerAvgTickDelta = BlockFunc
GC.ReportCircleFlow = BlockFunc
GC.ReportDSCircleFlow = BlockFunc
GC.ReportJumpFlow = BlockFunc
GC.ReportAIStrategyInfo = BlockFunc
GC.SendAIDeliveryInfo = BlockFunc
GC.ReportDailyTaskInfo = BlockFunc
GC.ReportMatchRoomData = BlockFunc
GC.SendPlayerSpectatingLog = BlockFunc
GC.ReportIDCardProduceFlow = BlockFunc
GC.ReportIDCardPickUpFlow = BlockFunc
GC.ReportIDCardDestroyFlow = BlockFunc
GC.ReportRevivalFlow = BlockFunc
GC.ReportGameSetting = BlockFunc
GC.ReportGameSettingNew = BlockFunc
GC.ReportAntsVoiceTeamCreate = BlockFunc
GC.ReportAntsVoiceTeamQuit = BlockFunc
GC.ReportCommonInfo = BlockFunc
GC.ReportLightweightStat = BlockFunc
GC.SendSecTLog = BlockFunc
GC.SendDataMiningTLog = BlockFunc
GC.SendActivityTLog = BlockFunc
GC.GetGeneralTLogData = BlockRetNil

GC.IsBypassed = true
end)

pcall(function()
if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
local original_SendPacket = NetUtil.SendPacket
local BlockedPackets = {
["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
["report_character_all_drag"]=1, ["report_parachute_all_drag"]=1, ["report_vehicle_move_drag"]=1,
["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1, ["report_heavy_weapon_box_activation_flow"]=1,
["report_heavy_weapon_box_item_flow"]=1, ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1,
["ReportJumpFlow"]=1, ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1, ["ReportGenerateMonsterFlow"]=1,
["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1, ["ReportRevivalFlow"]=1,
["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1, ["report_common_battle_info"]=1,
["report_client_scan_result"]=1, ["tss_sdk_report"]=1, ["report_memory_exception"]=1,
["report_avatar_exception"]=1, ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1,
["ReportPlayerControllerStateChanged"]=1, ["ReportAvatarFlow"]=1
}

NetUtil.SendPacket = function(packetName, ...)
if BlockedPackets[packetName] then return end
return original_SendPacket(packetName, ...)
end
NetUtil.IsBypassed = true
end
end)
end

-- ========================================== 
-- BYPASS 5: CONNECTION GUARD
-- ========================================== 
function _G.JINSHI_BYPASS_CONNECTED()
pcall(function()
if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end

local GC = _G.GameplayCallbacks
local original_OnDSPlayerStateChanged = GC.OnDSPlayerStateChanged

GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
local sState = InPlayerState and string.lower(tostring(InPlayerState)) or ""
local BadStates = {
["cheatdetected"] = true, ["connectionlost"] = true,
["connectiontimeout"] = true, ["connectionexception"] = true,
["netdrivererror"] = true
}
if BadStates[sState] then return end
if original_OnDSPlayerStateChanged then
pcall(original_OnDSPlayerStateChanged, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
end
end

GC.OnPlayerNetConnectionClosed = function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerActorChannelError = function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerRPCValidateFailed = function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerSpectateException = function(GameID, UID, Reason, ErrorMessage) end
GC.OnShutdownAfterError = function(GameID) end

_G.ConnectionGuardInitialized = true
end)
end

-- ========================================== 
-- BYPASS 6: BLOCK LOGS & REPORTS
-- ========================================== 
function _G.JINSHI_BYPASS_BLOCK()
pcall(function()
local TLog = package.loaded["TLog"] or _G.TLog
if TLog then
TLog.Info = function() end; TLog.Warning = function() end
TLog.Error = function() end; TLog.Debug = function() end; TLog.Report = function() end
end
local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
if CrashSight then
CrashSight.ReportException = function() end
CrashSight.SetCustomData = function() end; CrashSight.Log = function() end
end
local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
if ClientToolsReport then
ClientToolsReport.SendReport = function() end; ClientToolsReport.SendException = function() end
end
local ClientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
if ClientTLogUtil then
ClientTLogUtil.ReportGeneralCountByBRPhase = function() end
ClientTLogUtil.ReportCommonTLogDataByBRPhase = function() end
end
local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
if GameReportSubsystem then
GameReportSubsystem.CheckCanBugglyPostException = function() return false end
GameReportSubsystem.BugglyPostExceptionFull = function() return false end
end
end)
end

-- ========================================== 
-- BYPASS 7: SUB SYSTEM LOG BLOCK
-- ========================================== 
function _G.JINSHI_BYPASS_LOG()
pcall(function()
local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if not SubsystemMgr then return end
local AFKSub = SubsystemMgr:Get("AFKReportorSubsystem")
if AFKSub then 
AFKSub.PlayerHaveAction = function() end; AFKSub.ReportAFK = function() end
end
local AvatarExc = SubsystemMgr:Get("AvatarExceptionSubsystem")
if AvatarExc then
AvatarExc.ReportException = function() end
AvatarExc.BindPlayerCharacter = function() end
AvatarExc.CheckAvatarValid = function() return true end
end

local ShootVerifyClient = SubsystemMgr:Get("ShootVerifySubSystemClient")
if ShootVerifyClient then
ShootVerifyClient.ReportVerifyFail = function() end
ShootVerifyClient.OnVerifyFailed = function() end
end

local TSS = package.loaded["TssSdk"] or _G.TssSdk
if TSS then
TSS.OnRecvData = function() end; TSS.SendReportInfo = function() end
TSS.ScanMemory = function() return true end
end
end)
end

-- ========================================== 
-- BYPASS 8: REPLAY TELEMETRY BLOCK
-- ========================================== 
function _G.JINSHI_BYPASS_REPLAY()
pcall(function()
local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")

local RescueTrace = SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
if RescueTrace then
RescueTrace.ReportTrace = function() end; RescueTrace.StartTickMonitor = function() end
RescueTrace.TickMonitorCheck = function() end; RescueTrace.ReportTickMonitorHeartbeat = function() end
end

local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
if GameReportUtils then
GameReportUtils.ReplayReportData = function() end
GameReportUtils.ReportGameException = function() end
end

local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
if GameReportSubsystem then
GameReportSubsystem.ReplayReportData = function() return false end
if GameReportSubsystem.Reporter then
GameReportSubsystem.Reporter.ReportIntArrayData = function() end
GameReportSubsystem.Reporter.ReportUInt8ArrayData = function() end
GameReportSubsystem.Reporter.ReportFloatArrayData = function() end
end
end
end)
end

-- ========================================== 
-- EXTRA BYPASS: ADVANCED ANTI-DETECTION
-- ========================================== 
function _G.JINSHI_EXTRA_BYPASS()
    pcall(function()
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary then
            KismetSystemLibrary.IsDebuggerPresent = retFalse
            KismetSystemLibrary.IsRunningUnderDebugger = retFalse
            KismetSystemLibrary.DisablePakSignatureCheck = nop
        end

        local FileHelper = import("FileHelper")
        if FileHelper then
            FileHelper.FileExists = retTrue
            FileHelper.FileSize = retZero
            FileHelper.GetFileMD5Hash = function() return "00000000000000000000000000000000" end
        end

        local AntiCheat = import("AntiCheat")
        if AntiCheat then
            AntiCheat.CheckMemoryIntegrity = retTrue
            AntiCheat.CheckCodeIntegrity = retTrue
            AntiCheat.ReportCheat = nop
            AntiCheat.GetCheatDetectCount = retZero
        end

        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.ReportData = nop
            TssSdk.ReportString = nop
            TssSdk.ReportInt = nop
            TssSdk.ReportFloat = nop
            TssSdk.OnRecvData = nop
            TssSdk.ScanMemory = retTrue
        end

        local MemoryUtils = import("MemoryUtils")
        if MemoryUtils then
            MemoryUtils.ReadProcessMemory = retNil
            MemoryUtils.WriteProcessMemory = retFalse
            MemoryUtils.ScanMemoryRegion = retEmpty
        end

        local CrashReport = import("CrashReport")
        if CrashReport then
            CrashReport.ReportException = nop
            CrashReport.ReportAssert = nop
        end

        if os and os.getuid then os.getuid = function() return 999999 end end
        if os and os.getpid then os.getpid = function() return 999999 end end

        if os and os.getenv then
            local orig_getenv = os.getenv
            os.getenv = function(name)
                if name == "LD_PRELOAD" or name == "ANDROID_ROOT" or name == "PATH" then
                    return orig_getenv(name)
                end
                return nil
            end
        end

        print("[EXTRA BYPASS] Advanced anti-detection enabled")
    end)
end

-- ========================================== 
-- MASTER INIT FUNCTION
-- ========================================== 
function _G.InitializeAllBypasses()
    pcall(function()
        _G.JINSHI_BYPASS_INSTALL()
        _G.JINSHI_BYPASS_HOOK()
        _G.JINSHI_BYPASS_ISLAND()
        _G.JINSHI_BYPASS_CONNECTED()
        _G.JINSHI_BYPASS_BLOCK()
        _G.JINSHI_BYPASS_LOG()
        _G.JINSHI_BYPASS_REPLAY()
        _G.JINSHI_EXTRA_BYPASS()
        _G.DisableHiggsBoson()
        print("[✓ BYPASS] All Bypasses Initialized Successfully!")
    end)
end

pcall(InitializeBypass)
-- ========================================== 
-- =========== END BYPASS SYSTEM ============ 
-- ========================================== 
