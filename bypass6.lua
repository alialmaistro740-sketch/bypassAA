-- ======================= ULTIMATE WH BYPASS =========================
local function isBypassActive()
    return not _G._MOD_EXPIRED
end

local function isWHBypassActive()
    return _G._WHA_BYPASS_ACTIVE or false
end

function InstallWallhackBypass()
    if _G.__ULTIMATE_WH_BYPASS_LOADED then return end

    local function dummy() end
    local function trueFunc() return true end
    local function falseFunc() return false end
    local function zeroFunc() return 0 end

    -- Hook PrimitiveSceneProxy
    pcall(function()
        local PrimitiveSceneProxy = import("PrimitiveSceneProxy")
        if PrimitiveSceneProxy then
            local origGetViewRelevance = PrimitiveSceneProxy.GetViewRelevance
            PrimitiveSceneProxy.GetViewRelevance = function(self, view)
                if isBypassActive() and origGetViewRelevance(self, view) then
                    view.bRenderCustomDepth = false
                    view.bUsesSceneDepth = false
                end
                return view
            end

            local origGetDepthPriorityGroup = PrimitiveSceneProxy.GetDepthPriorityGroup
            PrimitiveSceneProxy.GetDepthPriorityGroup = function(self)
                if not isBypassActive() then
                    return origGetDepthPriorityGroup(self)
                end
                return 0
            end
        end
    end)

    -- Hook MeshComponent
    pcall(function()
        local MeshComponent = import("MeshComponent")
        if MeshComponent then
            MeshComponent.__origGRCD = MeshComponent.GetRenderCustomDepth
            MeshComponent.GetRenderCustomDepth = function(self)
                if not isBypassActive() then return MeshComponent.__origGRCD(self) end
                return false
            end

            MeshComponent.__origIRCD = MeshComponent.IsRenderedOnCustomDepth
            MeshComponent.IsRenderedOnCustomDepth = function(self)
                if not isBypassActive() then return MeshComponent.__origIRCD(self) end
                return false
            end

            MeshComponent.__origGCDSV = MeshComponent.GetCustomDepthStencilValue
            MeshComponent.GetCustomDepthStencilValue = function(self)
                if not isBypassActive() then return MeshComponent.__origGCDSV(self) end
                return 0
            end

            MeshComponent.__origSR = MeshComponent.ShouldRender
            MeshComponent.ShouldRender = function(self)
                if not isBypassActive() then return MeshComponent.__origSR(self) end
                return true
            end

            MeshComponent.__origIV = MeshComponent.IsVisible
            MeshComponent.IsVisible = function(self)
                if not isBypassActive() then return MeshComponent.__origIV(self) end
                return true
            end
        end
    end)

    -- Hook RHICommandList (depth state)
    pcall(function()
        local RHICommandList = import("RHICommandList")
        if RHICommandList and RHICommandList.SetDepthState then
            local origSetDepthState = RHICommandList.SetDepthState
            RHICommandList.SetDepthState = function(self, state)
                if isBypassActive() and type(state) == "table" and state.DepthEnable ~= nil then
                    state.DepthEnable = true
                end
                return origSetDepthState(self, state)
            end
        end
    end)

    -- Hook GameViewportClient to draw overlay
    pcall(function()
        local GameViewportClient = import("GameViewportClient")
        if GameViewportClient and GameViewportClient.Draw then
            local origDraw = GameViewportClient.Draw
            GameViewportClient.Draw = function(self, ...)
                origDraw(self, ...)
                if isBypassActive() and _G.AK_DrawWallhackOverlay then
                    pcall(_G.AK_DrawWallhackOverlay)
                end
            end
        end
    end)

    -- Hook Material & MaterialInstance
    pcall(function()
        local Material = import("Material")
        if Material then
            Material.__origDDT = Material.GetDisableDepthTest
            Material.GetDisableDepthTest = function(self)
                if not isBypassActive() then return Material.__origDDT(self) end
                return false
            end
            Material.__origBM = Material.GetBlendMode
            Material.GetBlendMode = function(self)
                if not isBypassActive() then return Material.__origBM(self) end
                return 0
            end
            Material.__origHash = Material.GetMaterialHash
            Material.GetMaterialHash = function(self)
                if not isBypassActive() then return Material.__origHash(self) end
                return "FAKE_HASH"
            end
            Material.__origVM = Material.VerifyMaterial
            Material.VerifyMaterial = function(self)
                if not isBypassActive() then return Material.__origVM(self) end
                return true
            end
        end

        local MaterialInstance = import("MaterialInstance")
        if MaterialInstance then
            MaterialInstance.__origDDT = MaterialInstance.GetDisableDepthTest
            MaterialInstance.GetDisableDepthTest = function(self)
                if not isBypassActive() then return MaterialInstance.__origDDT(self) end
                return false
            end
            MaterialInstance.__origBM = MaterialInstance.GetBlendMode
            MaterialInstance.GetBlendMode = function(self)
                if not isBypassActive() then return MaterialInstance.__origBM(self) end
                return 0
            end
            MaterialInstance.__origBM2 = MaterialInstance.GetBaseMaterial
            MaterialInstance.GetBaseMaterial = function(self)
                if not isBypassActive() then return MaterialInstance.__origBM2(self) end
                return nil
            end
        end

        local MaterialInstanceDynamic = import("MaterialInstanceDynamic")
        if MaterialInstanceDynamic then
            local origVec = MaterialInstanceDynamic.K2_GetVectorParameterValue
            MaterialInstanceDynamic.K2_GetVectorParameterValue = function(self, param)
                if not isBypassActive() then return origVec(self, param) end
                local p = tostring(param)
                if p:find("Color") or p:find("Emissive") or p:find("Tint") then
                    return {R=255, G=255, B=255, A=255}
                end
                return origVec(self, param)
            end

            local origScalar = MaterialInstanceDynamic.K2_GetScalarParameterValue
            MaterialInstanceDynamic.K2_GetScalarParameterValue = function(self, param)
                if not isBypassActive() then return origScalar(self, param) end
                if tostring(param):find("Emissive") then
                    return 0.0
                end
                return origScalar(self, param)
            end
        end
    end)

    -- Hook Object:GetObjectsOfClass to hide MaterialInstanceDynamic
    pcall(function()
        local Object = import("Object")
        if Object and Object.GetObjectsOfClass then
            local origGetObjects = Object.GetObjectsOfClass
            Object.GetObjectsOfClass = function(cls, ...)
                if isBypassActive() and cls and tostring(cls):find("MaterialInstanceDynamic") then
                    return {}
                end
                return origGetObjects(cls, ...)
            end
        end
    end)

    -- Hook Subsystems: ClientKernelCheckSubsystem
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local kernelCheck = SubsystemMgr:Get("ClientKernelCheckSubsystem")
            if kernelCheck and not kernelCheck.__akhooked then
                kernelCheck.__origIsKernelClean = kernelCheck.IsKernelClean
                kernelCheck.IsKernelClean = function(self)
                    if not isBypassActive() then return kernelCheck.__origIsKernelClean(self) end
                    return true, {code = 0, message = "clean"}
                end
                kernelCheck.__origGetKernelVersion = kernelCheck.GetKernelVersion
                kernelCheck.GetKernelVersion = function(self)
                    if not isBypassActive() then return kernelCheck.__origGetKernelVersion(self) end
                    return "5.4.0-generic"
                end
                kernelCheck.__akhooked = true
            end

            local memGuard = SubsystemMgr:Get("ClientMemoryGuardSubsystem")
            if memGuard and not memGuard.__akhooked then
                memGuard.__origIsMemoryClean = memGuard.IsMemoryClean
                memGuard.IsMemoryClean = function(self)
                    if not isBypassActive() then return memGuard.__origIsMemoryClean(self) end
                    return true, {code = 0}
                end
                memGuard.__origScanResult = memGuard.ScanResult
                memGuard.ScanResult = function(self)
                    if not isBypassActive() then return memGuard.__origScanResult(self) end
                    return "clean"
                end
                memGuard.__akhooked = true
            end
        end
    end)

    -- Hook ScreenMarkManager for ESP
    local hiddenMarkGroups = {1006, 9999}
    pcall(function()
        if ScreenMarkManager and ScreenMarkManager.ScreenMarkManager then
            local mgr = ScreenMarkManager.ScreenMarkManager
            if mgr.GetAllActiveMarks then
                local origGetAll = mgr.GetAllActiveMarks
                mgr.GetAllActiveMarks = function(self, ...)
                    local marks = origGetAll(self, ...)
                    if not isBypassActive() or not marks then return marks end
                    local filtered = {}
                    for _, mark in ipairs(marks) do
                        if mark.MarkGroupID and not table.contains(hiddenMarkGroups, mark.MarkGroupID) then
                            table.insert(filtered, mark)
                        end
                    end
                    return filtered
                end
            end
            if mgr.GetMarkCount then
                local origCount = mgr.GetMarkCount
                mgr.GetMarkCount = function(self, ...)
                    if isBypassActive() then
                        return math.max(0, origCount(self, ...) - #hiddenMarkGroups)
                    end
                    return origCount(self, ...)
                end
            end
            if mgr.GetMarksByGroup then
                local origGetByGroup = mgr.GetMarksByGroup
                mgr.GetMarksByGroup = function(self, groupId)
                    if isBypassActive() and table.contains(hiddenMarkGroups, groupId) then
                        return {}
                    end
                    return origGetByGroup(self, groupId)
                end
            end
            -- Disable add/remove marks
            mgr.OnAddMark = dummy
            mgr.OnRemoveMark = dummy
        end
    end)

    -- Hook replay functions
    pcall(function()
        if _G.Replay_IsEnemyFrameUIExisted then
            local orig = _G.Replay_IsEnemyFrameUIExisted
            _G.Replay_IsEnemyFrameUIExisted = function(...)
                if isBypassActive() then return false end
                return orig(...)
            end
        end
        if _G.Replay_CreateEnemyFrameUI then
            local orig = _G.Replay_CreateEnemyFrameUI
            _G.Replay_CreateEnemyFrameUI = function(...)
                if isBypassActive() then
                    _G.ReportEnemyFrameUI = dummy
                    return
                end
                return orig(...)
            end
        end
    end)

    -- Hook Actor meta to block ESP-related properties
    pcall(function()
        local Actor = import("Actor")
        if Actor then
            local mt = getmetatable(Actor) or {}
            local oldIndex = mt.__index
            mt.__index = function(self, key)
                if isBypassActive() then
                    local k = tostring(key)
                    if k:find("ESP") or k:find("bHasAKNative") or k:find("NativeDistMark") or k:find("_wh_") or k:find("WH_") then
                        return nil
                    end
                end
                return oldIndex and oldIndex(self, key)
            end
            setmetatable(Actor, mt)
        end
    end)

    -- Block UIHelper / UserWidget
    pcall(function()
        if _G.UIHelper and _G.UIHelper.GetAllWidgetsOfClass then
            _G.UIHelper.GetAllWidgetsOfClass = function(...) return {} end
        end
        local UserWidget = import("UserWidget")
        if UserWidget and UserWidget.AddToViewport then
            local origAdd = UserWidget.AddToViewport
            UserWidget.AddToViewport = function(self, ...)
                if isBypassActive() and self.ESPWidget then
                    return
                end
                return origAdd(self, ...)
            end
        end
    end)

    -- Block all ESP-related report functions
    local reportFuncs = {
        "ReportESPBox", "ReportESPHealth", "ReportMiniMapESP", "ReportEnemyFrameUI",
        "ReportMarkCreated", "ReportMarkDestroyed", "MarkSuspiciousESP",
        "OnScreenMarkAdd", "OnScreenMarkRemove", "ReportDistanceMarker",
        "ReportWallhackESP", "SendESPData", "UploadESPInfo"
    }
    pcall(function()
        for _, name in ipairs(reportFuncs) do
            if _G[name] then _G[name] = dummy end
            for _, mod in pairs(package.loaded) do
                if type(mod) == "table" and mod[name] then
                    mod[name] = dummy
                end
            end
        end
    end)

    -- Hook NetUtil and SendRPC
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packet, ...)
                if isBypassActive() and packet and tostring(packet):lower():match("esp") then
                    return nil
                end
                return origSend(packet, ...)
            end
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            _G.SendRPC = function(rpc, ...)
                if isBypassActive() and rpc and tostring(rpc):lower():match("esp") then
                    return
                end
                return origRPC(rpc, ...)
            end
        end
    end)

    _G.__ULTIMATE_WH_BYPASS_LOADED = true
    print("✅ Ultimate Wallhack + ESP Detection Bypass Installed")
