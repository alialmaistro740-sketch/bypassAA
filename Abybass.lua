-- ═══════════════════════════════════════════════════════════════════
-- 🔥 BYPASS MEGA ENGINE V4 🔥
-- 48 طبقة حقيقية | يدعم PUBG 64-bit
-- يمنع الباند + يعطّل الحمايات + يمنع التحديثات الداخلية
-- ═══════════════════════════════════════════════════════════════════

if _G.__BYPASS_MEGA_LOADED then return _G.__BYPASS_MEGA_LOADED end

local M = {
    VERSION = "4.0",
    LAYERS_OK = 0,
    LAYERS_FAIL = 0,
    BLOCKED = 0,
    LOG = {},
}

-- ═════════════════ أدوات ═════════════════
local function L(tag, msg)
    if type(print) == "function" then
        pcall(print, "[BYPASS:" .. tag .. "] " .. tostring(msg))
    end
end

local function safe(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn, ...)
    if not ok then L("ERR", err) return false end
    return true
end

local function noop() return true end
local function no() return false end
local function zero() return 0 end
local function empty() return {} end
local function estr() return "" end

-- ═══════════════════════════════════════════════════════════════════
-- الطبقات 1-10: تعطيل الحمايات الرئيسية
-- ═══════════════════════════════════════════════════════════════════

-- Layer 1: HiggsBoson Component (القلب النابض للحماية)
local function L1_HiggsBoson()
    L("L1", "HiggsBoson kill")
    local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if not ok or type(mod) ~= "table" then return end

    local methods = {
        "ControlMHActive","Tick","OnTick","ReceiveTick","MHActiveLogic",
        "TriggerAvatarCheck","StartAvatarCheck","ReportItemID","OnReportItemID",
        "ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert",
        "StaticShowSecurityAlertInDev","SendHisarData","OnLogin",
        "ValidateSecurityData","CheckMemoryIntegrity","ReportAbnormalMemory",
        "OnMemoryScanComplete","SendDetectionResult","TriggerClientScan",
        "SendAntiDataFlow","SendHitFireBtnFlow","OnGameModeType",
    }
    for _, name in ipairs(methods) do
        if type(mod[name]) == "function" then mod[name] = noop end
    end

    local retTrue = { "CheckWeaponIntegrity","CheckAvatarIntegrity","CheckBulletIntegrity" }
    for _, name in ipairs(retTrue) do
        if type(mod[name]) == "function" then mod[name] = noop end
    end

    local retEmpty = { "GetNetAvatarItemIDs","GetDetectionResult" }
    for _, name in ipairs(retEmpty) do
        if type(mod[name]) == "function" then mod[name] = empty end
    end

    if type(mod.GetCurWeaponSkinID) == "function" then mod.GetCurWeaponSkinID = zero end

    pcall(function()
        mod.bMHActive = false
        mod.mHActive = 0
    end)

    -- __inner_impl
    pcall(function()
        if type(mod.__inner_impl) == "table" then
            for _, name in ipairs(methods) do
                if type(mod.__inner_impl[name]) == "function" then
                    mod.__inner_impl[name] = noop
                end
            end
        end
    end)

    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 2: TssSDK (نظام الحماية الأساسي)
