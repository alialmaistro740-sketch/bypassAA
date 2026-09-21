-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  ⚡ AEGIS PHANTOM ULTIMATE v2.1 — FIXED EDITION                  ║
-- ║  Anti-Ban + Anti-Detection + PAK Shield + Server Blocker         ║
-- ║  Report Shield + Smart Rage + Shadow Mode                        ║
-- ║  FIXED: No RPC/Packet double-hooks | No require override        ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════
-- [المحرك الرئيسي] AEGIS PHANTOM
-- ═══════════════════════════════════════════════════════════════════
local Aegis = {
    Active = false,
    StartTime = 0,
    HeartbeatRate = 0.35,
    Cycle = 0,
    ThreatLevel = 0,
    ShadowActive = false,
    Hooked = {},
    Original = {},
    BlockedIPs = {},
    BlockedDomains = {},
    Kills = 0,
    Headshots = 0,
    LastKillTime = 0,
    KillTimestamps = {},
    CooldownUntil = 0,
    AimMode = "rage",
    PacketBlocked = 0,
    DetectorsKilled = 0,
    TelemetryDestroyed = 0
}

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 1] أدوات مساعدة
-- ═══════════════════════════════════════════════════════════════════
local function AgRndHex(len)
    local c = "0123456789abcdef"
    local t = {}
    for i = 1, len do t[i] = c:sub(math.random(1, 16), math.random(1, 16)) end
    return table.concat(t)
end

