-- ============================================================
-- ANTI-CHEAT BYPASS FUNCTIONS
-- ============================================================

function _G.KASHMIRY_BYPASS_INSTALL()
    pcall(function()
        local modulePaths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem",
        }
        local subsystem = nil
        for _, path in ipairs(modulePaths) do
            if package.loaded[path] then
                subsystem = package.loaded[path]
                break
            end
            local ok, mod = pcall(require, path)
            if ok and mod then
                subsystem = mod
                break
            end
        end

        if subsystem then
            subsystem.OnInit = function(self) return end
            subsystem._OnPlayerKilledOtherPlayer = function(self) return end
            subsystem._RecordFatalDamager = function(self) return end
            subsystem._OnDeathReplayDataWhenFatalDamaged = function(self) return end
            subsystem._RecordMurdererFromDeathReplayData = function(self) return end
            subsystem._RecordTeammatePlayerInfo = function(self) return end
            subsystem._OnBattleResult = function(self) return end
            subsystem._OnShowQuickReportMutualExclusiveUI = function(self) return end
            subsystem.GetFatalDamagerMap = function(self) return {} end
            subsystem.GetCachedTeammateName2InfoMap = function(self) return {} end
            subsystem.GetTeammateName2InfoMapDuringBattle = function(self) return {} end
            subsystem.GetCurrentNotInTeamHistoricalTeammateMap = function(self) return {} end
            subsystem.GetInTeamIndexFromHistoricalTeammateInfo = function(self) return -1 end
        end
    end)

    pcall(function()
        local modulePaths = {
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem",
        }
        local subsystem = nil
        for _, path in ipairs(modulePaths) do
            if package.loaded[path] then
                subsystem = package.loaded[path]
                break
            end
            local ok, mod = pcall(require, path)
            if ok and mod then
                subsystem = mod
                break
            end
        end

        if subsystem then
            subsystem.OnInit = function(self) return end
            subsystem._OnNearDeathOrRescued = function(self) return end
            subsystem._OnCharacterDied = function(self) return end
            subsystem._OnTeammateDamage = function(self) return end
            subsystem._OnPlayerSettlementStart = function(self) return end
            subsystem._AddKnockDownerToBattleResult = function(self) return end
            subsystem._AddKillerToBattleResult = function(self) return end
            subsystem._AddTeammateMurderToBattleResult = function(self) return end
            subsystem._AddFatalDamagerMapToBattleResult = function(self) return end
            subsystem._AddMLKillerUIDToBattleResult = function(self) return end
            subsystem._SaveHistoricalTeammateInfo = function(self) return end
            subsystem._RecordFatalDamager = function(self) return end
            subsystem._RecordTeammateMurderer = function(self) return end
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
        local ClientQuickReport = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if ClientQuickReport then
            ClientQuickReport.OnShowMutualExclusiveUI = function() return end
            ClientQuickReport.OnHideMutualExclusiveUI = function() return end
        end
    end)
end

function _G.DisableHiggsBoson()
    local pc = nil
    if slua_GameFrontendHUD then
        pc = slua_GameFrontendHUD:GetPlayerController()
    end
    if not pc or not slua.isValid(pc) then
        return
    end
    if pc.HiggsBoson then
        pc.HiggsBoson.bMHActive = false
        pc.HiggsBoson.bCallPreReplication = false
    end
    if pc.HiggsBosonComponent then
        pc.HiggsBosonComponent.bMHActive = false
        pc.HiggsBosonComponent:ControlMHActive(0)
    end
end