local function L2_TssSDK()
    L("L2", "TssSDK kill")
    local tss = _G.TssSdk or package.loaded["TssSdk"]
    if not tss then
        local ok, mod = pcall(require, "TssSdk")
        if ok then tss = mod end
    end
    if type(tss) ~= "table" then return end

    local funcs = {
        "GetSdkAntiData","GameScreenshot","GameScreenshot2","IsEmulator",
        "QueryOpts","GetCommLibValueByKey","GetShellDyMagicCode","AddMTCJTask",
        "SetToken","EnableDisableItem","InvokeCrashFromShell","ReInitMrpcs",
        "GetUserTag","QueryTssLibcAddr","RegistLibcSendListener",
        "RegistLibcRecvListener","RegistLibcConnectListener","RegistLibcCloseListener",
        "GetMrpcsData2Ptr","GetTPChannelVer","SetGameChannelIp","SetValueByKey",
        "SetChannelHost","SetChannelBuiltinIp","RecvSecSignature","PushAntiData3",
        "QueryRemainsAntiDataCount","GetAntiData3","DelAntiData3","SetSecToken",
        "GetThreadsInfo","AddTouchEvent","InitSwitchStr","SetCDNHost",
        "SetEnabledConnector","QueryHookInfo","SetCSLicense","AddAnoTouchEvent",
        "GetObjVMFuncAddr","ScanMemory","ScanSo","ScanFile","GetRiskFlag",
        "VerifyFileHash","CheckKernel","VerifyBoot","GetAntiDataQueue",
        "ReportAntiData","SendAntiData","ReportSdkData","SendSdkData","OnRecvData",
        "ReportData","SendToServer","SetUserInfo","Init","Start",
    }
    for _, name in ipairs(funcs) do
        if type(tss[name]) == "function" then
            tss[name] = function() return true, "OK" end
        end
    end

    if type(tss.Verify) == "function" then tss.Verify = noop end
    if type(tss.CheckIntegrity) == "function" then tss.CheckIntegrity = noop end
    if type(tss.Check) == "function" then tss.Check = noop end
    if type(tss.GetSignature) == "function" then
        tss.GetSignature = function() return "BYPASSED" end
    end

    pcall(function()
        tss.antiDataQueue = {
            push = noop, pop = function() return nil end,
            size = zero, clear = noop,
        }
    end)

    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 3: Anti-Cheat Manager
local function L3_AntiCheat()
    L("L3", "AntiCheat Manager")
    safe(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local mgr = pc.PlayerAntiCheatManager or pc.AntiCheatManager
        if not slua.isValid(mgr) then return end

        local counters = {
            "AutoAimFailedCnt","TrackingFailedCnt","AreaDamageFailedCnt",
            "JumpHeightFailedCnt","JumpFarFailedCnt","VehicleFlyingFailedCnt",
            "ShootVerifyTimes","SpeedUpValue","ClientTimeTotalAcc",
            "ServerAccumulateErrors","ServerAvgErrors","ServerCorrectTimes",
            "PlayerBadPingTimes","VehicleSpeedZDeltaTotal",
            "VehicleSpeedZDeltaOver10Times","PVSInCityKillCount",
            "PVSNotInCityKillCount","PVSCellHidePercent","PVSTotalHidePercent",
        }
        for _, f in ipairs(counters) do
            pcall(function()
                if type(mgr[f]) == "number" then mgr[f] = 0 end
            end)
        end

        local bools = {
            "bReportFeedBack","bOpenDetailDataCollect","bOpenBaseDiffCheck",
            "bUploadStuckGroundCount","bStuckGroundCapsule",
            "bImpactOtherAfterBurst","bGiveupPickupWhenBrust",
        }
        for _, f in ipairs(bools) do
            pcall(function()
                if type(mgr[f]) == "boolean" then mgr[f] = false end
            end)
        end

        local maxes = {
            "MaxShootPointPassWall","MaxMuzzleHeightTime","MaxLocusFailTime",
            "MaxBulletVictimClientPassWallTimes","MaxGunPosErrorTimes",
            "MaxSingleShotDamage","MaxFallingSustainTime","MaxMoveDistance2DPerSecond",
        }
        for _, f in ipairs(maxes) do
            pcall(function()
                if type(mgr[f]) == "number" then mgr[f] = 999999 end
            end)
        end

        M.LAYERS_OK = M.LAYERS_OK + 1
    end)
end

-- Layer 4: Safety Detection Subsystem
local function L4_Safety()
    L("L4", "Safety Detection")
    local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Common.Security.SafetyDetectionSubsystem")
    if ok and type(mod) == "table" then
        for _, name in ipairs({"DetectAbnormal","ReportAbnormal","OnDetectionResult","TriggerSafetyScan"}) do
            if type(mod[name]) == "function" then mod[name] = noop end
        end
        if type(mod.GetScanResults) == "function" then mod.GetScanResults = empty end
        if type(mod.IsAnomalyDetected) == "function" then mod.IsAnomalyDetected = no end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 5: HawkEye (المراقبة)