end

-- ======================= AIMBOT BYPASS =============================
function InstallAimbotBypass()
    if _G.__AIMBOT_BYPASS_LOADED then return end

    local function dummy() end
    local function trueFunc() return true end
    local function falseFunc() return false end
    local function zeroFunc() return 0 end

    -- Hook ShootWeaponEntity
    pcall(function()
        local ShootWeaponEntity = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if ShootWeaponEntity then
            local mt = getmetatable(ShootWeaponEntity) or {}
            local oldIndex = mt.__index
            mt.__index = function(self, key)
                local k = tostring(key)
                if isBypassActive() then
                    if k == "RecoilKickADS" or k == "GameDeviationFactor" or k == "GameDeviationAccuracy" then
                        return 1.0
                    elseif k == "AutoAimingConfig" then
                        local config = oldIndex and oldIndex(self, key)
                        if type(config) == "table" then
                            local newConfig = {}
                            for k2, v2 in pairs(config) do
                                if type(v2) == "number" then
                                    newConfig[k2] = 1.0
                                else
                                    newConfig[k2] = v2
                                end
                            end
                            return newConfig
                        end
                        return config
                    end
                end
                return oldIndex and oldIndex(self, key)
            end
            mt.__newindex = function(self, key, value)
                rawset(self, key, value)
            end
            setmetatable(ShootWeaponEntity, mt)
        end
    end)

    -- Hook ClientAimTrackingSubsystem
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local aimTrack = SubsystemMgr:Get("ClientAimTrackingSubsystem")
            if aimTrack then
                aimTrack.__origGetAimData = aimTrack.GetAimData
                aimTrack.GetAimData = function(self)
                    if not isBypassActive() then return aimTrack.__origGetAimData(self) end
                    return {accuracy = math.random(40, 60), headshotRate = math.random(10, 25), trackingTime = math.random(100, 300), aimLockCount = 0}
                end
                -- Disable report functions
                for _, name in ipairs({"ReportAimData", "SendAimStats", "UploadAimInfo"}) do
                    if aimTrack[name] then aimTrack[name] = dummy end
                end
            end
        end
    end)

    -- Hook PlayerController input
    pcall(function()
        local PlayerController = import("PlayerController")
        if PlayerController then
            local origAddYaw = PlayerController.AddYawInput
            PlayerController.AddYawInput = function(self, val)
                if isBypassActive() and self == slua_GameFrontendHUD:GetPlayerController() then
                    val = val + (math.random() - 0.5) * 0.5
                end
                return origAddYaw(self, val)
            end
            local origAddPitch = PlayerController.AddPitchInput
            PlayerController.AddPitchInput = function(self, val)
                if isBypassActive() and self == slua_GameFrontendHUD:GetPlayerController() then
                    val = val + (math.random() - 0.5) * 0.5
                end
                return origAddPitch(self, val)
            end

            if GameplayStatics and GameplayStatics.IsInputKeyDown then
                local origIsDown = GameplayStatics.IsInputKeyDown
                GameplayStatics.IsInputKeyDown = function(controller, key)
                    if isBypassActive() and key == "LeftMouseButton" and math.random() < 0.1 then
                        return false
                    end
                    return origIsDown(controller, key)
                end
            end
        end
    end)

    -- Hook ShootVerifySubSystemClient
    pcall(function()
        local ShootVerify = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if ShootVerify and ShootVerify.VerifyShot then
            local origVerify = ShootVerify.VerifyShot
            ShootVerify.VerifyShot = function(self, ...)
                if not isBypassActive() then return origVerify(self, ...) end
                local args = {...}
                if args[1] and type(args[1]) == "table" and args[1].hitLocation then
                    args[1].hitLocation.X = args[1].hitLocation.X + (math.random() - 0.5) * 2
                    args[1].hitLocation.Y = args[1].hitLocation.Y + (math.random() - 0.5) * 2
                end
                return true
            end
        end
    end)

    -- Hook Actor:GetBoneName to favour neck shots
    pcall(function()
        local Actor = import("Actor")
        if Actor and Actor.GetBoneName then
            local origGetBone = Actor.GetBoneName
            Actor.GetBoneName = function(self, boneIndex)
                local name = origGetBone(self, boneIndex)
                if isBypassActive() and tostring(name):find("neck") then
                    local r = math.random(1,3)
                    if r == 1 then return "head_01"
                    elseif r == 2 then return "spine_02"
                    end
                end
                return name
            end
        end
    end)

    -- Block aim-related report functions
    local aimFuncs = {
        "ReportAimFlow", "ReportRecoil", "ReportAimData", "SendAimStats",
        "UploadAimInfo", "ReportHeadshotRate", "ReportAccuracy", "ReportFireRate",
        "ReportRecoilKick", "ReportAutoAim", "ReportWeaponModification",
        "ReportWeaponStats", "ReportShootVerifyFail", "ReportHitIntegrity",
        "OnAimAssistDetected", "OnRecoilAnomaly", "OnFireRateAnomaly",
        "ClientAimTrackingUpdate", "ServerAimValidation"
    }
    pcall(function()
        for _, name in ipairs(aimFuncs) do
            if _G[name] then _G[name] = dummy end
            for _, mod in pairs(package.loaded) do
                if type(mod) == "table" and mod[name] then
                    mod[name] = dummy
                end
            end
        end
    end)

    -- Hook NetUtil and SendRPC for aim keywords
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packet, ...)
                if isBypassActive() and packet and (tostring(packet):lower():match("aim") or tostring(packet):lower():match("recoil") or tostring(packet):lower():match("shoot")) then
                    return nil
                end
                return origSend(packet, ...)
            end
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            _G.SendRPC = function(rpc, ...)
                if isBypassActive() and rpc and (tostring(rpc):lower():match("aim") or tostring(rpc):lower():match("recoil") or tostring(rpc):lower():match("shoot")) then
                    return
                end
                return origRPC(rpc, ...)
            end
        end
    end)

    _G.__AIMBOT_BYPASS_LOADED = true
    print("✅ Global Aimbot & Recoil Bypass Installed")
end