function _G.KASHMIRY_BYPASS_HOOK()
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
    end)

    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function(self) end
        _G.AvatarCheckCallback.OnReportItemID = function(self) end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(self, controller)
            if slua.isValid(controller) and controller.HiggsBosonComponent then
                controller.HiggsBosonComponent:ControlMHActive(0)
                controller.HiggsBosonComponent.bMHActive = false
            end
        end
    end

    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.BlackList then
            for key, _ in pairs(HiggsBosonComponent.BlackList) do
                HiggsBosonComponent.BlackList[key] = nil
            end
        end
    end)

    _G.BlackList = {}

    pcall(function()
        if not _G.GlobalPlayerCoronaData then
            _G.GlobalPlayerCoronaData = {}
        end
        if not _G.GlobalPlayerCheatTimes then
            _G.GlobalPlayerCheatTimes = {}
        end
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function(t, k, v) return end
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
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end
        end
    end)
end

function _G.KASHMIRY_BYPASS_ISLAND()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then
            return
        end

        local origOnDSPlayerStateChanged = _G.GameplayCallbacks.OnDSPlayerStateChanged
        _G.GameplayCallbacks.OnDSPlayerStateChanged = function(self, stateType, ...)
            if stateType and string.lower(tostring(stateType)) == "cheatdetected" then
                return
            end
            if origOnDSPlayerStateChanged then
                return origOnDSPlayerStateChanged(self, stateType, ...)
            end
        end

        local emptyFunc = function() return end
        local emptyTableFunc = function() return {} end

        _G.GameplayCallbacks.ReportAttackFlow = emptyFunc
        _G.GameplayCallbacks.ReportSecAttackFlow = emptyFunc
        _G.GameplayCallbacks.ReportHurtFlow = emptyFunc
        _G.GameplayCallbacks.ReportFireArms = emptyFunc
        _G.GameplayCallbacks.ReportVerifyInfoFlow = emptyFunc
        _G.GameplayCallbacks.ReportMrpcsFlow = emptyFunc
        _G.GameplayCallbacks.ReportPlayerBehavior = emptyFunc
        _G.GameplayCallbacks.ReportTeammatHurt = emptyFunc
        _G.GameplayCallbacks.ReportMisKillByTeammate = emptyFunc
        _G.GameplayCallbacks.ReportForbitPick = emptyFunc
        _G.GameplayCallbacks.ReportPlayerMoveRoute = emptyFunc
        _G.GameplayCallbacks.ReportPlayerPosition = emptyFunc
        _G.GameplayCallbacks.ReportVehicleMoveFlow = emptyFunc
        _G.GameplayCallbacks.ReportSecTgameMovingFlow = emptyFunc
        _G.GameplayCallbacks.ReportParachuteData = emptyFunc
        _G.GameplayCallbacks.SendTssSdkAntiDataToLobby = emptyFunc
        _G.GameplayCallbacks.SendDSErrorLogToLobby = emptyFunc
        _G.GameplayCallbacks.SendDSErrorLogToLobbyOnece = emptyFunc
        _G.GameplayCallbacks.SendDSHawkEyePatrolLogToLobby = emptyFunc
        _G.GameplayCallbacks.ReportEquipmentFlow = emptyFunc
        _G.GameplayCallbacks.ReportAimFlow = emptyFunc
        _G.GameplayCallbacks.GetWeaponReport = emptyTableFunc
        _G.GameplayCallbacks.GetOneWeaponReport = emptyTableFunc
        _G.GameplayCallbacks.ReportHeavyWeaponBoxSpawnFlow = emptyFunc
        _G.GameplayCallbacks.ReportHeavyWeaponBoxActivationFlow = emptyFunc
        _G.GameplayCallbacks.ReportHeavyWeaponBoxOpenPlayerFlow = emptyFunc
        _G.GameplayCallbacks.ReportHeavyWeaponBoxItemFlow = emptyFunc
        _G.GameplayCallbacks.ReportPlayersPing = emptyFunc
        _G.GameplayCallbacks.ReportPlayerIP = emptyFunc
        _G.GameplayCallbacks.ReportPlayerFramePingRecord = emptyFunc
        _G.GameplayCallbacks.OnDSConnectionSaturated = emptyFunc
        _G.GameplayCallbacks.ReportDSNetSaturation = emptyFunc
        _G.GameplayCallbacks.ReportNetContinuousSaturate = emptyFunc
        _G.GameplayCallbacks.ReportDSNetRate = emptyFunc
        _G.GameplayCallbacks.SendClientStats = emptyFunc
        _G.GameplayCallbacks.SendServerAvgTickDelta = emptyFunc
        _G.GameplayCallbacks.ReportCircleFlow = emptyFunc
        _G.GameplayCallbacks.ReportDSCircleFlow = emptyFunc
        _G.GameplayCallbacks.ReportJumpFlow = emptyFunc
        _G.GameplayCallbacks.ReportAIStrategyInfo = emptyFunc
        _G.GameplayCallbacks.SendAIDeliveryInfo = emptyFunc
        _G.GameplayCallbacks.ReportDailyTaskInfo = emptyFunc
        _G.GameplayCallbacks.ReportMatchRoomData = emptyFunc
        _G.GameplayCallbacks.SendPlayerSpectatingLog = emptyFunc
        _G.GameplayCallbacks.ReportIDCardProduceFlow = emptyFunc
        _G.GameplayCallbacks.ReportIDCardPickUpFlow = emptyFunc
        _G.GameplayCallbacks.ReportIDCardDestroyFlow = emptyFunc
        _G.GameplayCallbacks.ReportRevivalFlow = emptyFunc
        _G.GameplayCallbacks.ReportGameSetting = emptyFunc
        _G.GameplayCallbacks.ReportGameSettingNew = emptyFunc
        _G.GameplayCallbacks.ReportAntsVoiceTeamCreate = emptyFunc
        _G.GameplayCallbacks.ReportAntsVoiceTeamQuit = emptyFunc
        _G.GameplayCallbacks.ReportCommonInfo = emptyFunc
        _G.GameplayCallbacks.ReportLightweightStat = emptyFunc
        _G.GameplayCallbacks.SendSecTLog = emptyFunc
        _G.GameplayCallbacks.SendDataMiningTLog = emptyFunc
        _G.GameplayCallbacks.GetGeneralTLogData = function() return nil end
        _G.GameplayCallbacks.SendActivityTLog = emptyFunc
        _G.GameplayCallbacks.IsBypassed = true
    end)

    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local origSendPacket = NetUtil.SendPacket
            local blockedPackets = {
                ReportAttackFlow = 1,
                ReportSecAttackFlow = 1,
                ReportHurtFlow = 1,
                ReportFireArms = 1,
                ReportVerifyInfoFlow = 1,
                ReportMrpcsFlow = 1,
                ReportPlayerBehavior = 1,
                ReportTeammatHurt = 1,
                ReportTeammateKillConfirmFlow = 1,
                ReportForbiddenPickupFlow = 1,
                ReportPlayerMoveRoute = 1,
                ReportPlayerPosition = 1,
                ReportSecVehicleMoveFlow = 1,
                ReportSecTgameMovingFlow = 1,
                report_parachute_data = 1,
                report_character_all_drag = 1,
                report_parachute_all_drag = 1,
                report_vehicle_move_drag = 1,
                on_tss_sdk_anti_data = 1,
                report_unrealnet_exception = 1,
                ReportPlayerEquipmentInfo = 1,
                ReportAimFlow = 1,
                ReportHitFlow = 1,
                log_shooting_miss = 1,
                report_heavy_weapon_box_activation_flow = 1,
                report_heavy_weapon_box_item_flow = 1,
                ReportCircleFlow = 1,
                report_ds_player_circle_flow = 1,
                ReportJumpFlow = 1,
                ReportGameStartFlow = 1,
                ReportGameEndFlow = 1,
                report_players_ping = 1,
                report_player_ip = 1,
                report_player_frame_ping_record = 1,
                report_net_saturate = 1,
                report_ds_netsaturate = 1,
                report_ds_net_continuous_saturate = 1,
                report_ds_netrate = 1,
                report_unrealnet_clientstats = 1,
                report_serverstat_avgtickdelta = 1,
                report_all_players_address = 1,
                report_ai_strategyinfo = 1,
                ReportAIActionFlow = 1,
                ReportGenerateMonsterFlow = 1,
                report_ds_match_room_data = 1,
                SendSpectatingLog = 1,
                ReportIDCardProduceFlow = 1,
                ReportIDCardPickUpFlow = 1,
                ReportIDCardDestroyFlow = 1,
                ReportRevivalFlow = 1,
                ReportGameSetting = 1,
                ReportGameSettingNew = 1,
                ReportAntsVoiceTeamCreate = 1,
                ReportAntsVoiceTeamQuit = 1,
                report_common_info = 1,
                report_common_battle_info = 1,
                report_client_scan_result = 1,
                tss_sdk_report = 1,
                report_memory_exception = 1,
                report_avatar_exception = 1,
                report_ui_state = 1,
                report_hit_reg_fail = 1,
                report_character_state = 1,
                report_vehicle_exception = 1,
                report_camera_exception = 1,
                ReportPlayerControllerStateChanged = 1,
                ReportAvatarFlow = 1,
            }

            NetUtil.SendPacket = function(packetType, ...)
                if blockedPackets[packetType] then
                    return
                end
                return origSendPacket(packetType, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

function _G.KASHMIRY_BYPASS_CONNECTED()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then
            return
        end

        local origOnDSPlayerStateChanged = _G.GameplayCallbacks.OnDSPlayerStateChanged
        _G.GameplayCallbacks.OnDSPlayerStateChanged = function(self, stateType, ...)
            local stateStr = ""
            if stateType then
                stateStr = string.lower(tostring(stateType))
            end
            local blockedStates = {
                cheatdetected = true,
                connectionlost = true,
                connectiontimeout = true,
                connectionexception = true,
                netdrivererror = true,
            }
            if blockedStates[stateStr] then
                return
            end
            if origOnDSPlayerStateChanged then
                pcall(origOnDSPlayerStateChanged, self, stateType, ...)
            end
        end

        _G.GameplayCallbacks.OnPlayerNetConnectionClosed = function(self, ...) end
        _G.GameplayCallbacks.OnPlayerActorChannelError = function(self, ...) end
        _G.GameplayCallbacks.OnPlayerRPCValidateFailed = function(self, ...) end
        _G.GameplayCallbacks.OnPlayerSpectateException = function(self, ...) end
        _G.GameplayCallbacks.OnShutdownAfterError = function(self) end

        _G.ConnectionGuardInitialized = true
    end)