local function L5_HawkEye()
    L("L5", "HawkEye block")
    _G.IsBeingWatched = false

    local targets = {
        "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem",
        "GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.ClientHawkEyePatrolSubsystem",
    }
    for _, path in ipairs(targets) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            local funcs = {
                "_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer",
                "_OnRecvInspectorBroadcastCount","SendReportTLog","ReportCheat",
                "_OnHawkFlag","ReportPlayerFlag","RequestFlagPlayer","SendFlagReport",
                "RequestImprison","_InitHawkEyePatrolSubsystem",
                "_CollectBeWatchedPlayerInfo","ServerRPC_HawkReportCheat",
            }
            for _, name in ipairs(funcs) do
                if type(mod[name]) == "function" then mod[name] = noop end
            end
            if type(mod.CanInspectorBroadcast) == "function" then
                mod.CanInspectorBroadcast = no
            end
            if type(mod.IsDuringHawkEyePatrol) == "function" then
                mod.IsDuringHawkEyePatrol = no
            end
            if type(mod.HasReported) == "function" then
                mod.HasReported = noop
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 6: Ban Logic
local function L6_BanLogic()
    L("L6", "Ban logic kill")
    local paths = {
        "client.slua.logic.ban.ClientBanLogic",
        "client.slua.logic.ban.BanTipsLogic",
        "GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic",
        "GameLua.Mod.BaseMod.Client.Security.ClientBanLogic",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            local funcs = {
                "OnSyncBanInfo","OnVoiceBanNotify","OnRealTimeVoiceBanNotify",
                "OnVoiceBanSuccess","OnSyncMicSuspicious","OnSyncMicPreFilter",
                "OnNotifyWarningTips","ReqBanInfo",
                "ShowBanTips","ShowPunishTips","ShowWarningTips","OnReceiveBanNotice",
            }
            for _, name in ipairs(funcs) do
                if type(mod[name]) == "function" then mod[name] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 7: Flag Subsystem
local function L7_Flags()
    L("L7", "Flag subsystem")
    safe(function()
        local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Client.Security.ClientFlagSubsystem")
        if ok and type(mod) == "table" then
            for _, name in ipairs({"EvaluateFlags","ReportFlag","SyncFlagStatus","IncreaseFlagCount","ResetFlags"}) do
                if type(mod[name]) == "function" then mod[name] = noop end
            end
            if type(mod.GetFlagLevel) == "function" then mod.GetFlagLevel = zero end
            if type(mod.GetFlagBanDuration) == "function" then mod.GetFlagBanDuration = zero end
            if type(mod.IsFlagged) == "function" then mod.IsFlagged = no end
            pcall(function()
                mod.FlagCount = 0
                mod.FlagLevel = 0
                mod.FlagSeverity = 0
            end)
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 8: Login Ban
local function L8_LoginBan()
    L("L8", "Login ban kill")
    local paths = {
        "client.slua.logic.login.logic_login_ban",
        "client.slua.logic.ban.logic_flag_ban",
        "GameLua.Mod.BaseMod.Client.Login.LoginLock",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            if type(mod.CheckCanLogin) == "function" then mod.CheckCanLogin = noop end
            if type(mod.IsBanned) == "function" then mod.IsBanned = no end
            if type(mod.IsSecurityBan) == "function" then mod.IsSecurityBan = no end
            if type(mod.IsFlagBanned) == "function" then mod.IsFlagBanned = no end
            if type(mod.CheckFlagBan) == "function" then mod.CheckFlagBan = no end
            if type(mod.CheckBan) == "function" then mod.CheckBan = no end
            if type(mod.GetBanInfo) == "function" then
                mod.GetBanInfo = function() return { end_time = 0 } end
            end
            if type(mod.GetBanEndTime) == "function" then mod.GetBanEndTime = zero end
            if type(mod.GetFlagBanEndTime) == "function" then mod.GetFlagBanEndTime = zero end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 9: Reports
local function L9_Reports()
    L("L9", "Report suppression")
    local paths = {
        "client.slua.logic.ClientAppStat",
        "GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager",
        "GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil",
        "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
        "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
        "GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Submit")) then
                    mod[k] = noop
                    M.BLOCKED = M.BLOCKED + 1
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 10: Globals cleanup
local function L10_Globals()
    L("L10", "Global cleanup")
    local tables = {
        "_G.Bugly", "_G.Beacon", "_G.CrashSight",
        "_G.ClientToolsReport", "_G.NetUtil", "_G.TDataMaster",
        "_G.ClientTlogHandler", "_G.LoginAndWinTlogHandler",
        "_G.tlog_report_utils", "_G.BasicDataTLogReport",
        "_G.BasicDataClientReport", "_G.BasicDataReport",
        "_G.puffer_tlog", "_G.ClientErrorReportHandler",
        "_G.BattleReportHandler", "_G.BugHandler",
        "_G.LobbyPingReportHandler", "_G.WeekRportHandler",
        "_G.logic_complaint", "_G.EmulatorHandler",
        "_G.emulator_scanner", "_G.LoginVerifyHandler",
        "_G.logic_ds_monitor", "_G.logic_chat_voice_report",
        "_G.logic_chat_voice_doctor", "_G.logic_home_audit_state",
        "_G.logic_home_report", "_G.gem_report_utils",
        "_G.ChatHandler", "_G.ClientReplayDataReporter",
        "_G.ServerDataMgr", "_G.GameSafeCallbacks",
    }
    for _, tname in ipairs(tables) do
        local gname = tname:gsub("^_G%.", "")
        local target = _G[gname]
        if type(target) == "table" then
            for k, v in pairs(target) do
                if type(v) == "function" then
                    target[k] = noop
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- الطبقات 11-20: منع التحديثات الداخلية
-- ═══════════════════════════════════════════════════════════════════

local function L11_HotfixManager()
    L("L11", "Hotfix manager")
    local paths = {
        "GameLua.Mod.BaseMod.Client.Hotfix.HotfixManager",
        "GameLua.Mod.BaseMod.Client.Hotfix.HotfixDownloader",
        "client.slua.logic.hotfix.logic_hotfix",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" and (k:find("Download") or k:find("Apply") or k:find("Start") or k:find("Request")) then
                    mod[k] = noop
                elseif type(v) == "function" and k:find("Check") then
                    mod[k] = no
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L12_VersionUpdate()
    L("L12", "Version update block")
    local paths = {
        "client.slua.logic.login.logic_version_update",
        "client.slua.logic.version.logic_update",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Check") or k:find("Is") then
                        mod[k] = no
                    else
                        mod[k] = noop
                    end
                end
            end
            if type(mod.GetVersion) == "function" then
                mod.GetVersion = function() return "4.4.0" end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L13_PatchManager()
    L("L13", "Patch manager")
    local paths = {
        "GameLua.Mod.BaseMod.Client.Patch.PatchManager",
        "client.slua.logic.patch.logic_patch",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Check") or k:find("Has") then
                        mod[k] = no
                    else
                        mod[k] = noop
                    end
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L14_ContentUpdater()
    L("L14", "Content updater")
    local paths = {
        "GameLua.Mod.BaseMod.Client.Content.ContentUpdater",
        "GameLua.Mod.BaseMod.Client.Config.ConfigUpdater",
        "GameLua.Mod.BaseMod.Client.CDN.CDNUpdater",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L15_SecurityUpdater()
    L("L15", "Security updater")
    local paths = {
        "GameLua.Mod.BaseMod.Common.Security.SecurityDataUpdater",
        "GameLua.Mod.BaseMod.Client.Security.AntiCheatUpdate",
        "GameLua.Mod.BaseMod.Client.Security.HiggsBosonUpdater",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Check") or k:find("Is") then
                        mod[k] = no
                    else
                        mod[k] = noop
                    end
                end
            end
            if type(mod.GetCurrentVersion) == "function" then
                mod.GetCurrentVersion = function() return "999.0" end
            end
            if type(mod.GetSecurityVersion) == "function" then
                mod.GetSecurityVersion = function() return "9.9" end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 16: HTTP blocker
local function L16_HttpBlocker()
    L("L16", "HTTP hotfix blocker")
    if type(_G.HttpRequest) ~= "function" then
        M.LAYERS_FAIL = M.LAYERS_FAIL + 1
        return
    end
    local orig = _G.HttpRequest
    local blocked = { "hotfix", "update", "patch", "cdn/version", "downloadpatch" }
    _G.HttpRequest = function(url, cb, ...)
        if type(url) == "string" then
            local lower = url:lower()
            for _, w in ipairs(blocked) do
                if lower:find(w, 1, true) then
                    L("L16", "Blocked: " .. url:sub(1, 60))
                    M.BLOCKED = M.BLOCKED + 1
                    if type(cb) == "function" then pcall(cb, false, "") end
                    return true
                end
            end
        end
        return orig(url, cb, ...)
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 17: Console command filter
local function L17_ConsoleFilter()
    L("L17", "Console filter")
    safe(function()
        local KSL = import("KismetSystemLibrary")
        if not KSL or type(KSL.ExecuteConsoleCommand) ~= "function" then return end
        local orig = KSL.ExecuteConsoleCommand
        KSL.ExecuteConsoleCommand = function(world, cmd)
            if type(cmd) == "string" then
                local l = cmd:lower()
                if l:find("update", 1, true) or l:find("patch", 1, true)
                   or l:find("hotfix", 1, true) or l:find("security", 1, true) then
                    L("L17", "Cmd blocked: " .. cmd:sub(1, 40))
                    return
                end
            end
            return orig(world, cmd)
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- Layer 18-20: احتياطي
local function L18_IntegrityCheck()
    L("L18", "Integrity check")
    local paths = {
        "GameLua.Mod.BaseMod.Common.Security.IntegrityCheck",
        "GameLua.Mod.BaseMod.Common.Security.LuaIntegrityCheck",
        "GameLua.Mod.BaseMod.Common.Security.APKIntegrity",
        "GameLua.Mod.BaseMod.Common.Security.LibCheck",
        "GameLua.Mod.BaseMod.Common.Security.PakIntegrityChecker",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Check") or k:find("Verify") or k:find("Is") then
                        mod[k] = noop
                    else
                        mod[k] = noop
                    end
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L19_Memory()
    L("L19", "Memory protection")
    for _, name in ipairs({"mprotect","munmap","ptrace","monitor","getpid","getppid","gettid"}) do
        if _G[name] then _G[name] = function() return 0 end end
    end
    if _G.ReportAbnormalMemory then _G.ReportAbnormalMemory = noop end
    if _G.CheckMemoryIntegrity then _G.CheckMemoryIntegrity = noop end
    if _G.TriggerClientScan then _G.TriggerClientScan = noop end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L20_Network()
    L("L20", "Network protection")
    for _, name in ipairs({"sys_read","sys_open","nanosleep","imp_recv","imp_send","socket"}) do
        if _G[name] then _G[name] = noop end
    end
    for _, name in ipairs({"strstr","strcpy","strncpy"}) do
        if _G[name] then _G[name] = estr end
    end
    if _G.strlen then _G.strlen = zero end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- الطبقات 21-30: أنظمة إضافية
-- ═══════════════════════════════════════════════════════════════════

local function L21_DeviceCheck()
    L("L21", "Device check")
    local paths = {
        "GameLua.Mod.BaseMod.Client.Security.ClientDeviceCheckSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.DSDeviceCheck",
        "GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint",
        "GameLua.Mod.BaseMod.Client.Security.SecureBootCheck",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Is") or k:find("Verify") or k:find("Check") then
                        mod[k] = noop
                    elseif k:find("Get") then
                        mod[k] = estr
                    else
                        mod[k] = noop
                    end
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L22_Inspection()
    L("L22", "Inspection block")
    local paths = {
        "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L23_AFK()
    L("L23", "AFK subsystem")
    local paths = {
        "GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem",
        "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Check") then mod[k] = no
                    else mod[k] = noop end
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L24_Macro()
    L("L24", "Macro/Speedhack block")
    local paths = {"BanMacro","NGActionBanSprint","SpeedhackValidator","InputVarianceChecker"}
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    if k:find("Is") or k:find("Check") then mod[k] = no
                    elseif k:find("Get") then mod[k] = zero
                    else mod[k] = noop end
                end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L25_Emulator()
    L("L25", "Emulator hide")
    safe(function()
        if _G.EmulatorHandler then
            _G.EmulatorHandler.send_emulator_info = noop
        end
        if _G.emulator_scanner then
            _G.emulator_scanner.StartScan = noop
            _G.emulator_scanner.GetScanResult = no
        end
        local paths = {"EmulatorSystem","logic_emulator"}
        for _, path in ipairs(paths) do
            local ok, mod = pcall(require, path)
            if ok and type(mod) == "table" then
                for k, v in pairs(mod) do
                    if type(v) == "function" then
                        if k:find("Is") then mod[k] = no
                        elseif k:find("Get") then
                            mod[k] = function() return "NoEmulator" end
                        else mod[k] = noop end
                    end
                end
                pcall(function() mod.EmulatorTestMark = true end)
            end
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L26_AutoClick()
    L("L26", "AutoClick detect kill")
    local paths = {"HawkEyeSpectatorState","VoiceReportSubsystem","BugglyReportRecord"}
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L27_QuickReport()
    L("L27", "Quick report kill")
    local paths = {
        "DSQuickReportMaliciousTeammate",
        "ClientQuickReportMaliciousTeammate",
        "GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L28_Patroller()
    L("L28", "Patroller block")
    safe(function()
        local ok, mod = pcall(require, "PatrollerModule")
        if ok and type(mod) == "table" then
            mod.UpdateStats = noop
            mod.GetRank = zero            mod.AddInspectionRecord = noop
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L29_Screenshot()
    L("L29", "Screenshot block")
    safe(function()
        local MTDer = import("ScreenshotMTDer")
        if MTDer then
            MTDer.MTDePicture = function() return "" end
            MTDer.ReMTDePicture = function() return "" end
            MTDer.HasCaptured = noop
            MTDer.TakeScreenshot = noop
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L30_TLog()
    L("L30", "TLog kill")
    local paths = {
        "TLog","puffer_tlog","tlog_report_utils",
    }
    for _, path in ipairs(paths) do
        local t = package.loaded[path] or _G[path]
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(v) == "function" then t[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- الطبقات 31-40: أنظمة slua + require
-- ═══════════════════════════════════════════════════════════════════

local function L31_SluaVerify()
    L("L31", "slua verify kill")
    safe(function()
        if slua then
            slua.getSignature = function() return 0xDEADBEEF end
            slua.verifyBytecode = noop
            slua.checkIntegrity = noop
        end
        local loader = package.loaded["slua.loader"]
        if type(loader) == "table" then
            loader.verifyBytecode = noop
            loader.checkIntegrity = noop
            loader.disableSignatureCheck = noop
        end
        local ser = package.loaded["slua.serialize"]
        if type(ser) == "table" then
            ser.check = noop
            ser.verify = noop
        end
        if _G.slua_verify then _G.slua_verify = noop end
        if _G.check_slua_integrity then _G.check_slua_integrity = noop end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L32_MD5Bypass()
    L("L32", "MD5 bypass")
    safe(function()
        local Creative = import("CreativeModeBlueprintLibrary")
        if Creative then
            Creative.MD5HashByteArray = function() return "0" end
            Creative.MD5HashFile = function() return "0" end
            Creative.GetContentDiffData = function() return true, "OK" end
            Creative.VerifyFileIntegrity = noop
        end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then
            STExtra.CheckMD5 = noop
            STExtra.GetMD5 = function() return "OK" end
            STExtra.VerifyFile = noop
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "0" end end
        if _G.CRC32 then _G.CRC32 = zero end
        if _G.SHA1 then _G.SHA1 = function() return "0" end end
        local FHC = package.loaded["common.file_hash_checker"]
        if type(FHC) == "table" then
            FHC.CheckFileMD5 = noop
            FHC.VerifyAll = noop
            FHC.GetHash = function() return "OK" end
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L33_SkinBypass()
    L("L33", "Skin bypass")
    safe(function()
        local paths = {
            "client.slua.logic.download.report.puffer_tlog",
            "client.slua.logic.report.EquipmentExceptionReport",
            "AvatarUtils",
        }
        for _, path in ipairs(paths) do
            local ok, mod = pcall(require, path)
            if ok and type(mod) == "table" then
                for k, v in pairs(mod) do
                    if type(v) == "function" then
                        if k:find("Check") or k:find("Is") then mod[k] = noop
                        else mod[k] = noop end
                    end
                end
            end
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L34_AnogsPatch()
    L("L34", "libanogs.so patch")
    local SH = _G.ScriptHelperClient
    if not SH then
        M.LAYERS_FAIL = M.LAYERS_FAIL + 1
        return
    end

    local BASE_CACHE = {}
    local function getBase(lib)
        if BASE_CACHE[lib] then return BASE_CACHE[lib] end
        local b = 0
        local ok, r = pcall(SH.GetPUBGModuleBaseAddr, lib)
        if ok and type(r) == "number" then b = r end
        if b == 0 then
            local alt = lib:gsub("%.so$", "")
            local ok2, r2 = pcall(SH.GetPUBGModuleBaseAddr, alt)
            if ok2 and type(r2) == "number" then b = r2 end
        end
        BASE_CACHE[lib] = b
        return b
    end

    local function hex2bin(h)
        return (h:gsub("%x%x", function(x) return string.char(tonumber(x, 16)) end))
    end

    local function patch(lib, off, bytes)
        local b = getBase(lib)
        local addr = b > 0 and (b + off) or nil
        if SH.ProcessSoPatch and addr then
            local ok = pcall(SH.ProcessSoPatch, addr, bytes)
            if ok then return true end
            local ok2 = pcall(SH.ProcessSoPatch, addr, hex2bin(bytes))
            if ok2 then return true end
        end
        if SH.ProcessSoPatch then
            local ok = pcall(SH.ProcessSoPatch, {
                { module = lib, offset = off, addr = addr,
                  bytes = bytes, data = hex2bin(bytes) }
            })
            if ok then return true end
        end
        return false
    end

    local PATCHES = {
        { 0x2328F0, "C0 03 5F D6" },
        { 0x213360, "C0 03 5F D6" },
        { 0x2ECE70, "C0 03 5F D6" },
        { 0x4D5998, "00 00 80 D2 C0 03 5F D6" },
        { 0x4D59A4, "00 00 80 D2 C0 03 5F D6" },
        { 0x4D4DB4, "00 00 80 D2 C0 03 5F D6" },
        { 0x4D4DD0, "00 00 80 D2 C0 03 5F D6" },
        { 0x4D571C, "00 00 80 D2 C0 03 5F D6" },
        { 0x4D5748, "00 00 80 D2 C0 03 5F D6" },
    }

    local c = 0
    for _, p in ipairs(PATCHES) do
        if patch("libanogs.so", p[1], p[2]) then c = c + 1 end
    end
    L("L34", "Anogs: " .. c .. "/" .. #PATCHES)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L35_RequireHook()
    L("L35", "Require hook")
    if type(require) ~= "function" then
        M.LAYERS_FAIL = M.LAYERS_FAIL + 1
        return
    end
    local orig = require
    local patched = {}
    local function hook(name)
        local mod = orig(name)
        if patched[name] then return mod end
        patched[name] = true
        -- الترقيع يتم في الطبقات الفردية، لكن هنا نحمي إعادة الاستدعاء
        return mod
    end
    pcall(function() require = hook end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L36_SessionKeep()
    L("L36", "Session keeper")
    -- منع انتهاء الجلسة
    pcall(function()
        if _G.__SAMEERSession then
            _G.__SAMEERSession.authenticatedAt = os.time and os.time() or 0
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L37_AntiDetect()
    L("L37", "Anti-detection")
    -- إخفاء متغيرات الـ mod من الفحص
    safe(function()
        local hidden = {
            "__BYPASS_MEGA_LOADED",
            "__HackerAnogsBypass",
            "__HackerESPWidgets",
            "__HackerWatermark",
        }
        for _, name in ipairs(hidden) do
            if _G[name] then
                pcall(setmetatable, _G[name], { __tostring = function() return "" end })
            end
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L38_PakSignature()
    L("L38", "Pak signature check")
    safe(function()
        local KSL = import("KismetSystemLibrary")
        if KSL then
            KSL.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            KSL.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            KSL.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            KSL.ExecuteConsoleCommand(nil, "sig.Check 0")
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L39_Process()
    L("L39", "Process hide")
    if _G.getpid then _G.getpid = zero end
    if _G.getppid then _G.getppid = zero end
    if _G.gettid then _G.gettid = zero end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L40_AntiDebug()
    L("L40", "Anti-debug")
    local paths = {"GameLua.Mod.BaseMod.Common.Security.AntiDebug"}
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            mod.Check = no
            mod.Report = noop
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- الطبقات 41-48: طبقات أخيرة
-- ═══════════════════════════════════════════════════════════════════

local function L41_ShootVerify()
    L("L41", "Shoot verify block")
    local paths = {
        "GameLua.Dev.Subsystem.ShootVerifySubSystemClient",
        "GameLua.Mod.BaseMod.Common.Security.ShootVerify",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L42_AimBotDetect()
    L("L42", "Aimbot detector kill")
    local paths = {
        "HawkEyeSpectatorState",
        "GameLua.Mod.BaseMod.Client.Security.HawkEyeAimDetect",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L43_AvatarCheck()
    L("L43", "Avatar check")
    if _G.AvatarCheckCallback then
        for k, v in pairs(_G.AvatarCheckCallback) do
            if type(v) == "function" then
                _G.AvatarCheckCallback[k] = noop
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L44_AntiData()
    L("L44", "AntiData kill")
    safe(function()
        local tss = _G.TssSdk or package.loaded["TssSdk"]
        if type(tss) == "table" then
            if type(tss.AnoSDKDelReportData) == "function" then tss.AnoSDKDelReportData = noop end
            if type(tss.AnoSDKGetReportData) == "function" then tss.AnoSDKGetReportData = function() return nil end end
            if type(tss.GetAntiData3) == "function" then tss.GetAntiData3 = function() return nil end end
            if type(tss.PushAntiData3) == "function" then tss.PushAntiData3 = noop end
        end
    end)
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L45_ErrorReport()
    L("L45", "Error report kill")
    local globals = {
        "ClientErrorReportHandler", "ReportPlatformCrashKit",
    }
    for _, g in ipairs(globals) do
        local t = _G[g]
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(v) == "function" then t[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L46_AutoKick()
    L("L46", "Auto kick block")
    local paths = {
        "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
    }
    for _, path in ipairs(paths) do
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then mod[k] = noop end
            end
        end
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L47_AntiBanFlag()
    L("L47", "Anti ban flag")
    -- منع رفع علم الباند
    _G.Flagged = false
    _G.IsFlagged = false
    _G.FlagLevel = 0
    _G.FlagSeverity = 0
    M.LAYERS_OK = M.LAYERS_OK + 1
end

local function L48_Final()
    L("L48", "Final lock")
    -- منع أي محاولة لإعادة تفعيل الحمايات
    local function lock()
        if _G.__BYPASS_MEGA_LOADED and not _G.__BYPASS_MEGA_LOADED.booted then
            -- إعادة تشغيل
            pcall(function() _G.__BYPASS_MEGA_LOADED.boot() end)
        end
    end
    if type(CGameState) == "table" and type(CGameState.AddGameTimer) == "function" then
        pcall(function()
            CGameState:AddGameTimer(5.0, true, lock)
        end)
    end
    M.LAYERS_OK = M.LAYERS_OK + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- التشغيل الرئيسي
-- ═══════════════════════════════════════════════════════════════════

function M.boot()
    if M.BOOTED then
        L("BOOT", "Already booted")
        return true
    end

    L("BOOT", "═══════════════════════════════════════════")
    L("BOOT", "  BYPASS MEGA V" .. M.VERSION)
    L("BOOT", "  Started: " .. os.date("%H:%M:%S"))
    L("BOOT", "═══════════════════════════════════════════")

    local layers = {
        L1_HiggsBoson, L2_TssSDK, L3_AntiCheat, L4_Safety,
        L5_HawkEye, L6_BanLogic, L7_Flags, L8_LoginBan,
        L9_Reports, L10_Globals,
        L11_HotfixManager, L12_VersionUpdate, L13_PatchManager,
        L14_ContentUpdater, L15_SecurityUpdater, L16_HttpBlocker,
        L17_ConsoleFilter, L18_IntegrityCheck, L19_Memory, L20_Network,
        L21_DeviceCheck, L22_Inspection, L23_AFK, L24_Macro,
        L25_Emulator, L26_AutoClick, L27_QuickReport, L28_Patroller,
        L29_Screenshot, L30_TLog,
        L31_SluaVerify, L32_MD5Bypass, L33_SkinBypass, L34_AnogsPatch,
        L35_RequireHook, L36_SessionKeep, L37_AntiDetect, L38_PakSignature,
        L39_Process, L40_AntiDebug,
        L41_ShootVerify, L42_AimBotDetect, L43_AvatarCheck, L44_AntiData,
        L45_ErrorReport, L46_AutoKick, L47_AntiBanFlag, L48_Final,
    }

    for i, layer in ipairs(layers) do
        local ok = safe(layer)
        if not ok then
            L("BOOT", "Layer " .. i .. " FAILED")
        end
    end

    M.BOOTED = true

    L("BOOT", "═══════════════════════════════════════════")
    L("BOOT", "  Layers OK: " .. M.LAYERS_OK)
    L("BOOT", "  Layers FAIL: " .. M.LAYERS_FAIL)
    L("BOOT", "  Blocked: " .. M.BLOCKED)
    L("BOOT", "═══════════════════════════════════════════")

    return true
end

function M.status()
    return {
        version = M.VERSION,
        booted = M.BOOTED,
        layers_ok = M.LAYERS_OK,
        layers_fail = M.LAYERS_FAIL,
        blocked = M.BLOCKED,
    }
end

_G.__BYPASS_MEGA_LOADED = M
return M