-- ======================= ADVANCED BYPASS ===========================
function InstallAdvancedBypass()
    if _G.__ADVANCED_BYPASS_LOADED then return end

    local function dummy() end
    local function trueFunc() return true end
    local function falseFunc() return false end
    local function zeroFunc() return 0 end
    local function emptyTable() return {} end

    -- Hook ShootWeaponEntity: Fire
    pcall(function()
        local ShootWeaponEntity = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if ShootWeaponEntity and ShootWeaponEntity.Fire then
            local origFire = ShootWeaponEntity.Fire
            ShootWeaponEntity.Fire = function(self, ...)
                if isBypassActive() then
                    -- Add random modifications if needed
                end
                return origFire(self, ...)
            end
        end
    end)

    -- Hook Actor:TakeDamage to randomize hit location
    pcall(function()
        local Actor = import("Actor")
        if Actor and Actor.TakeDamage then
            local origTakeDamage = Actor.TakeDamage
            Actor.TakeDamage = function(self, damage, damageEvent, controller, instigator)
                if isBypassActive() and controller and controller.HitInfo then
                    local hit = controller.HitInfo
                    if hit.BoneName and tostring(hit.BoneName):find("head") and math.random() < 0.3 then
                        hit.BoneName = "neck_01"
                    end
                    hit.Location.X = hit.Location.X + (math.random() - 0.5) * 2
                    hit.Location.Y = hit.Location.Y + (math.random() - 0.5) * 2
                    hit.Location.Z = hit.Location.Z + (math.random() - 0.5) * 2
                end
                return origTakeDamage(self, damage, damageEvent, controller, instigator)
            end
        end
    end)

    -- Block position-related packets
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packet, ...)
                if isBypassActive() and packet and tostring(packet):lower():match("position") or tostring(packet):lower():match("location") or tostring(packet):lower():match("coord") then
                    return nil
                end
                return origSend(packet, ...)
            end
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            _G.SendRPC = function(rpc, ...)
                if isBypassActive() and rpc and (tostring(rpc):lower():match("position") or tostring(rpc):lower():match("location") or tostring(rpc):lower():match("coord")) then
                    return
                end
                return origRPC(rpc, ...)
            end
        end
    end)

    -- Stats collection (for accuracy spoofing)
    local stats = {totalShots = 0, totalHits = 0, headshots = 0, kills = 0}

    pcall(function()
        -- Hook Fire to count shots
        local ShootWeaponEntity = import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if ShootWeaponEntity and ShootWeaponEntity.Fire then
            local origFire = ShootWeaponEntity.Fire
            ShootWeaponEntity.Fire = function(self, ...)
                if isBypassActive() then
                    stats.totalShots = stats.totalShots + 1
                end
                return origFire(self, ...)
            end
        end

        -- Hook TakeDamage to count hits/kills
        local Actor = import("Actor")
        if Actor and Actor.TakeDamage then
            local origTakeDamage = Actor.TakeDamage
            Actor.TakeDamage = function(self, damage, damageEvent, controller, instigator)
                if isBypassActive() and instigator == slua_GameFrontendHUD:GetPlayerController() then
                    stats.totalHits = stats.totalHits + 1
                    if damageEvent and damageEvent.HitInfo and damageEvent.HitInfo.BoneName and tostring(damageEvent.HitInfo.BoneName):find("head") then
                        stats.headshots = stats.headshots + 1
                    end
                    if self:IsDead() then
                        stats.kills = stats.kills + 1
                    end
                end
                return origTakeDamage(self, damage, damageEvent, controller, instigator)
            end
        end
    end)

    -- Hook GameReportUtils to spoof accuracy
    pcall(function()
        local GameReportUtils = require("GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils")
        if GameReportUtils and GameReportUtils.ReportGameResult then
            local origReport = GameReportUtils.ReportGameResult
            GameReportUtils.ReportGameResult = function(self, data)
                if isBypassActive() and data then
                    data.accuracy = math.min(0.65, 0.35 + math.random() * 0.15)
                    data.headshotRate = math.min(0.3, 0.1 + math.random() * 0.1)
                    data.totalShots = math.max(stats.totalShots, 1)
                    data.totalKills = stats.kills
                    data.totalHits = math.floor(data.totalShots * data.accuracy)
                end
                return origReport(self, data)
            end
        end

        local BattleResultShowResultLogic = require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic")
        if BattleResultShowResultLogic and BattleResultShowResultLogic.ReceiveData then
            local origReceive = BattleResultShowResultLogic.ReceiveData
            BattleResultShowResultLogic.ReceiveData = function(self, data)
                if isBypassActive() and data then
                    data.Accuracy = math.random(35,50) / 100
                    data.HeadShotRate = math.random(10,20) / 100
                end
                return origReceive(self, data)
            end
        end
    end)

    -- Hook debugger detection
    pcall(function()
        if rawget(_G, "IsDebuggerPresent") then _G.IsDebuggerPresent = falseFunc end
        local Kernel32 = import("Kernel32")
        if Kernel32 then
            Kernel32.IsDebuggerPresent = falseFunc
            Kernel32.CheckRemoteDebuggerPresent = falseFunc
        end
    end)

    -- TssSdk hooks
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.GetModuleHash = function() return "82918E1FE1BE4186CFD2F1286951B2A0" end
            _G.TssSdk.VerifyModule = trueFunc
            _G.TssSdk.ScanProcess = emptyTable
        end
    end)

    -- Hook FMemory::Memcpy
    pcall(function()
        local FMemory = import("FMemory")
        if FMemory and FMemory.Memcpy then
            local origMemcpy = FMemory.Memcpy
            FMemory.Memcpy = function(dest, src, size)
                if isBypassActive() then return end
                return origMemcpy(dest, src, size)
            end
        end
    end)

    -- Hook Pak file functions
    pcall(function()
        local FFileHelper = import("FFileHelper")
        if FFileHelper then
            if FFileHelper.GetFileSize then
                local origGetSize = FFileHelper.GetFileSize
                FFileHelper.GetFileSize = function(filename)
                    local size = origGetSize(filename)
                    if isBypassActive() and filename and tostring(filename):lower():match(".pak") then
                        return 2000000000
                    end
                    return size
                end
            end
            if FFileHelper.SaveStringToFile then
                local origSave = FFileHelper.SaveStringToFile
                FFileHelper.SaveStringToFile = function(str, filename, ...)
                    if isBypassActive() and filename and tostring(filename):lower():match(".pak") then
                        return true
                    end
                    return origSave(str, filename, ...)
                end
            end
        end

        local PakFileSubsystem = require("GameLua.GameCore.Module.Subsystem.PakFileSubsystem")
        if PakFileSubsystem then
            PakFileSubsystem.CheckPakIntegrity = dummy
            PakFileSubsystem.ReportPakMismatch = dummy
        end
    end)

    -- Speed hack: override max speed and acceleration
    pcall(function()
        local CharacterMovement = import("CharacterMovementComponent")
        if CharacterMovement then
            local origMaxSpeed = CharacterMovement.GetMaxSpeed
            CharacterMovement.GetMaxSpeed = function(self)
                local speed = origMaxSpeed(self)
                if isBypassActive() then
                    return 600.0
                end
                return speed
            end
            local origMaxAccel = CharacterMovement.GetMaxAcceleration
            CharacterMovement.GetMaxAcceleration = function(self)
                local accel = origMaxAccel(self)
                if isBypassActive() then
                    return 2048.0
                end
                return accel
            end
        end
    end)

    -- Block material shader maps
    pcall(function()
        local Material = import("Material")
        if Material then
            Material.GetShaderMap = function() return nil end
            Material.GetShaderPlatform = function() return 0 end
        end
        local MaterialInstance = import("MaterialInstance")
        if MaterialInstance then
            MaterialInstance.GetShaderMap = function() return nil end
        end
        local FPakFile = import("FPakFile")
        if FPakFile and FPakFile.GetPakEntries then
            FPakFile.GetPakEntries = function(...) return {} end
        end
        local FPakPlatformFile = import("FPakPlatformFile")
        if FPakPlatformFile then
            FPakPlatformFile.GetPakFolders = function(...) return {} end
            FPakPlatformFile.FindFileInPakFiles = function(...) return false end
        end
    end)

    -- Block screenshots
    pcall(function()
        local ScreenshotManager = import("ScreenshotManager")
        if ScreenshotManager then
            ScreenshotManager.RequestScreenshot = function(...) return false end
            ScreenshotManager.HasPendingScreenshot = function(...) return false end
        end
    end)

    _G.__ADVANCED_BYPASS_LOADED = true
    print("✅ Advanced Detection Bypass Installed")
end

-- ======================= DEVICE BAN BYPASS =========================
function InstallDeviceBanBypass()
    if _G.__DEVICE_BAN_BYPASS_LOADED then return end

    local function randomHexString(length)
        local chars = "0123456789ABCDEF"
        local result = ""
        for i = 1, length do
            result = result .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        return result
    end

    local deviceID = randomHexString(32)
    local androidID = randomHexString(16)
    local macAddress = string.format("%02X:%02X:%02X:%02X:%02X:%02X",
        math.random(0,255), math.random(0,255), math.random(0,255),
        math.random(0,255), math.random(0,255), math.random(0,255))
    local imei = "35" .. math.random(100000, 999999) .. math.random(100000, 999999)

    pcall(function()
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            local origGetDeviceID = SystemInfo.GetDeviceID
            SystemInfo.GetDeviceID = function()
                if isBypassActive() then return deviceID end
                return origGetDeviceID()
            end
            local origGetUniqueDeviceId = SystemInfo.GetUniqueDeviceId
            SystemInfo.GetUniqueDeviceId = function()
                if isBypassActive() then return deviceID end
                return origGetUniqueDeviceId()
            end
            local origGetMacAddress = SystemInfo.GetMacAddress
            SystemInfo.GetMacAddress = function()
                if isBypassActive() then return macAddress end
                return origGetMacAddress()
            end
            local origGetAndroidId = SystemInfo.GetAndroidId
            SystemInfo.GetAndroidId = function()
                if isBypassActive() then return androidID end
                return origGetAndroidId()
            end
            local origGetIMEI = SystemInfo.GetIMEI
            SystemInfo.GetIMEI = function()
                if isBypassActive() then return imei end
                return origGetIMEI()
            end
            local origGetDeviceName = SystemInfo.GetDeviceName
            SystemInfo.GetDeviceName = function()
                if isBypassActive() then return "Galaxy S21 Ultra 5G" end
                return origGetDeviceName()
            end
        end
    end)

    -- Hook Build class
    pcall(function()
        local Build = import("Build")
        if Build then
            local props = {"Fingerprint","Serial","Hardware","Brand","Model","Manufacturer","Product","Device","Board"}
            for _, prop in ipairs(props) do
                if Build[prop] then
                    local orig = Build[prop]
                    Build[prop] = function()
                        if isBypassActive() then
                            if prop == "Fingerprint" then
                                return "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys"
                            elseif prop == "Serial" then
                                return "R5CT1234567"
                            elseif prop == "Hardware" then
                                return "oriole"
                            elseif prop == "Brand" then
                                return "google"
                            elseif prop == "Model" then
                                return "Pixel 6"
                            elseif prop == "Manufacturer" then
                                return "Google"
                            elseif prop == "Product" then
                                return "oriole"
                            elseif prop == "Device" then
                                return "oriole"
                            elseif prop == "Board" then
                                return "gs101"
                            end
                        end
                        return orig()
                    end
                end
            end
            if Build.VERSION and Build.VERSION.SDK_INT then
                local origSDK = Build.VERSION.SDK_INT
                Build.VERSION.SDK_INT = function()
                    if isBypassActive() then return 33 end
                    return origSDK()
                end
            end
        end
    end)

    -- Hook TssSdk device info
    pcall(function()
        if _G.TssSdk then
            if _G.TssSdk.GetDeviceInfo then
                local orig = _G.TssSdk.GetDeviceInfo
                _G.TssSdk.GetDeviceInfo = function()
                    if not isBypassActive() then return orig() end
                    return {
                        deviceId = deviceID,
                        androidId = androidID,
                        mac = macAddress,
                        imei = imei,
                        model = "Pixel 6",
                        brand = "google",
                        sdkInt = 33,
                        fingerprint = "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys"
                    }
                end
            end
            if _G.TssSdk.GetFingerprint then
                local orig = _G.TssSdk.GetFingerprint
                _G.TssSdk.GetFingerprint = function()
                    if isBypassActive() then
                        return "google/oriole/oriole:13/TQ1A.221205.011/2022120500:user/release-keys"
                    end
                    return orig()
                end
            end
            if _G.TssSdk.GetClientID then
                local orig = _G.TssSdk.GetClientID
                _G.TssSdk.GetClientID = function()
                    if isBypassActive() then return deviceID end
                    return orig()
                end
            end
        end
    end)

    -- Override global device identifiers
    pcall(function()
        if _G.DeviceID then _G.DeviceID = deviceID end
        if _G.AndroidID then _G.AndroidID = androidID end
        if _G.MacAddress then _G.MacAddress = macAddress end
        if _G.IMEI then _G.IMEI = imei end
    end)

    _G.__DEVICE_BAN_BYPASS_LOADED = true
    print("✅ Device ID / Ban Bypass Installed")