end

function _G.KASHMIRY_BYPASS_BLOCK()
    pcall(function()
        local TLog = package.loaded.TLog or _G.TLog
        if TLog then
            TLog.Info = function() end
            TLog.Warning = function() end
            TLog.Error = function() end
            TLog.Debug = function() end
            TLog.Report = function() end
        end

        local CrashSight = package.loaded.CrashSight or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end
            CrashSight.Log = function() end
        end

        local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReport then
            ClientToolsReport.SendReport = function() end
            ClientToolsReport.SendException = function() end
        end

        local ClientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
        if ClientTLogUtil then
            ClientTLogUtil.ReportGeneralCountByBRPhase = function() end
            ClientTLogUtil.ReportCommonTLogDataByBRPhase = function() end
        end

        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local gameReport = SubsystemMgr:Get("GameReportSubsystem")
            if gameReport then
                gameReport.CheckCanBugglyPostException = function() return false end
                gameReport.BugglyPostExceptionFull = function() return false end
            end
        end
    end)
end

function _G.KASHMIRY_BYPASS_LOG()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubsystemMgr then
            return
        end

        local afkReportor = SubsystemMgr:Get("AFKReportorSubsystem")
        if afkReportor then
            afkReportor.PlayerHaveAction = function() end
            afkReportor.ReportAFK = function() end
        end

        local avatarException = SubsystemMgr:Get("AvatarExceptionSubsystem")
        if avatarException then
            avatarException.ReportException = function() end
            avatarException.BindPlayerCharacter = function() end
            avatarException.CheckAvatarValid = function() return true end
        end

        local shootVerify = SubsystemMgr:Get("ShootVerifySubSystemClient")
        if shootVerify then
            shootVerify.ReportVerifyFail = function() end
            shootVerify.OnVerifyFailed = function() end
        end

        local TssSdk = package.loaded.TssSdk or _G.TssSdk
        if TssSdk then
            TssSdk.OnRecvData = function() end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
        end
    end)