Aegis.Capture = function(self, key, fn)
    if not self.Original[key] and type(fn) == "function" then
        self.Original[key] = fn
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 2] إصلاح ملفات أندرويد
-- ═══════════════════════════════════════════════════════════════════
local function AgFixFiles()
    pcall(function()
        local fakePaths = {
            "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/apollo_reslist.flist",
            "/storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/apollo_reslist.flist",
            "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/apollo_reslist.flist"
        }
        for _, path in ipairs(fakePaths) do
            pcall(function()
                local f = io.open(path, "w")
                if f then f:write("1:0\n") f:close() end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 3] جدول IPs و Domains
-- ═══════════════════════════════════════════════════════════════════
local function AgBuildTables(self)
    pcall(function()
        local ips = {
            "43.128.","43.129.","43.130.","43.131.","43.132.","43.133.",
            "43.134.","43.135.","43.136.","43.137.","43.138.","43.139.",
            "43.140.","43.141.","43.142.","43.143.","43.144.","43.145.",
            "43.146.","43.147.","43.148.","43.149.","43.150.","43.151.",
            "43.152.","43.153.","43.154.","43.155.","43.156.","43.157.",
            "43.158.","43.159.","43.160.","43.161.","43.162.","43.163.",
            "129.204.","129.205.","129.206.","129.207.","129.226.","129.227.",
            "101.32.","101.33.","101.34.","101.35.",
            "119.28.","119.29.","119.38.","119.39.",
            "162.14.","162.62.","175.24.","175.27."
        }
        for _, ip in ipairs(ips) do self.BlockedIPs[ip] = true end
        
        local domains = {
            "anticheat.qq.com","tss.tencent.com","ace.tencent.com",
            "pubgm.qq.com","pubgmobile.qq.com","pubg.qq.com",
            "report.qq.com","ban.qq.com","security.qq.com",
            "tlog.qq.com","bugly.qq.com","crash.qq.com",
            "puffer.qq.com","puffer.tencent.com",
            "puffer-pubgm.qq.com","puffer-pubgm.tencent.com",
            "cdn.pubgm.qq.com","cdn-pubgm.qq.com",
            "cdn.pubgmobile.qq.com","cdn.pubgmobile.tencent.com",
            "ig.qq.com","tencent.ig.com","pubgm.tencent.com",
            "battleye.com","easyanticheat.com","xigncode.com"
        }
        for _, d in ipairs(domains) do self.BlockedDomains[d] = true end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 4] ✅ FIXED: لا يوجد require override
-- ═══════════════════════════════════════════════════════════════════
local function AgInstallRequire(self)
    -- تم التعطيل - Require override كان يعطل المود
    -- نستخدم بدلاً منه AgKillDetectors
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 5] محايد الباند الآمن
-- ═══════════════════════════════════════════════════════════════════
local function AgNeutralizeBan()
    pcall(function()
        local numVars = {
            "BanStatus","BanLevel","BanCount","BanTime","BanDuration","BanExpiry",
            "BanType","SuspensionLevel","ViolationLevel","RiskLevel","SecurityLevel",
            "TrustScore","SuspicionScore","ViolationCount","CheatCount","DetectionCount",
            "FlagCount","ReportCount","WarningLevel","SecurityScore","TrustLevel",
            "ReputationScore","HonorScore","AntiCheatScore","BehaviorScore"
        }
        for _, v in ipairs(numVars) do _G[v] = 0 ; rawset(_G, v, 0) end
        
        local boolVars = {
            "IsBanned","bIsBanned","bBan","bBanStatus","bIsPermanentlyBanned",
            "PermanentBan","TempBan","IsSuspicious","bIsSuspicious","IsReported",
            "bIsReported","IsFlagged","bIsFlagged","bIsCheating","bIsHacking",
            "bIsModding","bDetected","bIsWatching","bIsMonitored","bIsInspected"
        }
        for _, v in ipairs(boolVars) do _G[v] = false ; rawset(_G, v, false) end
        
        local strVars = {"BanReason","BanMessage","BanDetails","ViolationReason","FlagReason"}
        for _, v in ipairs(strVars) do _G[v] = "" ; rawset(_G, v, "") end
        
        for _, obj in ipairs({ClientBanLogic, RealTimeBan, BanSystem}) do
            if obj and type(obj) == "table" then
                for k, v in pairs(obj) do
                    local t = type(v)
                    if t == "function" then pcall(function() obj[k] = nop end)
                    elseif t == "boolean" then obj[k] = false
                    elseif t == "number" then obj[k] = 0
                    elseif t == "string" then obj[k] = "" end
                end
            end
        end
        
        if _G.Account then
            _G.Account.IsBanned = false
            _G.Account.BanStatus = 0
            _G.Account.WarningLevel = 0
            _G.Account.IsSuspicious = false
            _G.Account.SecurityLevel = 100
            _G.Account.TrustScore = 100
            _G.Account.SuspicionScore = 0
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 6] ✅ FIXED: قاتل الأنظمة — بدون تعطيل المود
-- ═══════════════════════════════════════════════════════════════════
Aegis.DetectorList = {
    -- Anti-Cheat SDKs
    "TssSdk","ACE","AntiCheatExpert","XignCode","BattlEye",
    "Gokuba","SwiftHawk","CoronaLab","HawkEyePatrol","HiggsBoson","TenProtect",
    -- Report Systems
    "PlayerReport","ReportSystem","ReportManager","ClientReportPlayerSubsystem",
    "DSReportPlayerSubsystem","TLog","tlog_report_utils","ClientToolsReport",
    "GameReportSubsystem","Telemetry","Analytics","BehaviorScoreSubsystem",
    "AFKReportorSubsystem","PlayerSecurityInfoSubsystem","ClientSecurityCollector",
    "ClientSecMrpcsFlowSubsystem","MrpcsFlowSubsystem","CircleFlowSubsystem",
    "KillFlowSubsystem","DeathFlowSubsystem",
    -- Detection Systems
    "MemoryScanner","MemoryCheck","MemoryTamper","DebuggerDetect","MemoryScan",
    "FileIntegrity","PakVerification","MD5Check","SignatureVerify"
    -- ✅ تم حذف ShootVerifySubSystemClient, DamageVerification, HitboxVerification
    -- ✅ تم حذف AimAssistDetect, AimbotDetect, ESPDetect (لأنها تستخدم من المود)
}