end





-- ======================= BLOCK ALL REPORT FUNCTIONS ================
local blockList = {
    "reportattackflow", "reportsecattackflow", "reporthurtflow", "reportfirearms",
    "reportverifyinfoflow", "reportmrpcsflow", "reportplayerbehavior", "reportteammathurt",
    "reportmisKillbyteammate", "reportforbitpick", "reportplayermoveroute", "reportplayerposition",
    "reportvehiclemoveflow", "reportsecregamemovingflow", "reportparachutedata",
    "sendtsssdkantidatatolobby", "senddserrorlogtolobby", "senddshawkeyepatrollogtolobby",
    "sendsectlog", "senddata miningtlog", "sendactivitytlog", "sendclientmemusage",
    "sendclientfps", "onclientcrashreport", "onnetworklossdetected", "reportmatchroomdata",
    "reportplayersping", "sendclientstats", "sendserveravgtickdelta", "reporthitflow",
    "onplayeractorchannelerror", "onplayerrpcvalidatefailed", "reportequipmentflow",
    "reportaimflow", "getweaponreport", "getoneweaponreport", "reportheavyweaponboxspawnflow",
    "reportheavyweaponboxactivationflow", "reportheavyweaponboxopenplayerflow",
    "reportheavyweaponboxitemflow", "reportplayerip", "reportplayerframepingrecord",
    "ondsconnectionsaturated", "reportdsnetsaturation", "reportnetcontinuoussaturate",
    "reportdsnetrate", "reportcircleflow", "reportdscircleflow", "reportjumpflow",
    "reportaistrategyinfo", "sendaideliveryinfo", "reportdailytaskinfo", "sendplayerspectatinglog",
    "reportidcardproduceflow", "reportidcardpickupflow", "reportidcarddestroyflow",
    "reportrevivalflow", "reportgamesetting", "reportgamesettingnew", "reportantsvoiceteamcreate",
    "reportantsvoiceteamquit", "reportcommoninfo", "reportlightweightstat", "getgeneraltlogdata",
    "reportwallhack", "reportaimbot", "reportspeedhack", "reportmagicbullet",
    "reportplayercontrollerstatechanged", "reportavatarflow", "reportabnormalmaterial",
    "reportdepthtestchange", "reportmemoryexception", "reportmaterialscan", "reportshaderoverride",
    "reportplayerkillflow", "clientsecplayerkillflow", "checkreportsecattackflow",
    "checkreportsecattackflowwithattackflow", "isenablereportplayerkillflow",
    "isenablereportmrpcsincircleflow", "isenablereportmrpcsintpartcircleflow",
    "isenablereportmrpcsflow", "isenablereporthitflow", "isenablereportcircleflow",
    "onplayernetconnectionclosed", "onplayerspectateexception", "onshutdownaftererror",
    "heartbeat", "sendheartbeat", "serverheartbeat", "swifthawk", "clientswifthawk",
    "swifthawkreport", "swifthawkdata", "anticheatreport", "cheatdetection",
    "violationreport", "securityviolation", "integritycheck", "signatureverify",
    "md5", "hash", "filecheck", "pakcheck"
}

function IsBlockedFunction(name)
    for _, keyword in ipairs(blockList) do
        if name:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

-- Patch require to intercept security modules
local securityModules = {
    "AntiCheat", "Integrity", "ReportPlayer", "HawkEye", "SwiftHawk",
    "Ban", "TssSdk", "ShootVerify", "CoronaLab", "HiggsBoson"
}

function IsSecurityModule(name)
    for _, mod in ipairs(securityModules) do
        if name:find(mod, 1, true) then
            return true
        end
    end
    return false
end

local origRequire = require
local blockModules = {
    "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
    "GameLua.Mod.BaseMod.Common.Security.AvatarCheckCallback",
    "GameLua.Mod.BaseMod.Common.Security.GameSafeCallbacks",
}

function _G.require(name)
    if blockModules[name] then
        return {bMHActive = false, BlackList = {}}
    end
    local module = origRequire(name)
    if type(module) == "table" and IsSecurityModule(name) and not module.__ak_sec_patch then
        pcall(function()
            for k, v in pairs(module) do
                if type(v) == "function" then
                    local key = tostring(k):lower():gsub("[^%w]", "")
                    if IsBlockedFunction(key) then
                        module[k] = function() end
                    end
                end
            end
            module.__ak_sec_patch = true
        end)
    end
    return module
end

-- ======================= ULTIMATE PACKET BLOCK =====================
-- Block subsystem functions
local subsystemBlacklist = {
    "FileCheckSubsystem", "IntegrityCheckSubsystem", "PakCheckSubsystem",
    "ClientWallhackDetectionSubsystem", "ClientESPDetectionSubsystem",
    "ClientAimTrackingSubsystem", "ClientAntiCheatSubsystem",
    "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem",
    "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem",
    "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem",
    "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem",
    "WallCheckSubsystem", "BehaviorScoreSubsystem", "AFKReportorSubsystem",
    "AvatarExceptionSubsystem", "GameReportSubsystem", "SwiftHawkSubsystem",
    "HeartbeatSubsystem", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
    "ModifierExceptionSubsystem", "SimulateCharacterSubsystem",
    "ClientRenderCheckSubsystem", "ClientMemoryGuardSubsystem",
    "ClientKernelCheckSubsystem"
}

pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr and not SubsystemMgr.__ak_intercept then
        local origGet = SubsystemMgr.Get
        SubsystemMgr.Get = function(self, name)
            local sub = origGet(self, name)
            if type(sub) == "table" and not sub.__ak_sub_silenced then
                for _, blackName in ipairs(subsystemBlacklist) do
                    if name == blackName then
                        pcall(function()
                            for k, v in pairs(sub) do
                                if type(v) == "function" then
                                    local key = tostring(k):lower():gsub("[^%w]", "")
                                    if IsBlockedFunction(key) then
                                        sub[k] = function() end
                                    end
                                end
                            end
                            sub.__ak_sub_silenced = true
                        end)
                        break
                    end
                end
            end
            return sub
        end
        SubsystemMgr.__ak_intercept = true
    end
end)

-- Patch GameplayCallbacks
if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
local mt = getmetatable(_G.GameplayCallbacks) or {}
mt.__index = function(t, key)
    local func = rawget(t, key)
    if type(func) == "function" then
        local name = tostring(key):lower():gsub("[^%w]", "")
        if IsBlockedFunction(name) then
            return function() end
        end
    end
    return func
end
mt.__newindex = function(t, key, value)
    if type(value) == "function" then
        local name = tostring(key):lower():gsub("[^%w]", "")
        if IsBlockedFunction(name) then
            value = function() end
        end
    end
    rawset(t, key, value)
end
setmetatable(_G.GameplayCallbacks, mt)

-- Block EventSystem events
pcall(function()
    if _G.EventSystem and not _G.EventSystem.__ak_event_blocked then
        local origPost = _G.EventSystem.postEvent
        _G.EventSystem.postEvent = function(event, ...)
            if event and tostring(event):lower():find("security") or tostring(event):lower():find("cheat") then
                return
            end
            return origPost(event, ...)
        end
        _G.EventSystem.__ak_event_blocked = true
    end
end)

-- Disable debug info
pcall(function()
    if debug and debug.getinfo then debug.getinfo = function() return {} end end
    if debug and debug.getlocal then debug.getlocal = function() return nil end end
    if jit and jit.attach then
        jit.attach(function() end, "bc")
    end
end)

-- ======================= HYPER MD5 BLOCK ===========================
function InstallHyperMD5Block()
    local fakeMD5 = "7b1c7b5608da3083097816106fc331f9"

    local function fakeHash() return fakeMD5 end
    local function trueFunc() return true end
    local function dummy() end

    pcall(function()
        -- Patch all MD5/hash functions in modules
        local function patchTable(tbl)
            if type(tbl) ~= "table" then return end
            for k, v in pairs(tbl) do
                if type(v) == "function" then
                    local name = tostring(k):lower()
                    if name:match("md5") or name:match("hash") or name:match("crc") or name:match("sha") or name:match("integrity") or name:match("signature") or name:match("verifyfile") or name:match("checkfile") then
                        tbl[k] = trueFunc
                    end
                end
            end
        end

        local modulesToPatch = {
            "CreativeModeBlueprintLibrary", "STExtraBlueprintFunctionLibrary",
            "GameplayStatics", "KismetMathLibrary", "KismetSystemLibrary",
            "FFileHelper", "GameplayData", "AvatarUtils", "TssSdk",
            "slua.loader", "slua.serialize"
        }
        for _, modName in ipairs(modulesToPatch) do
            pcall(function()
                local mod = _G[modName] or package.loaded[modName]
                if mod then patchTable(mod) end
            end)
        end

        -- Patch global MD5 functions
        local md5Funcs = {
            "MD5Hash", "CRC32", "SHA1", "SHA256", "HMAC", "CheckFileIntegrity",
            "VerifySignature", "FileMismatchReport", "OnFileCorrupted",
            "slua_verify", "check_slua_integrity", "GetMD5",
            "ComputeMD5", "VerifyFileIntegrity", "CheckMD5", "CheckFileMD5", "GetFileMD5"
        }
        for _, name in ipairs(md5Funcs) do
            if _G[name] and type(_G[name]) == "function" then
                _G[name] = trueFunc
            end
        end

        -- Patch io.open to block MD5 writes
        local origIOOpen = io.open
        io.open = function(filename, mode)
            if type(filename) == "string" and filename:lower():match("md5") and mode and (mode == "w" or mode == "a") then
                return nil, "Blocked by HyperMD5"
            end
            return origIOOpen(filename, mode)
        end

        -- Block NetUtil MD5 packets
        if NetUtil and NetUtil.SendPacket and not NetUtil._HyperMD5Blocked then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packet, ...)
                if packet and tostring(packet):lower():match("md5") then
                    return nil
                end
                return origSend(packet, ...)
            end
            NetUtil._HyperMD5Blocked = true
        end

        -- TssSdk MD5 hooks
        if _G.TssSdk then
            _G.TssSdk.GetFileMD5 = fakeHash
            _G.TssSdk.VerifyFileSignature = trueFunc
            local origRecv = _G.TssSdk.OnRecvData
            _G.TssSdk.OnRecvData = function(data)
                if type(data) == "string" and data:lower():match("md5") then
                    return
                end
                if origRecv then origRecv(data) end
            end
        end

        -- Patch subsystem check functions
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local checkSubs = {"FileCheckSubsystem", "AssetCheckSubsystem", "IntegrityCheckSubsystem", "PakCheckSubsystem"}
            for _, name in ipairs(checkSubs) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            sub[k] = dummy
                        end
                    end
                    sub.StartCheck = dummy
                    sub.ReportAbnormalFile = dummy
                end
            end
        end
    end)