end

function _G.KASHMIRY_BYPASS_REPLAY()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")

        if SubsystemMgr then
            local rescueReplay = SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
            if rescueReplay then
                rescueReplay.ReportTrace = function() end
                rescueReplay.StartTickMonitor = function() end
                rescueReplay.TickMonitorCheck = function() end
                rescueReplay.ReportTickMonitorHeartbeat = function() end
            end
        end

        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils then
            GameReportUtils.ReplayReportData = function() end
            GameReportUtils.ReportGameException = function() end
        end

        if SubsystemMgr then
            local gameReport = SubsystemMgr:Get("GameReportSubsystem")
            if gameReport then
                gameReport.ReplayReportData = function() return false end
                if gameReport.Reporter then
                    gameReport.Reporter.ReportIntArrayData = function() end
                    gameReport.Reporter.ReportUInt8ArrayData = function() end
                    gameReport.Reporter.ReportFloatArrayData = function() end
                end
            end
        end
    end)
end

function _G.InitializeAllBypasses()
    pcall(function()
        _G.KASHMIRY_BYPASS_INSTALL()
        _G.KASHMIRY_BYPASS_HOOK()
        _G.KASHMIRY_BYPASS_ISLAND()
        _G.KASHMIRY_BYPASS_CONNECTED()
        _G.KASHMIRY_BYPASS_BLOCK()
        _G.KASHMIRY_BYPASS_LOG()
        _G.KASHMIRY_BYPASS_REPLAY()
        _G.DisableHiggsBoson()
        print("[✓ BYPASS] All Bypasses Initialized Successfully!")
    end)