local function AgKillDetectors(self)
    pcall(function()
        for _, name in ipairs(self.DetectorList) do
            local sys = _G[name]
            if not sys then
                pcall(function() sys = require("GameLua.Mod.BaseMod.Common.Security." .. name) end)
            end
            if sys and type(sys) == "table" then
                for k, v in pairs(sys) do
                    local t = type(v)
                    if t == "function" then 
                        pcall(function() sys[k] = nop end)
                        self.DetectorsKilled = self.DetectorsKilled + 1
                    elseif t == "boolean" then sys[k] = false
                    elseif t == "number" then sys[k] = 0 end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 7] ✅ FIXED: درع الشبكة — يستخدم Flag واحد
-- ═══════════════════════════════════════════════════════════════════
local function AgNetworkShield(self)
    pcall(function()
        -- ✅ فقط إذا ما كان محجوز مسبقاً
        if NetUtil and NetUtil.SendPacket and not _G._AgPacketHooked then
            _G._AgPacketHooked = true
            local orig = NetUtil.SendPacket
            self.Original["NetUtil.SendPacket"] = orig
            
            local blocked = {
                "report","ban","cheat","hack","detect","verify",
                "security","anti","tss","ace","tlog","telemetry",
                "mrpcs","swifthawk","coronalab","gokuba",
                "requestpak","requesthash","reqverify"
            }
            
            NetUtil.SendPacket = function(packetName, ...)
                local name = tostring(packetName):lower()
                for i = 1, #blocked do
                    if name:find(blocked[i], 1, true) then
                        Aegis.PacketBlocked = Aegis.PacketBlocked + 1
                        return nil
                    end
                end
                return orig(packetName, ...)
            end
            self.Hooked["NetUtil.SendPacket"] = true
        end
        
        -- ✅ SendRPC — flag واحد فقط
        if _G.SendRPC and not _G._AgRPCHooked then
            _G._AgRPCHooked = true
            local orig = _G.SendRPC
            self.Original["SendRPC"] = orig
            
            _G.SendRPC = function(rpcName, ...)
                local name = tostring(rpcName):lower()
                if name:find("report") or name:find("ban") or name:find("verify")
                   or name:find("security") or name:find("anti") or name:find("detect")
                   or name:find("hack") or name:find("kick")
                   or name:find("reportplayer") or name:find("submitreport")
                   or name:find("reportcheater") or name:find("reportviolation")
                   or name:find("report") or name:find("reqverify")
                   or name:find("reqhash") or name:find("requestpak") then
                    return nil
                end
                return orig(rpcName, ...)
            end
            self.Hooked["SendRPC"] = true
        end
        
        -- ✅ Socket
        if socket and socket.connect and not _G._AgSocketHooked then
            _G._AgSocketHooked = true
            local orig = socket.connect
            self.Original["socket.connect"] = orig
            local ips = self.BlockedIPs
            local doms = self.BlockedDomains
            
            socket.connect = function(host, port, ...)
                local h = tostring(host):lower()
                for ip in pairs(ips) do
                    if h:sub(1, #ip) == ip then
                        Aegis.PacketBlocked = Aegis.PacketBlocked + 1
                        return nil, "blocked"
                    end
                end
                for d in pairs(doms) do
                    if h:find(d, 1, true) then
                        Aegis.PacketBlocked = Aegis.PacketBlocked + 1
                        return nil, "blocked"
                    end
                end
                return orig(host, port, ...)
            end
            self.Hooked["socket.connect"] = true
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 8] SSL Bypass
-- ═══════════════════════════════════════════════════════════════════
local function AgSSLBypass()
    pcall(function()
        if ssl and ssl.verify then ssl.verify = function() return true end end
        if ssl and ssl.x509 and ssl.x509.verify then ssl.x509.verify = function() return true end end
        if NetUtil then
            NetUtil.VerifyCertificate = function() return true end
            NetUtil.CheckCertificate = function() return true end
            NetUtil.VerifySSL = function() return true end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 9] حماية الذاكرة
-- ═══════════════════════════════════════════════════════════════════
local function AgMemoryShield()
    pcall(function()
        if debug then
            debug.getinfo = function() return {} end
            debug.sethook = function() end
            debug.getlocal = function() return nil end
            debug.setlocal = function() end
            debug.getupvalue = function() return nil end
            debug.setupvalue = function() end
            debug.getregistry = function() return {} end
            debug.traceback = function() return "" end
        end
        if jit and jit.attach then
            pcall(function() jit.attach(function() end, "bc") end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 10] Telemetry Destroyer
-- ═══════════════════════════════════════════════════════════════════
local function AgDestroyTelemetry(self)
    pcall(function()
        local queues = {
            "TelemetryQueue","LogQueue","ReportQueue","ExceptionQueue",
            "CrashQueue","TraceQueue","BanQueue","KickQueue","FlagQueue",
            "SuspicionQueue","DetectionQueue","VerificationQueue",
            "MonitorQueue","AnalyticsQueue","StatsQueue","SecurityQueue"
        }
        for _, q in ipairs(queues) do
            _G[q] = {}
            rawset(_G, q, {})
            self.TelemetryDestroyed = self.TelemetryDestroyed + 1
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 11] Identity Spoof
-- ═══════════════════════════════════════════════════════════════════
local function AgSpoofIdentity(self)
    pcall(function()
        local id = {
            HWID = AgRndHex(32),
            IMEI = "35" .. AgRndHex(13),
            MAC = AgRndHex(2)..":"..AgRndHex(2)..":"..AgRndHex(2)..":"..AgRndHex(2)..":"..AgRndHex(2)..":"..AgRndHex(2),
            ANDID = AgRndHex(16),
            SERIAL = "SN"..AgRndHex(14),
            DEVID = "AG_"..AgRndHex(24),
            UUID = AgRndHex(8).."-"..AgRndHex(4).."-"..AgRndHex(4).."-"..AgRndHex(4).."-"..AgRndHex(12),
            OAID = AgRndHex(32)
        }
        
        local KSL = import("KismetSystemLibrary")
        if KSL then
            KSL.GetDeviceId = function() return id.HWID end
            KSL.GetUniqueDeviceId = function() return id.UUID end
            KSL.GetMacAddress = function() return id.MAC end
            KSL.GetSerialNumber = function() return id.SERIAL end
        end
        
        local DI = import("DeviceID")
        if DI then
            DI.GetDeviceID = function() return id.DEVID end
            DI.GetIMEI = function() return id.IMEI end
            DI.GetAndroidID = function() return id.ANDID end
            DI.GetMACAddress = function() return id.MAC end
            DI.GetSerialNumber = function() return id.SERIAL end
            DI.GetUniqueDeviceID = function() return id.UUID end
            DI.GetOAID = function() return id.OAID end
        end
        
        local SI = import("SystemInfo")
        if SI then
            SI.IsEmulator = function() return false end
            SI.IsRooted = function() return false end
            SI.IsDebugged = function() return false end
            SI.IsJailbroken = function() return false end
            SI.IsVirtualMachine = function() return false end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 12] كاشف التهديد الذكي
-- ═══════════════════════════════════════════════════════════════════
local function AgThreatScan(self)
    pcall(function()
        local threat = 0
        local now = os.time()
        
        local recent = 0
        for i = #self.KillTimestamps, 1, -1 do
            if now - self.KillTimestamps[i] < 30 then recent = recent + 1 else break end
        end
        if recent >= 4 then threat = threat + 20 end
        if recent >= 6 then threat = threat + 35 end
        if recent >= 8 then threat = threat + 50 end
        
        if self.Kills >= 5 then
            local ratio = self.Headshots / self.Kills
            if ratio > 0.6 then threat = threat + 25 end
            if ratio > 0.75 then threat = threat + 45 end
            if ratio > 0.85 then threat = threat + 60 end
        end
        
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then
                if pc.ClientHawkEyePatrolSubsystem then
                    local he = pc.ClientHawkEyePatrolSubsystem
                    if he._bHasReported or he.bIsWatching then threat = threat + 40 end
                end
            end
        end)
        
        self.ThreatLevel = math.min(100, threat)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 13] التحكم الذكي بالأيم
-- ═══════════════════════════════════════════════════════════════════
local function AgSmartRageControl(self)
    pcall(function()
        if not _G.LexusConfig or not _G.LexusState then return end
        local now = os.time()
        
        if now < self.CooldownUntil then
            self.AimMode = "cooldown"
            return
        end
        
        if self.LastKillTime > 0 and (now - self.LastKillTime) > 180 then
            self.Kills = 0
            self.Headshots = 0
        end
        
        local hsRatio = self.Kills > 0 and (self.Headshots / self.Kills) or 0
        
        if self.ThreatLevel >= 75 then
            self.AimMode = "cooldown"
            self.CooldownUntil = now + math.random(60, 120)
            self.Kills = 0
            self.Headshots = 0
        elseif self.ThreatLevel >= 50 then
            self.AimMode = "legit"
        else
            self.AimMode = "rage"
        end
        
        if self.AimMode == "rage" then
            _G.LexusConfig.AutoHead = true
            if _G.LexusState.CustomTextData then
                _G.LexusState.CustomTextData.AimTouchHipSpeed = 85
                _G.LexusState.CustomTextData.AimTouchHipFOV = 45
                _G.LexusState.CustomTextData.AimTouchScopeSpeed = 75
                _G.LexusState.CustomTextData.AimTouchScopeFOV = 40
                _G.LexusState.CustomTextData.AimTouchSniperSpeed = 60
                _G.LexusState.CustomTextData.AimTouchSniperFOV = 30
            end
        elseif self.AimMode == "legit" then
            _G.LexusConfig.AutoHead = false
            if _G.LexusState.CustomTextData then
                _G.LexusState.CustomTextData.AimTouchHipSpeed = 35
                _G.LexusState.CustomTextData.AimTouchHipFOV = 15
                _G.LexusState.CustomTextData.AimTouchScopeSpeed = 25
                _G.LexusState.CustomTextData.AimTouchScopeFOV = 12
                _G.LexusState.CustomTextData.AimTouchSniperSpeed = 20
                _G.LexusState.CustomTextData.AimTouchSniperFOV = 10
            end
        elseif self.AimMode == "cooldown" then
            _G.LexusConfig.AutoHead = false
            _G.LexusConfig.AimTouchEnable = false
            if _G.LexusState.CustomTextData then
                _G.LexusState.CustomTextData.AimTouchHipSpeed = 15
                _G.LexusState.CustomTextData.AimTouchScopeSpeed = 12
                _G.LexusState.CustomTextData.AimTouchSniperSpeed = 10
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 14] Anti-Replay + Anti-Screenshot
-- ═══════════════════════════════════════════════════════════════════
local function AgAntiReplay()
    pcall(function()
        local smtd = import("ScreenshotMTDer")
        if smtd then
            smtd.MTDePicture = function() return "" end
            smtd.HasCaptured = function() return true end
            smtd.TakeScreenshot = nop
        end
        
        local rs = package.loaded["ReplaySubsystem"]
        if rs then
            for k, v in pairs(rs) do
                if type(v) == "function" and (k:find("Record") or k:find("Capture") or k:find("Save")) then
                    pcall(function() rs[k] = nop end)
                end
            end
        end
        
        for _, cn in ipairs({"CrashSight","Bugly","CrashReporter"}) do
            local c = _G[cn]
            if c then
                c.ReportException = nop
                c.SetCustomData = nop
                c.Log = nop
                c.SendCrash = nop
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 15] Report Shield — حجب بلاغات اللاعبين
-- ═══════════════════════════════════════════════════════════════════
local function AgReportShield()
    pcall(function()
        -- ✅ تم دمج هذا مع AgNetworkShield — لا override إضافي
        
        local reportSystems = {
            "ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
            "PlayerReportSystem","ReportManager","ReportController",
            "ClientReportSystem","DSReportSystem","ReportSubsystem"
        }
        for _, name in ipairs(reportSystems) do
            local sys = _G[name] or package.loaded[name]
            if sys and type(sys) == "table" then
                for k, v in pairs(sys) do
                    if type(v) == "function" and (k:find("Report") or k:find("Submit") or k:find("Send")) then
                        pcall(function() sys[k] = function() return true end end)
                    end
                end
            end
        end
        
        if ui_complaint then
            ui_complaint.SubmitReportData = function(self) 
                if self.CloseWindow then self:CloseWindow(false) end 
                return 
            end
            ui_complaint._OnClickReport = function(self) return end
            ui_complaint.AddPlayerForReport = function(self, ...) return end
        end
        if LogicComplaint then
            LogicComplaint.Submit = function(...) return end
            LogicComplaint.SubmitReport = function(...) return end
            LogicComplaint.SendReport = function(...) return end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PATCH 16] قاتل نوافذ الباند
-- ═══════════════════════════════════════════════════════════════════
local function AgKillBanWindows()
    pcall(function()
        local allW = slua.getUIList() or {}
        local killKw = {
            "Ban","Legal","Notice","Suspension","Frozen","Penalty",
            "Sanction","Terminated","Blocked","Flagged","Violation",
            "Security","AntiCheat","Warning","Alert"
        }
        for _, w in pairs(allW) do
            if slua.isValid(w) then
                local n = w:GetName() or ""
                for _, kw in ipairs(killKw) do
                    if n:find(kw) then
                        pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        pcall(function() w:RemoveFromParent() end)
                        break
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [PAK SHIELD] نظام حماية PAK Hash
-- ═══════════════════════════════════════════════════════════════════
local PakShield = {
    Active = false,
    StartTime = 0,
    HeartbeatRate = 0.6,
    Hooked = {},
    Original = {},
    FakeHashes = {},
    HashRequestsBlocked = 0,
    ServerReportsBlocked = 0,
    ServerRequestsBlocked = 0,
    Cycle = 0
}

local function PakRndHash()
    local chars = "0123456789abcdef"
    local s = {}
    for i = 1, 40 do
        s[i] = chars:sub(math.random(1, 16), math.random(1, 16))
    end
    return table.concat(s)
end

PakShield.CaptureOriginals = function(self)
    pcall(function()
        local hashFuncs = {
            "GetPakHash", "VerifyPakHash", "CheckPakHash", "PakHash",
            "HashFile", "GetFileHash", "VerifyHash", "ValidateHash",
            "IsHashValid", "GetMD5", "GetSHA1", "GetSHA256", "GetCRC32",
            "ComputePakHash", "CalculatePakHash", "GeneratePakHash"
        }
        for _, fn in ipairs(hashFuncs) do
            if _G[fn] and type(_G[fn]) == "function" then
                self.Original[fn] = _G[fn]
            end
        end
    end)
end

PakShield.DisableHashFunctions = function(self)
    pcall(function()
        local hashFuncs = {
            "GetPakHash", "VerifyPakHash", "CheckPakHash", "PakHash",
            "HashFile", "GetFileHash", "VerifyHash", "ValidateHash",
            "IsHashValid", "GetMD5", "GetSHA1", "GetSHA256", "GetCRC32",
            "ComputePakHash", "CalculatePakHash", "GeneratePakHash",
            "CheckFileHash", "VerifyFileHash", "CompareHash",
            "IsHashEqual", "CheckHashMatch", "ValidateHashMatch"
        }
        
        for _, fn in ipairs(hashFuncs) do
            if _G[fn] then
                self.Original[fn] = self.Original[fn] or _G[fn]
                _G[fn] = function(...)
                    return PakRndHash()
                end
            end
        end
    end)
end

PakShield.HookPakSystems = function(self)
    pcall(function()
        local PakManager = import("PakManager")
        if PakManager then
            self.Original["PakManager.GetPakHash"] = PakManager.GetPakHash
            self.Original["PakManager.VerifyPakHash"] = PakManager.VerifyPakHash
            
            PakManager.GetPakHash = function() return PakRndHash() end
            PakManager.VerifyPakHash = function() return true end
            PakManager.CheckPakHash = function() return true end
            PakManager.ValidatePak = function() return true end
            PakManager.IsPakValid = function() return true end
            PakManager.VerifyIntegrity = function() return true end
            PakManager.CheckIntegrity = function() return true end
        end
        
        local PakLoader = import("PakLoader")
        if PakLoader then
            PakLoader.VerifyPak = function() return true end
            PakLoader.VerifyHash = function() return true end
            PakLoader.CheckIntegrity = function() return true end
            PakLoader.VerifyPakFile = function() return true end
            PakLoader.ValidateHash = function() return true end
            PakLoader.VerifySignature = function() return true end
        end
        
        if _G.PakFileSystem then
            _G.PakFileSystem.VerifyFile = function() return true end
            _G.PakFileSystem.CheckIntegrity = function() return true end
            _G.PakFileSystem.GetFileHash = function() return PakRndHash() end
            _G.PakFileSystem.ValidatePak = function() return true end
            _G.PakFileSystem.IsPakValid = function() return true end
        end
        
        if _G.FileManager then
            _G.FileManager.VerifyFile = function() return true end
            _G.FileManager.CheckFileIntegrity = function() return true end
            _G.FileManager.GetFileHash = function() return PakRndHash() end
            _G.FileManager.ValidateFile = function() return true end
        end
        
        local KSL = import("KismetSystemLibrary")
        if KSL then
            KSL.VerifyPakHash = function() return true end
            KSL.CheckPakIntegrity = function() return true end
            KSL.GetPakHash = function() return PakRndHash() end
        end
    end)
end

PakShield.HookCreativeMode = function(self)
    pcall(function()
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            local FIXED_HASH = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
            
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.SHA1HashFile = function() return FIXED_HASH end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = function() return true end
            CMode.ComputeHash = function() return FIXED_HASH end
            CMode.CalculateFileHash = function() return FIXED_HASH end
            CMode.VerifyPak = function() return true end
        end
    end)
end

PakShield.BlockServerRequests = function(self)
    pcall(function()
        -- ✅ لا نستبدل RecvPacket — فقط نضيف على SendPacket الموجود
        if _G.RecvRPC and not self.Hooked["RecvRPC"] then
            local origRecvRPC = _G.RecvRPC
            self.Original["RecvRPC"] = origRecvRPC
            _G.RecvRPC = function(rpcName, ...)
                local name = tostring(rpcName):lower()
                if name:find("requestpak") or name:find("requesthash") or
                   name:find("reqverify") or name:find("reqintegrity") or
                   name:find("askhash") or name:find("querypak") or
                   name:find("serverpakcheck") or name:find("serverhash") or
                   name:find("integritycheck") then
                    self.ServerRequestsBlocked = self.ServerRequestsBlocked + 1
                    return nil
                end
                return origRecvRPC(rpcName, ...)
            end
            self.Hooked["RecvRPC"] = true
        end
    end)
end

PakShield.SpoofServerHandshake = function(self)
    pcall(function()
        local integrityModules = {
            "client.slua.logic.report.EquipmentExceptionReport",
            "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils",
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"
        }
        
        for _, path in ipairs(integrityModules) do
            local mod = package.loaded[path]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and 
                       (k:find("Hash") or k:find("Verify") or k:find("Check")) then
                        mod[k] = function() return true end
                    end
                end
            end
        end
    end)
end

PakShield.EngineLevelDisable = function(self)
    pcall(function()
        if _G.FPakEntry then
            _G.FPakEntry.VerifyHash = function() return true end
        end
        if _G.FPakFile then
            _G.FPakFile.CheckIntegrity = function() return true end
        end
        if _G.IPakFile then
            _G.IPakFile.Verify = function() return true end
        end
        if _G.FPakReader then
            _G.FPakReader.Validate = function() return true end
        end
    end)
end

PakShield.Heartbeat = function(self)
    pcall(function()
        self.Cycle = self.Cycle + 1
        
        self:DisableHashFunctions()
        
        if self.Cycle % 3 == 0 then
            self:HookPakSystems()
            self:HookCreativeMode()
        end
        
        if self.Cycle % 5 == 0 then
            self:SpoofServerHandshake()
            self:BlockServerRequests()
            self:EngineLevelDisable()
        end
    end)
end

PakShield.Activate = function(self)
    if self.Active or _G._PakShieldActive then return end
    _G._PakShieldActive = true
    self.Active = true
    self.StartTime = os.time()
    
    self:CaptureOriginals()
    self:DisableHashFunctions()
    self:HookPakSystems()
    self:HookCreativeMode()
    self:SpoofServerHandshake()
    self:BlockServerRequests()
    self:EngineLevelDisable()
    
    for i = 1, 50 do
        self.FakeHashes[i] = PakRndHash()
    end
    
    local function loop()
        if not self.Active then return end
        self:Heartbeat()
        local ok, ticker = pcall(require, "common.time_ticker")
        if ok and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(self.HeartbeatRate, loop)
        end
    end
    loop()
end

-- ═══════════════════════════════════════════════════════════════════
-- [النبض الرئيسي] Heartbeat
-- ═══════════════════════════════════════════════════════════════════
Aegis.Heartbeat = function(self)
    pcall(function()
        self.Cycle = self.Cycle + 1
        
        AgNeutralizeBan()
        AgDestroyTelemetry(self)
        AgAntiReplay()
        AgReportShield()
        
        if self.Cycle % 3 == 0 then
            AgKillDetectors(self)
        end
        
        if self.Cycle % 4 == 0 then
            AgThreatScan(self)
            AgSmartRageControl(self)
        end
        
        if self.Cycle % 6 == 0 then
            AgKillBanWindows()
        end
        
        if self.Cycle % 100 == 0 then
            AgSpoofIdentity(self)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- [التشغيل]
-- ═══════════════════════════════════════════════════════════════════
Aegis.Activate = function(self)
    if self.Active or _G._AegisActive then return end
    _G._AegisActive = true
    self.Active = true
    self.StartTime = os.time()
    
    AgFixFiles()
    AgBuildTables(self)
    AgNeutralizeBan()
    AgNetworkShield(self)
    AgSSLBypass()
    AgMemoryShield()
    AgSpoofIdentity(self)
    AgDestroyTelemetry(self)
    AgAntiReplay()
    AgReportShield()
    AgKillDetectors(self)
    AgKillBanWindows()
    
    local function loop()
        if not self.Active then return end
        self:Heartbeat()
        local ok, ticker = pcall(require, "common.time_ticker")
        if ok and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(self.HeartbeatRate, loop)
        end
    end
    loop()
end

Aegis.OnKill = function(self, isHeadshot)
    self.Kills = self.Kills + 1
    self.LastKillTime = os.time()
    if isHeadshot then self.Headshots = self.Headshots + 1 end
    table.insert(self.KillTimestamps, os.time())
    if #self.KillTimestamps > 30 then table.remove(self.KillTimestamps, 1) end
end

pcall(function() Aegis:Activate() end)
pcall(function() PakShield:Activate() end)

_G.Aegis = Aegis
_G.PakShield = PakShield
_G.AEGIS_LOADED = true
_G.PAK_SHIELD_LOADED = true
_G.AEGIS_FORTRESS = true