end

-- ======================= ULTIMATE REPORT BLOCK =====================
function BlockAllReports()
    local function dummy() end
    local function trueFunc() return true end
    local function falseFunc() return false end
    local function zeroFunc() return 0 end
    local function emptyTable() return {} end
    local function emptyString() return "" end

    -- Patch all security modules
    pcall(function()
        -- HiggsBosonComponent
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local origInit = Higgs.Initialize or Higgs.ctor
            Higgs.Initialize = function(self, ...)
                self.bMHActive = false
                self.bCallPreReplication = false
                if origInit then origInit(self, ...) end
            end
            -- Also patch by metatable
            local mt = getmetatable(Higgs) or {}
            mt.__index = function(t, k) return dummy end
            mt.__newindex = function(t, k, v) end
            mt.__call = dummy
            setmetatable(Higgs, mt)
            rawset(Higgs, "bMHActive", false)
            rawset(Higgs, "bCallPreReplication", false)
            rawset(Higgs, "BlackList", {})
        end

        -- AvatarCheckCallback
        if _G.AvatarCheckCallback and type(_G.AvatarCheckCallback) == "table" then
            local mt = getmetatable(_G.AvatarCheckCallback) or {}
            mt.__index = dummy
            mt.__newindex = dummy
            mt.__call = dummy
            setmetatable(_G.AvatarCheckCallback, mt)
            rawset(_G.AvatarCheckCallback, "bMHActive", false)
            rawset(_G.AvatarCheckCallback, "BlackList", {})
        end

        -- GameSafeCallbacks
        if _G.GameSafeCallbacks then
            local mt = getmetatable(_G.GameSafeCallbacks) or {}
            mt.__index = dummy
            mt.__newindex = dummy
            mt.__call = dummy
            setmetatable(_G.GameSafeCallbacks, mt)
            rawset(_G.GameSafeCallbacks, "bMHActive", false)
            rawset(_G.GameSafeCallbacks, "BlackList", {})
        end

        _G.BlackList = {}
    end)

    -- Patch FFileHelper
    pcall(function()
        local FFileHelper = import("FFileHelper")
        if FFileHelper and FFileHelper.SaveStringToFile then
            local origSave = FFileHelper.SaveStringToFile
            FFileHelper.SaveStringToFile = function(str, filename, ...)
                if tostring(filename):lower():match("md5") or tostring(filename):lower():match("hash") or tostring(filename):lower():match("integrity") then
                    return true
                end
                return origSave(str, filename, ...)
            end
        end
    end)

    -- Patch slua signatures
    pcall(function()
        if slua and slua.getSignature then
            slua.getSignature = function() return 3735928559 end
        end
        if rawget(_G, "slua_loader") then
            local loader = rawget(_G, "slua_loader")
            loader.verifyBytecode = trueFunc
            loader.checkIntegrity = trueFunc
            if loader.disableSignatureCheck then
                loader.disableSignatureCheck = trueFunc
            end
        end
        if package.loaded["slua.serialize"] then
            local ser = package.loaded["slua.serialize"]
            ser.check = trueFunc
            ser.verify = trueFunc
        end
        if jit and jit.attach then
            jit.attach(function() end, "bc")
        end
    end)

    -- Execute console commands to disable pak signature checks
    pcall(function()
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary then
            KismetSystemLibrary.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            KismetSystemLibrary.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            KismetSystemLibrary.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            KismetSystemLibrary.ExecuteConsoleCommand(nil, "sig.Check 0")
            KismetSystemLibrary.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
    end)

    -- Block all telemetry, logging, error reporting
    pcall(function()
        if package.loaded["client.slua.logic.download.report.puffer_tlog"] then
            local mod = package.loaded["client.slua.logic.download.report.puffer_tlog"]
            mod.ReportEvent = dummy
            mod.ReportDownloadResult = dummy
            mod.ReportODPTDError = dummy
            mod.ReportSkinError = dummy
        end

        if _G.AvatarUtils then
            _G.AvatarUtils.CheckIsWeaponInBlackList = falseFunc
            _G.AvatarUtils.IsValidAvatar = trueFunc
            _G.AvatarUtils.CheckAvatarIntegrity = trueFunc
            _G.AvatarUtils.ReportInvalidAvatar = dummy
        end

        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local fileCheck = SubsystemMgr:Get("FileCheckSubsystem")
            if fileCheck then
                fileCheck.StartCheck = dummy
                fileCheck.ReportAbnormalFile = dummy
                fileCheck.StopCheck = dummy
            end
        end

        if package.loaded["client.slua.logic.report.EquipmentExceptionReport"] then
            local mod = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
            mod.Report = dummy
            mod.SendException = dummy
        end
    end)

    -- Block Screenshot
    pcall(function()
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MTDePicture = function() return "" end
            ScreenshotMaker.ReMTDePicture = function() return "" end
            ScreenshotMaker.HasCaptured = trueFunc
            ScreenshotMaker.TakeScreenshot = dummy
            ScreenshotMaker.MakePicture = function() return "" end
            ScreenshotMaker.ReMakePicture = function() return "" end
        end
    end)

    -- Block TLog
    pcall(function()
        if _G.TLog then
            _G.TLog.Info = dummy
            _G.TLog.Warning = dummy
            _G.TLog.Error = dummy
            _G.TLog.Debug = dummy
            _G.TLog.Report = dummy
            _G.TLog.Send = dummy
            _G.TLog.Flush = dummy
        end

        if _G.CrashSight then
            _G.CrashSight.ReportException = dummy
            _G.CrashSight.SetCustomData = dummy
            _G.CrashSight.Log = dummy
            _G.CrashSight.SendCrash = dummy
            _G.CrashSight.ReportUserException = dummy
        end

        local GameReportUtils = require("GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils")
        if GameReportUtils then
            GameReportUtils.BugglyPostExceptionFull = falseFunc
            GameReportUtils.CheckCanBugglyPostException = falseFunc
            GameReportUtils.ReplayReportData = dummy
            GameReportUtils.ReportGameException = dummy
            GameReportUtils.PostException = dummy
        end

        if package.loaded["client.slua.logic.report.ClientToolsReport"] then
            local mod = package.loaded["client.slua.logic.report.ClientToolsReport"]
            mod.SendReport = dummy
            mod.SendException = dummy
            mod.UploadLog = dummy
        end

        if package.loaded["client.slua.config.tlog.tlog_report_utils"] then
            local mod = package.loaded["client.slua.config.tlog.tlog_report_utils"]
            mod.ReportTLogEvent = dummy
            mod.FlushEvents = dummy
        end
    end)

    -- Block analytics
    local analytics = {"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}
    pcall(function()
        for _, name in ipairs(analytics) do
            if _G[name] then
                _G[name].logEvent = dummy
                _G[name].trackEvent = dummy
                _G[name].setEnabled = falseFunc
                _G[name].sendEvent = dummy
                _G[name].report = dummy
            end
        end
    end)

    -- Block more crash/analytics modules
    local moreModules = {"Bugly", "Bugly2", "ExceptionHandler", "TDataManager", "TSSException", "GameGuard", "TDataMaster"}
    pcall(function()
        for _, name in ipairs(moreModules) do
            local mod = package.loaded[name] or _G[name]
            if mod then
                if mod.ReportException then mod.ReportException = dummy end
                if mod.ReportError then mod.ReportError = dummy end
                if mod.Report then mod.Report = dummy end
                if mod.SendReport then mod.SendReport = dummy end
                if mod.SetUserData then mod.SetUserData = dummy end
            end
        end
    end)

    -- Block subsystem report functions
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local subs = {
                "AFKReportorSubsystem", "ClientDataStatistcsSubsystem",
                "AvatarExceptionSubsystem", "ShootVerifySubSystemClient",
                "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
                "FileCheckSubsystem", "BehaviorScoreSubsystem"
            }
            for _, name in ipairs(subs) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            local key = tostring(k)
                            if key:find("Report") or key:find("Send") or key:find("Upload") or key:find("Verify") or key:find("Check") or key:find("Validate") or key:find("Scan") or key:find("Detect") then
                                pcall(function() sub[k] = dummy end)
                            end
                        end
                    end
                    if sub.ReportPingDelayTimer then
                        sub.ReportPingDelayTimer = nil
                        sub.DelayCount = 0
                    end
                end
            end
        end
    end)

    -- Block Replay/Report subsystems
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local replaySubs = {"RescueBtnReplayTraceSubsystem", "GameReportSubsystem", "ReplaySubsystem"}
            for _, name in ipairs(replaySubs) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            local key = tostring(k)
                            if key:find("Report") or key:find("Trace") or key:find("Replay") or key:find("Record") or key:find("Save") then
                                pcall(function() sub[k] = dummy end)
                            end
                        end
                    end
                    if sub.Reporter then
                        sub.Reporter.ReportIntArrayData = dummy
                        sub.Reporter.ReportUInt8ArrayData = dummy
                        sub.Reporter.ReportFloatArrayData = dummy
                    end
                    sub.ReplayReportData = falseFunc
                    sub.CheckCanBugglyPostException = falseFunc
                    sub.BugglyPostExceptionFull = falseFunc
                    sub.GetClientReplayDataReporter = function() return nil end
                end
            end
        end

        if package.loaded["client.slua.logic.replay.logic_report_replay"] then
            local mod = package.loaded["client.slua.logic.replay.logic_report_replay"]
            mod.ReportReplay = dummy
            mod.SendReportReq = dummy
            mod.UploadReplay = dummy
        end

        local ReplayUI = import("ReplayUI")
        if ReplayUI and ReplayUI.ShowReportButton then
            ReplayUI.ShowReportButton = dummy
        end

        if package.loaded["client.slua.logic.home.logic_home_report"] then
            local mod = package.loaded["client.slua.logic.home.logic_home_report"]
            mod.ShowInGameReportUI = dummy
            mod.SendReport = dummy
        end
    end)

    -- Block GameplayCallbacks report functions
    pcall(function()
        if _G.GameplayCallbacks then
            local funcs = {
                "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
                "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate",
                "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition",
                "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData",
                "SendTssSdkAntiDataToLobby", "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby",
                "SendSecTLog", "SendDataMiningTLog", "SendActivityTLog", "SendClientMemUsage",
                "SendClientFPS", "OnClientCrashReport", "OnNetworkLossDetected",
                "ReportMatchRoomData", "ReportPlayersPing", "SendClientStats",
                "SendServerAvgTickDelta", "ReportHitFlow", "OnPlayerActorChannelError",
                "OnPlayerRPCValidateFailed", "ReportEquipmentFlow", "ReportAimFlow",
                "GetWeaponReport", "GetOneWeaponReport", "ReportHeavyWeaponBoxSpawnFlow",
                "ReportHeavyWeaponBoxActivationFlow", "ReportHeavyWeaponBoxOpenPlayerFlow",
                "ReportHeavyWeaponBoxItemFlow", "ReportPlayerIP", "ReportPlayerFramePingRecord",
                "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
                "ReportDSNetRate", "ReportCircleFlow", "ReportDSCircleFlow", "ReportJumpFlow",
                "ReportAIStrategyInfo", "SendAIDeliveryInfo", "ReportDailyTaskInfo",
                "SendPlayerSpectatingLog", "ReportIDCardProduceFlow", "ReportIDCardPickupFlow",
                "ReportIDCardDestroyFlow", "ReportRevivalFlow", "ReportGameSetting",
                "ReportGameSettingNew", "ReportAntsVoiceTeamCreate", "ReportAntsVoiceTeamQuit",
                "ReportCommonInfo", "ReportLightweightStat", "SendSecTLog",
                "SendDataMiningTLog", "SendActivityTLog", "GetGeneralTLogData",
                "ReportWallhack", "ReportAimbot", "ReportSpeedhack", "ReportMagicBullet",
                "ReportPlayerControllerStateChanged", "ReportAvatarFlow", "ReportAbnormalMaterial",
                "ReportDepthTestChange", "ReportMemoryException", "ReportMaterialScan",
                "ReportShaderOverride", "ClientSecPlayerKillFlow", "CheckReportSecAttackFlow",
                "CheckReportSecAttackFlowWithAttackFlow", "IsEnableReportPlayerKillFlow",
                "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow",
                "IsEnableReportHitFlow", "IsEnableReportCircleFlow",
                "OnPlayerNetConnectionClosed", "OnPlayerSpectateException", "OnShutdownAfterError"
            }
            for _, name in ipairs(funcs) do
                if _G.GameplayCallbacks[name] then
                    _G.GameplayCallbacks[name] = dummy
                end
            end
            -- Also disable check functions
            for _, name in ipairs({"CheckReportSecAttackFlow", "CheckReportSecAttackFlowWithAttackFlow", "IsEnableReportPlayerKillFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do
                if _G[name] then _G[name] = falseFunc end
            end
            _G.GameplayCallbacks.IsUltimateBypassed = true
        end
    end)

    -- Block security collectors
    pcall(function()
        local collectors = {"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}
        for _, name in ipairs(collectors) do
            if _G[name] then
                for k, v in pairs(_G[name]) do
                    if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then
                        _G[name][k] = dummy
                    end
                end
            end
        end

        local PlayerSecurityInfoSubsystem = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if PlayerSecurityInfoSubsystem then
            PlayerSecurityInfoSubsystem.ReportData = dummy
            PlayerSecurityInfoSubsystem.CheckCheat = falseFunc
            PlayerSecurityInfoSubsystem.ValidatePlayer = trueFunc
            PlayerSecurityInfoSubsystem.CollectData = dummy
            PlayerSecurityInfoSubsystem.SendToServer = dummy
        end

        if _G.PlayerSecurityInfo then
            _G.PlayerSecurityInfo.ReportCheat = dummy
            _G.PlayerSecurityInfo.ReportSuspicious = dummy
            _G.PlayerSecurityInfo.SendSecurityData = dummy
            _G.PlayerSecurityInfo.CollectSecurityInfo = dummy
        end
    end)

    -- Block flow subsystems
    pcall(function()
        local flowSubs = {"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}
        for _, name in ipairs(flowSubs) do
            local mod = package.loaded[name] or _G[name]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then
                        pcall(function() mod[k] = dummy end)
                    end
                end
            end
        end

        local ClientCircleFlowSubsystem = require("GameLua.Mod.BaseMod.Client.Security.ClientCircleFlowSubsystem")
        if ClientCircleFlowSubsystem then
            ClientCircleFlowSubsystem.ReportCircleFlow = dummy
            ClientCircleFlowSubsystem.SendCircleData = dummy
            ClientCircleFlowSubsystem.ReportPlayerPosition = dummy
            ClientCircleFlowSubsystem.ReportCircleData = dummy
        end

        if _G.ReportPlayerKillFlow then _G.ReportPlayerKillFlow = dummy end
        if _G.ClientSecPlayerKillFlow then _G.ClientSecPlayerKillFlow = dummy end
    end)

    -- Block heartbeat
    pcall(function()
        local heartbeats = {"Heartbeat", "SendHeartbeat", "ClientHeartbeat", "ServerHeartbeat"}
        for _, name in ipairs(heartbeats) do
            if _G[name] then _G[name] = dummy end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[name] then
                _G.GameplayCallbacks[name] = dummy
            end
        end
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local hb = SubsystemMgr:Get("HeartbeatSubsystem")
            if hb then
                if hb.timer then pcall(function() hb:RemoveGameTimer(hb.timer) end) end
                hb.SendHeartbeat = dummy
                hb.StartHeartbeat = dummy
            end
        end
    end)

    -- Block CoronaLab
    pcall(function()
        if _G.CoronaLab then
            _G.CoronaLab.ReportData = dummy
            _G.CoronaLab.SendData = dummy
            _G.CoronaLab.CollectData = dummy
            _G.CoronaLab.Telemetry = dummy
        end
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local corona = SubsystemMgr:Get("CoronaLabSubsystem")
            if corona then
                corona.ReportData = dummy
                corona.SendToServer = dummy
                corona.CollectTelemetry = dummy
                corona.StopCollection = dummy
            end
        end
        _G.GlobalPlayerCoronaData = {}
        local mt = {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
    end)

    -- Block ModifierException
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local ModifierExceptionSubsystem = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if ModifierExceptionSubsystem then
            ModifierExceptionSubsystem.ReportException = dummy
            ModifierExceptionSubsystem.CheckModifier = trueFunc
            ModifierExceptionSubsystem.ValidateModifier = trueFunc
            ModifierExceptionSubsystem.ReportModifierError = dummy
        end
    end)

    -- Block SimulateCharacter
    pcall(function()
        local SimulateCharacterSubsystem = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if SimulateCharacterSubsystem then
            SimulateCharacterSubsystem.ReportLocation = dummy
            SimulateCharacterSubsystem.SendLocationData = dummy
            SimulateCharacterSubsystem.VerifyLocation = trueFunc
        end
    end)

    -- Block ShootVerify
    pcall(function()
        local ShootVerify = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if ShootVerify then
            ShootVerify.OnShootVerifyFailed = dummy
            ShootVerify.SendVerifyData = dummy
            ShootVerify.ReportBulletHit = dummy
            ShootVerify.UploadHitInfo = dummy
            ShootVerify.VerifyShot = trueFunc
        end
        if _G.BulletHitInfoUploadData then
            _G.BulletHitInfoUploadData.Report = dummy
            _G.BulletHitInfoUploadData.Send = dummy
            _G.BulletHitInfoUploadData.Upload = dummy
        end
    end)

    -- Block report player subsystems
    pcall(function()
        local clientReport = require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if clientReport then
            clientReport.OnInit = dummy
            clientReport._OnPlayerKilledOtherPlayer = dummy
            clientReport._RecordFatalDamager = dummy
            clientReport._OnDeathReplayDataWhenFatalDamaged = dummy
            clientReport._RecordMurdererFromDeathReplayData = dummy
            clientReport._RecordTeammatePlayerInfo = dummy
            clientReport._OnBattleResult = dummy
            clientReport._OnShowQuickReportMutualExclusiveUI = dummy
            clientReport.GetFatalDamagerMap = emptyTable
            clientReport.GetCachedTeammateName2InfoMap = emptyTable
            clientReport.GetTeammateName2InfoMapDuringBattle = emptyTable
            clientReport.GetCurrentNotInTeamHistoricalTeammateMap = emptyTable
            clientReport.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end

        local dsReport = require("GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem")
        if dsReport then
            dsReport.OnInit = dummy
            dsReport._OnNearDeathOrRescued = dummy
            dsReport._OnCharacterDied = dummy
            dsReport._OnTeammateDamage = dummy
            dsReport._OnPlayerSettlementStart = dummy
            dsReport._AddKnockDownerToBattleResult = dummy
            dsReport._AddKillerToBattleResult = dummy
            dsReport._AddTeammateMurderToBattleResult = dummy
            dsReport._AddFatalDamagerMapToBattleResult = dummy
            dsReport._AddMLKillerUIDToBattleResult = dummy
            dsReport._SaveHistoricalTeammateInfo = dummy
            dsReport._RecordFatalDamager = dummy
            dsReport._RecordTeammateMurderer = dummy
        end

        local ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if ReportPlayerUtils then
            ReportPlayerUtils.RecordFatalDamager = dummy
            ReportPlayerUtils.IsUsingHistoricalTeammateInfo = falseFunc
            ReportPlayerUtils.IsCharacterDeliverAI = falseFunc
        end

        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = emptyTable
            SecurityCommonUtils.LogIf = falseFunc
        end

        local ClientQuickReportMaliciousTeammate = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if ClientQuickReportMaliciousTeammate then
            ClientQuickReportMaliciousTeammate.OnShowMutualExclusiveUI = dummy
            ClientQuickReportMaliciousTeammate.OnHideMutualExclusiveUI = dummy
        end
    end)

    -- Block all subsystem timers and report functions
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local allSubs = {
                "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem",
                "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient",
                "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
                "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem",
                "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem",
                "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
                "AvatarExceptionSubsystem", "GameReportSubsystem", "RescueBtnReplayTraceSubsystem",
                "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "PlayerKillFlowSubsystem",
                "CircleFlowSubsystem", "SwiftHawkSubsystem", "HeartbeatSubsystem",
                "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem",
                "MD5CheckSubsystem", "PakVerifySubsystem"
            }
            for _, name in ipairs(allSubs) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            local key = tostring(k)
                            if key:find("Report") or key:find("Send") or key:find("Upload") or key:find("Verify") or key:find("Check") or key:find("Validate") or key:find("Scan") or key:find("Detect") or key:find("Collect") or key:find("Flow") or key:find("Heartbeat") then
                                pcall(function() sub[k] = dummy end)
                            end
                        end
                    end
                    -- Remove timers
                    if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                    if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                    if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
                end
            end
        end
    end)

    -- Disable feature flags
    pcall(function()
        local flags = {
            "ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY",
            "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"
        }
        for _, flag in ipairs(flags) do
            if _G[flag] then _G[flag] = false end
        end
    end)

    -- Block additional reporting functions
    pcall(function()
        local STExtraBP = import("STExtraBlueprintFunctionLibrary")
        if STExtraBP and STExtraBP.IsDevelopment then
            STExtraBP.IsDevelopment = falseFunc
        end
        if Client then
            Client.IsDevelopment = falseFunc
            Client.IsShipping = falseFunc
        end
        if Server then
            Server.IsShipping = falseFunc
        end

        local ToolReportUtil = require("client.slua.logic.report.ToolReportUtil")
        if ToolReportUtil then
            ToolReportUtil.IsReleaseVersion = falseFunc
            ToolReportUtil.IsWhite = falseFunc
            ToolReportUtil.GetReportSwitch = falseFunc
        end

        if _G.TApmHelper then _G.TApmHelper.postEvent = dummy end

        if _G.PacketCallbacks then
            _G.PacketCallbacks.player_report_cheat = dummy
            _G.PacketCallbacks.upload_loots_rsp = dummy
            _G.PacketCallbacks.watch_player_exit = dummy
            _G.PacketCallbacks.player_login_report = dummy
            _G.PacketCallbacks.player_logout_report = dummy
            _G.PacketCallbacks.server_time_report = dummy
        end

        if _G.ServerDataMgr and _G.ServerDataMgr.DeletablePlayerResultKey then
            _G.ServerDataMgr.DeletablePlayerResultKey.SuspiciousHitCount = true
            _G.ServerDataMgr.DeletablePlayerResultKey.EspTotalSimTraceCnt = true
            _G.ServerDataMgr.DeletablePlayerResultKey.EspTotalImeFocusCnt = true
            _G.ServerDataMgr.DeletablePlayerResultKey.ClientGravityAnomalyCount = true
        end

        local SecurityNotifyPCFeature = require("GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature")
        if SecurityNotifyPCFeature then
            SecurityNotifyPCFeature.ClientRPC_SyncBanID = dummy
            SecurityNotifyPCFeature.ClientRPC_StrongTips = dummy
            SecurityNotifyPCFeature.ClientRPC_NormalTips = dummy
            SecurityNotifyPCFeature.Notify = dummy
            SecurityNotifyPCFeature.ClientRPC_NotifyBan = dummy
            SecurityNotifyPCFeature.ClientRPC_NotifyPunish = dummy
            SecurityNotifyPCFeature.ClientRPC_NotifyIllegalProgram = dummy
        end

        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtils and SecurityCommonUtils.EStrategyTypeInReplay then
            local strat = SecurityCommonUtils.EStrategyTypeInReplay
            strat.EspTotalSimTraceCnt = 0
            strat.EspTotalImeFocusCnt = 0
            strat.ClientGravityAnomalyCount = 0
            strat.FlyingErrorCnt = 0
        end

        local ClientGlueHiaSystem = require("GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem")
        if ClientGlueHiaSystem then
            ClientGlueHiaSystem.CheckHitIntegrity = dummy
            ClientGlueHiaSystem.InitSession = dummy
            ClientGlueHiaSystem.OnBattleEnd = dummy
        end

        local BehaviorScoreSubsystem = require("GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem")
        if BehaviorScoreSubsystem then
            BehaviorScoreSubsystem.OnHandleBehaviorScore = dummy
            BehaviorScoreSubsystem.AIPerceptionScore = dummy
            BehaviorScoreSubsystem.ReportBehavior = dummy
            BehaviorScoreSubsystem.CalcFinalScore = zeroFunc
        end

        local ClientBanLogic = require("client.slua.logic.ban.ClientBanLogic")
        if ClientBanLogic then
            ClientBanLogic.OnSyncBanInfo = dummy
            ClientBanLogic.OnVoiceBanNotify = dummy
            ClientBanLogic.OnRealTimeVoiceBanNotify = dummy
            ClientBanLogic.OnVoiceBanSuccess = dummy
            ClientBanLogic.OnSyncMicSuspicious = dummy
            ClientBanLogic.OnSyncMicPreFilter = dummy
            ClientBanLogic.OnNotifyWarningTips = dummy
            ClientBanLogic.ReqBanInfo = dummy
        end

        if _G.ban_util then
            _G.ban_util.CheckBanStatus = falseFunc
            _G.ban_util.GetBanTime = zeroFunc
            _G.ban_util.IsBanForever = falseFunc
        end

        if _G.logic_tt_ban then
            _G.logic_tt_ban.CheckIfCanCreateRole = dummy
            _G.logic_tt_ban.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
        end

        local handlers = {
            "GodzillaBanHandler", "AntiaddctionHandler", "AccessRestrictionHandler"
        }
        for _, name in ipairs(handlers) do
            local handler = require("client.network.Protocol." .. name)
            if handler then
                for k, v in pairs(handler) do
                    if type(v) == "function" then
                        handler[k] = dummy
                    end
                end
            end
        end

        local LogicDeleteAccount = require("client.slua.logic.gdpr.logic_deleteaccount")
        if LogicDeleteAccount then
            LogicDeleteAccount.ForceDeleteAccount = falseFunc
            LogicDeleteAccount.OnReceiveDeleteNotify = dummy
        end

        local ComplianceUtil = require("client.slua.logic.gdpr.compliance_util")
        if ComplianceUtil then
            ComplianceUtil.CheckCompliance = dummy
        end

        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local dsHawk = SubsystemMgr:Get("DSHawkEyePatrolSubsystem")
            if dsHawk then
                dsHawk.MarkSuspiciousPlayer = dummy
            end
        end

        if _G.DSHawkEyePatrolSubsystem then
            _G.DSHawkEyePatrolSubsystem._OnHawkReport = dummy
            _G.DSHawkEyePatrolSubsystem._OnHawkImprison = dummy
            _G.DSHawkEyePatrolSubsystem.CheckPunishPlayer = dummy
        end

        local ClientHawkEye = require("GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem")
        if ClientHawkEye then
            ClientHawkEye._OnHawkSync = dummy
            ClientHawkEye._OnHawkReportSuccess = dummy
            ClientHawkEye._StartExitGameTimer = dummy
            ClientHawkEye._OnRecvInspectorBroadcastCount = dummy
            ClientHawkEye.SendReportTLog = dummy
            ClientHawkEye.ReportCheat = dummy
            ClientHawkEye.CanInspectorBroadcast = falseFunc
        end

        local InspectionSystem = require("GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem")
        if InspectionSystem then
            InspectionSystem.AskForInspector = dummy
            InspectionSystem.ReportEnemy = dummy
            InspectionSystem.KickOutOneTeam = dummy
            InspectionSystem.OnReceiveInspectCmd = dummy
            InspectionSystem.ClientReportData = dummy
            InspectionSystem.SendReportToInspector = dummy
            InspectionSystem.SendKickOutOneTeam = dummy
            InspectionSystem.ClientNotifyInspectorImplementation = dummy
            InspectionSystem.RecvNotifyInspector = dummy
        end

        local DSInspection = require("GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem")
        if DSInspection then
            DSInspection.ServerKickOutOneTeamByPlayerImplementation = dummy
            DSInspection.AddReportedCount = dummy
            DSInspection.AddInspectionRecord = dummy
            DSInspection.BanPlayerByInspection = dummy
            DSInspection.BroadCastToAllInspector = dummy
            DSInspection.ServerReportToInspectorImplementation = dummy
            DSInspection.InitPlayerInspectionInfo = dummy
        end
    end)

    -- Block TLog handlers
    pcall(function()
        local tlogModules = {
            "client.network.Protocol.ClientTlogHandler",
            "client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler",
            "client.network.Protocol.LobbyPingReportHandler",
            "client.slua.config.tlog.tlog_report_utils",
            "client.slua.data.BasicData.BasicDataTLogReport",
            "client.slua.data.BasicData.BasicDataClientReport",
            "client.slua.data.BasicData.BasicDataReport",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"
        }
        for _, modName in ipairs(tlogModules) do
            local mod = package.loaded[modName]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and (k:find("Log") or k:find("Report") or k:find("Send") or k:find("Tlog")) then
                        pcall(function() mod[k] = dummy end)
                    end
                end
            end
        end

        -- Specific handlers
        if package.loaded["client.network.Protocol.ClientErrorReportHandler"] then
            local mod = package.loaded["client.network.Protocol.ClientErrorReportHandler"]
            mod.send_client_error_report = dummy
            mod.send_client_crash_report = dummy
            mod.send_client_tools_batch_report_req = dummy
        end
        if package.loaded["client.network.Protocol.BattleReportHandler"] then
            local mod = package.loaded["client.network.Protocol.BattleReportHandler"]
            mod.send_battle_report = dummy
            mod.send_battle_result = dummy
            mod.send_vod_game_report_req = dummy
            mod.send_batch_get_vod_info_req = dummy
            mod.send_get_game_report_req = dummy
            mod.send_batch_get_game_report_req = dummy
            mod.send_get_game_report_by_uid_req = dummy
        end
        if package.loaded["client.network.Protocol.BugHandler"] then
            local mod = package.loaded["client.network.Protocol.BugHandler"]
            mod.send_report_bug_info = dummy
            mod.send_report_bug_feedback = dummy
        end
        if package.loaded["client.network.Protocol.LobbyPingReportHandler"] then
            local mod = package.loaded["client.network.Protocol.LobbyPingReportHandler"]
            mod.send_lobby_ping_report = dummy
            mod.send_ingame_ping_report = dummy
        end
        if package.loaded["client.network.Protocol.WeekRportHandler"] then
            local mod = package.loaded["client.network.Protocol.WeekRportHandler"]
            mod.send_week_report = dummy
            mod.send_week_detail = dummy
        end
        if package.loaded["client.logic.battle.logic_complaint"] then
            local mod = package.loaded["client.logic.battle.logic_complaint"]
            mod.SendComplaintReq = dummy
            mod.Submit = dummy
            mod.ReportPlayer = dummy
            mod.ShowComplaint = dummy
            mod.ShowHandle = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"]
            mod.OnBattleResult = dummy
            mod.OnResultProcessStart = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"]
            mod.OnBattleResult = dummy
            mod.OnResultProcessStart = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"]
            mod.OnBattleResult = dummy
            mod.OnResultProcessStart = dummy
            mod.OnResultProcessContinue = dummy
            mod.ReceiveData = dummy
            mod.SendEndFlow = dummy
            mod.OnReport = dummy
            mod.ShowResult = dummy
            mod.ShowResultInternal = dummy
            mod.StopResultProcess = dummy
        end
        if package.loaded["client.network.Protocol.EmulatorHandler"] then
            local mod = package.loaded["client.network.Protocol.EmulatorHandler"]
            mod.send_emulator_info = dummy
        end
        if package.loaded["client.logic.login.emulator_scanner"] then
            local mod = package.loaded["client.logic.login.emulator_scanner"]
            mod.StartScan = dummy
            mod.GetScanResult = falseFunc
            mod.ReportScanResult = dummy
        end
        if package.loaded["client.network.Protocol.LoginVerifyHandler"] then
            local mod = package.loaded["client.network.Protocol.LoginVerifyHandler"]
            mod.send_login_verify_req = dummy
            mod.send_device_verify_req = dummy
        end
        if package.loaded["client.logic.data.logic_ds_monitor"] then
            local mod = package.loaded["client.logic.data.logic_ds_monitor"]
            mod.OnRecordMsg = dummy
            mod.OnReportMsg = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"]
            mod.StartToCheck = dummy
            mod.OnReceiveRTT = dummy
            mod.OnReceiveJitter = dummy
            mod.ReportAbnormal = dummy
            mod.ResetData = dummy
        end
        if package.loaded["client.slua.logic.chat_voice.logic_chat_voice_report"] then
            local mod = package.loaded["client.slua.logic.chat_voice.logic_chat_voice_report"]
            mod.ReportVoiceData = dummy
            mod.ReportVoiceText = dummy
        end
        if package.loaded["client.slua.logic.chat_voice.logic_chat_voice_doctor"] then
            local mod = package.loaded["client.slua.logic.chat_voice.logic_chat_voice_doctor"]
            mod.UploadVoiceLog = dummy
            mod.UploadVoiceException = dummy
        end
        if package.loaded["client.slua.logic.home.Audit.logic_home_audit_state"] then
            local mod = package.loaded["client.slua.logic.home.Audit.logic_home_audit_state"]
            mod.SendAuditState = dummy
            mod.ReportAuditResult = dummy
        end
        if package.loaded["client.slua.logic.home.logic_home_report"] then
            local mod = package.loaded["client.slua.logic.home.logic_home_report"]
            mod.ReportHomeData = dummy
            mod.ReportHomeVisitor = dummy
        end
        if package.loaded["client.logic.store.gem_report_utils"] then
            local mod = package.loaded["client.logic.store.gem_report_utils"]
            mod.ReportGemData = dummy
            mod.ReportGemPurchase = dummy
        end
        if package.loaded["client.slua.logic.CustomerService.LogicSafeStation"] then
            local mod = package.loaded["client.slua.logic.CustomerService.LogicSafeStation"]
            mod.UploadVideoEvidence = dummy
            mod.ReportPlayerBehavior = dummy
        end
        if package.loaded["client.slua.logic.CustomerService.LogicCustomerService"] then
            local mod = package.loaded["client.slua.logic.CustomerService.LogicCustomerService"]
            mod.SendComplaint = dummy
            mod.SendFeedback = dummy
        end
        if package.loaded["GameLua.Mod.TDEvent.ZNQ6th.DS.ZNQ6thDSReviveSubsystem"] then
            local mod = package.loaded["GameLua.Mod.TDEvent.ZNQ6th.DS.ZNQ6thDSReviveSubsystem"]
            mod.HaveNewItemForRevive = dummy
        end
        if package.loaded["GameLua.Mod.TDEvent.ZNQ7th.DS.ZNQ7DSReviveSubsystem"] then
            local mod = package.loaded["GameLua.Mod.TDEvent.ZNQ7th.DS.ZNQ7DSReviveSubsystem"]
            mod.HaveChanceRevival = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"] and package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"].OnSpectatorReplayChanged then
            local mod = package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"]
            mod.OnSpectatorReplayChanged = function(self) _G.IsBeingWatched = true end
        end
        if package.loaded["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"] then
            local mod = package.loaded["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"]
            mod.DelayKickOutPlayer = dummy
            mod.ActiveKickNotify = dummy
        end
        if package.loaded["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem"] then
            local mod = package.loaded["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem"]
            mod.IsDebugPanelEnalbedCli = dummy
        end
        if package.loaded["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem"] then
            local mod = package.loaded["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem"]
            mod.OnPlayerKilled = dummy
        end
        if _G.ClientReplayDataReporter then
            _G.ClientReplayDataReporter.ReportIntArrayData = dummy
            _G.ClientReplayDataReporter.ReportFloatArrayData = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"]
            mod.RequestGotoSpectatingImp = dummy
            mod.RequestGotoSpectating = dummy
        end
        if package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"] then
            local mod = package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"]
            mod.ReportAllPlayerInfo = dummy
            mod.ReportFrameData = dummy
            mod.ReportPlayerInput = dummy
            if mod.uCompletePlayBack then
                mod.uCompletePlayBack.AddRecordMLAIInfo = dummy
                mod.uCompletePlayBack.StopRecording = dummy
            end
        end
        if package.loaded["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"]
            mod.RealLogoutTimer = dummy
            mod.LogQueue = {}
            mod.AddToLogQue = dummy
            mod.DoPrint = dummy
            mod.OnAIPawnDied = dummy
            mod.OnAIPawnReceiveDamage = dummy
            mod.OnAIPawnEnemyChange = dummy
        end
        if package.loaded["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"]
            mod.HandleEnterFighting = dummy
            mod.InitializePlayerInputInfo = dummy
            mod.AddOneAFKInfo = dummy
            mod.SetPlayerAFKState = dummy
            mod.ResetPlayerInputInfo = dummy
            mod.PlayerHaveAction = dummy
        end
        if package.loaded["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"] then
            local mod = package.loaded["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"]
            mod.SendAFKTips = dummy
            mod.OnHandleLostConnection = dummy
        end
        if package.loaded["client.slua.logic.data.data_mgr"] then
            local mod = package.loaded["client.slua.logic.data.data_mgr"]
            mod.GetWeaponSkinSoundVolumeInfoByGroup = zeroFunc
        end
        if package.loaded["GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic"] then
            local mod = package.loaded["GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic"]
            mod._SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = dummy
            mod.ShowReturnLobbyIfFirstExitTeamBeforeBoarding = falseFunc
            mod.OnReceiveCreditScoreChange = dummy
            mod._IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = falseFunc
            mod.SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = dummy
        end
    end)

    -- Final global block for common report functions
    pcall(function()
        local globalBlockList = {
            "ReportTLogEvent", "SendTlog", "SendClientStats", "ReportHitFlow",
            "ReportAvatarException", "SendComplaintReq", "SubmitReport",
            "ReportSuspiciousPlayer", "SendPacket", "OnSyncBanInfo", "OnVoiceBanNotify",
            "SendSecTLog", "MarkSuspiciousPlayer", "ReportPlayerBehaviorData",
            "CheckCompliance", "ReportIllegalProgram", "UploadVoiceLog"
        }
        for _, name in ipairs(globalBlockList) do
            if type(_G[name]) == "function" then
                _G[name] = dummy
            end
        end
    end)
end

-- ======================= HTTP & NETWORK BLOCK ======================
local blockedDomains = {
    "tss.tencent", "syzsdk", "gcloud.qq", "reportlog", "tdos", "logupload",
    "feedback.wh", "crash2", "privacy.qq", "privacy.tencent", "oth.eve",
    "mdt.qq", "act.tencentyun", "analytics", "report.qq", "anticheatexpert",
    "crashsight", "wetest", "log.tav", "sngd", "tracer", "intlsdk", "igamecj",
    "abs.twimg", "dl.listdl", "igame.gcloudcs", "bugly", "beacon", "helpshift",
    "tdm", "apm", "safeguard", "weiyun", "qzone", "tencent-cloud", "myapp",
    "idqqimg", "gtimg", "qqmail", "tcdn", "cloudctrl", "sdkostrace",
    "103.134.189.146", "mbgame", "csoversea", "igame", "pubgmobile",
    "down.anticheatexpert.com", "asia.csoversea.mbgame.anticheatexpert.com",
    "log.tav.qq", "syzsdk.qq", "logiservice.qcloud", "opensdk.tencent",
    "exp.helpshift", "loginsdkapi.zingplay", "firebase", "googleapis",
    "facebook", "gvoice"
}

local blockedKeywords = {
    "tlog", "crash", "bugly", "report", "beacon", "wetest", "analytics",
    "telemetry", "trace", "dump", "exception", "feedback", "aps_log",
    "mtp_detect", "network_loss", "client_error", "ue4crash", "tdm", "gcloud"
}

function IsUrlBlocked(url)
    if not url then return false end
    local lower = url:lower()
    for _, domain in ipairs(blockedDomains) do
        if lower:find(domain, 1, true) then return true end
    end
    for _, keyword in ipairs(blockedKeywords) do
        if lower:find(keyword, 1, true) then return true end
    end
    return false
end

pcall(function()
    if _G.HttpRequest then
        local origHttp = _G.HttpRequest
        _G.HttpRequest = function(url, ...)
            if IsUrlBlocked(url) then return nil end
            return origHttp(url, ...)
        end
    end
    if _G.FHttpModule and _G.FHttpModule.CreateRequest then
        local origCreate = _G.FHttpModule.CreateRequest
        _G.FHttpModule.CreateRequest = function(...)
            local url = select(1, ...)
            if IsUrlBlocked(url) then return nil end
            return origCreate(...)
        end
    end
end)

-- Block io.open for log files
local origIOOpen = io.open
io.open = function(filename, mode)
    if type(filename) == "string" then
        for _, keyword in ipairs(blockedKeywords) do
            if filename:lower():find(keyword, 1, true) and mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                return nil, "Blocked"
            end
        end
    end
    return origIOOpen(filename, mode)
end

-- Remove crash context
if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
    _G.UnrealEngine.CrashContext = {}
    _G.UnrealEngine.CrashContext.AddCrashData = function() end
    if _G.SetCrashContext then _G.SetCrashContext = function() end end
    if _G.ReportCrash then _G.ReportCrash = function() end end
end

-- ======================= INITIALIZATION ============================
function InitializeAllSystems()
    if not CheckExpiration() then
        showExpirationMessage(true)
        return
    end

    -- Show welcome
    if not _G.WelcomeShown then
        showExpirationMessage(false)
        _G.WelcomeShown = true
    end

    -- Setup native ESP config
    SetupNativeESP()

    -- Start wallhack timer if not started
    if not _G._newWallhackStarted then
        _G._newWallhackStarted = true
        pcall(function()
            if _G.StartNewWallhack then
                _G.StartNewWallhack()
            end
        end)
    end

    -- Install bypasses
    InstallWallhackBypass()
    InstallAimbotBypass()
    InstallAdvancedBypass()
    InstallDeviceBanBypass()
    InstallHyperMD5Block()
    BlockAllReports()
end