end

-- ============================================================
-- UI HOOKS
-- ============================================================

local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
local LobbyWifiUI = require("client.slua.umg.lobby.Main.Lobby_Main_Wifi_UIBP")
local origUpdateQuality = LobbyWifiUI.__inner_impl.UpdateQuality

function LobbyWifiUI.__inner_impl.UpdateQuality(self)
    self.UIRoot.WidgetSwitcher_Quality:SetActiveWidgetIndex(0)
    self.UIRoot.TextBlock_High:SetText("KASHMIRY")
    self.UIRoot.TextBlock_High:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.85, 0.8, 1)))
end

local origUpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI

function IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI(self, quality, mode)
    self.UIRoot.TextBlock_quality:SetText("KASHMIRY")
    pcall(function()
        if not _G.InGameUITools then
            _G.InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        end
        local mainControl = _G.InGameUITools.GetMainControlBaseUI()
        if mainControl then
            mainControl.TextBlock_BID:SetText("Telegram: @OFFICAL_KASHMIRY1")
            mainControl.TextBlock_BID:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.75, 0.8, 1)))
            mainControl.TextBlock_Hour:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end)
end

local origOnInitialize = IngamePhoneStateUI.__inner_impl.OnInitialize

function IngamePhoneStateUI.__inner_impl.OnInitialize(self)
    origOnInitialize(self)
    if self.UIRoot.TextBlock_quality then
        self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0.6, 0.2, 1)))
    end
end
