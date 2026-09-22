local ASTExtraPlayerCharacter = import("STExtraPlayerCharacter")
local EViewTargetBlendFunction = import("EViewTargetBlendFunction")
local FormatLog = FuncUtil.FormatLog
local EPawnState = import("EPawnState")
local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
local EInspectorBroadcastResult = {Broadcasted = 1, ReachLimit = 2}
local DSHawkEyePatrolSubsystem = {}

function DSHawkEyePatrolSubsystem:OnInit()
  FormatLog("on init")
  self:AddCommonEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_CHARACTER_DIED, self._OnCharacterDied, self)
  self:AddCommonEvent(EVENTTYPE_PLAYER, EVENTID_PLAYER_WATCH_PLAYER_EXIT, self._OnWatchPlayerExit, self)
  self:AddCommonEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_HAWK_REPORT, self._OnHawkReport, self)
  self:AddCommonEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_HAWK_IMPRISON, self._OnHawkImprison, self)
  self:AddCommonEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_PLAYER_RESPAWN, self._OnPlayerRespawn, self)
  self:AddCommonEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_RECONNECT, self._OnPlayerReconnect, self)
  self:AddCommonEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_SYNC_INSPECTOR_BROADCAST_COUNT, self._OnSyncInspectorBroadcastCount, self)
  self._tDeathSentFlag = {}
  self._tSuspiciousPlayerSet = {}
  self._tWantNextPatrolPlayerSet = {}
  self._tPunishedPlayerSet = {}
  self._tImprisonPlayerSet = {}
  self._tReportPlayerSet = {}
  self.nMaxInspectorBroadcastCount = 3
  self.nInspectorBroadcastTotalCount = 0
  self.nMaxInspectorBroadcastTotalCount = 3
  self.nLastInspectorBroadcastTime = 0
  self.nInspectorBroadcastCDSec = 20
end

function DSHawkEyePatrolSubsystem:_OnCharacterDied(_, __, uDeadCharacter, uDamageCauser, nDamageType, uKillerCharacter)
  self:_ReportCharacterDied(uDeadCharacter, uDamageCauser, nDamageType, uKillerCharacter)
end

function DSHawkEyePatrolSubsystem:_OnWatchPlayerExit(_, __, nUID, sReason)
  nUID = tonumber(nUID)
  if not nUID then
    return
  end
  if sReason ~= "is_hawkeye_next" then
    return
  end
  FormatLog("nUID=%s, sReason=%s", nUID, sReason)
  self._tWantNextPatrolPlayerSet[nUID] = true
end

function DSHawkEyePatrolSubsystem:_OnHawkReport(_, __, nPlayerKey, uReporterComp, bInspectorBroadcast)
  FormatLog("_OnHawkReport nPlayerKey[%s]", tostring(nPlayerKey))
  local uPlayerController = self:_GetPlayerControllerByPlayerKey(nPlayerKey)
  if slua.isValid(uPlayerController) then
    self:CheckPunishPlayer(uPlayerController, uReporterComp)
  end
  if bInspectorBroadcast then
    self:CheckInspectorBroadcast(uReporterComp)
  end
end

function DSHawkEyePatrolSubsystem:_OnHawkImprison(_, __, nPlayerKey, bImprison)
  FormatLog("_OnHawkImprison nPlayerKey[%s] bImprison[%s]", tostring(nPlayerKey), tostring(bImprison))
  local uPlayerController = self:_GetPlayerControllerByPlayerKey(nPlayerKey)
  if slua.isValid(uPlayerController) then
    self:ImprisonPlayer(uPlayerController, bImprison)
  end
end

function DSHawkEyePatrolSubsystem:_OnPlayerRespawn(_, __, uCharacter)
  if not slua.isValid(uCharacter) then
    return
  end
  local nPlayerUID = tonumber(uCharacter.PlayerUID)
  if not self._tPunishedPlayerSet[nPlayerUID] then
    return
  end
  local uPlayerController = uCharacter:GetPlayerControllerSafety()
  if not slua.isValid(uPlayerController) then
    FormatLog("invalid uPlayerController")
    return
  end
  FormatLog("_OnPlayerRespawn nPlayerUID[%s]", tostring(nPlayerUID))
  uCharacter:EnterState(EPawnState.HawkReported)
  if slua.isValid(uPlayerController.SpectatorComponent) then
    uPlayerController.SpectatorComponent:ClientRPC_HawkReportSuccess(false)
  end
  if self._tImprisonPlayerSet[nPlayerUID] then
    FormatLog("in _tImprisonPlayerSet")
    self:ImprisonPlayer(uPlayerController, true)
  end
end

function DSHawkEyePatrolSubsystem:_OnPlayerReconnect(_, __, uReporterComp)
  if not slua.isValid(uReporterComp) then
    FormatLog("invalid uReporterComp")
    return
  end
  local uReporterController = uReporterComp:GetOwner()
  if not slua.isValid(uReporterController) then
    FormatLog("invalid uReporterController")
    return
  end
  local nReporterUID = uReporterController.UID
  if nReporterUID and self._tReportPlayerSet[nReporterUID] then
    FormatLog("_OnPlayerReconnect nReporterUID[%s]", tostring(nReporterUID))
    uReporterComp:ClientRPC_HawkReportSuccess(true)
  end
  local RealTimeBan = require("GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan")
  local nCount = RealTimeBan.GetUIDInspectorBroadcastCount(nReporterUID)
  if 0 <= nCount then
    local nLimit = RealTimeBan.GetUIDInspectorBroadcastLimit(nReporterUID)
    FormatLog("Call ClientRPC_SyncInspectorBroadcastCount nUID[%s] nCount[%s] nLimit[%s]", nReporterUID, nCount, nLimit)
    uReporterComp:ClientRPC_SyncInspectorBroadcastCount(nCount, false, nLimit)
  end
end

function DSHawkEyePatrolSubsystem:_OnSyncInspectorBroadcastCount(_, __, uSpectatorComp)
  if not slua.isValid(uSpectatorComp) then
    FormatLog("invalid uSpectatorComp")
    return
  end
  local uPlayerController = uSpectatorComp:GetOwner()
  if not slua.isValid(uPlayerController) then
    FormatLog("invalid uPlayerController")
    return
  end
  local nUID = uPlayerController.UID
  local RealTimeBan = require("GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan")
  local nCount = RealTimeBan.GetUIDInspectorBroadcastCount(nUID)
  if 0 <= nCount then
    local nLimit = RealTimeBan.GetUIDInspectorBroadcastLimit(nUID)
    FormatLog("Call ClientRPC_SyncInspectorBroadcastCount nUID[%s] nCount[%s] nLimit[%s]", nUID, nCount, nLimit)
    uSpectatorComp:ClientRPC_SyncInspectorBroadcastCount(nCount, false, nLimit)
  end
end

function DSHawkEyePatrolSubsystem:_GetPlayerControllerByPlayerKey(nPlayerKey)
  FormatLog("_GetPlayerControllerByPlayerKey nPlayerKey[%s]", tostring(nPlayerKey))
  if not nPlayerKey then
    FormatLog("not nPlayerKey")
    return nil
  end
  if type(nPlayerKey) ~= "number" then
    FormatLog("not number")
    return nil
  end
  return Game:GetPlayerControllerByPlayerKey(nPlayerKey)
end

function DSHawkEyePatrolSubsystem:CheckPunishPlayer(uPlayerController, uReporterComp)
  local nPlayerUID = uPlayerController.UID
  FormatLog("CheckPunishPlayer nPlayerUID[%s]", tostring(nPlayerUID))
  if self._tPunishedPlayerSet[nPlayerUID] then
    FormatLog("already in _tPunishedPlayerSet")
    return
  end
  local ServerPlayerDataMgr = require("Server.Data.ServerPlayerDataMgr")
  local PlayerInfo = ServerPlayerDataMgr.GetPlayerInfo(nPlayerUID) or {}
  if PlayerInfo.ext_attr and PlayerInfo.ext_attr[2] then
    FormatLog("PlayerInfo.ext_attr[2]")
    if PlayerInfo.ext_attr[2].MarkType == 2 then
      FormatLog("PlayerInfo.ext_attr[2] MarkType == 2")
      self._tPunishedPlayerSet[nPlayerUID] = true
      local uReportController = uReporterComp:GetOwner()
      if slua.isValid(uReportController) then
        local nReporterUID = uReportController.UID
        if nReporterUID then
          self._tReportPlayerSet[nReporterUID] = true
          FormatLog("nReporterUID[%s] add _tReportPlayerSet", tostring(nReporterUID))
        end
      end
      local uPlayer = uPlayerController:GetPlayerCharacterSafety()
      if slua.isValid(uPlayer) then
        uPlayer:EnterState(EPawnState.HawkReported)
      end
      local uVehicleComp = uPlayerController.VehicleUserComp
      if slua.isValid(uVehicleComp) then
        uVehicleComp:ForceExitVehicle(true, "Hawk", true)
      end
      if slua.isValid(uPlayerController.SpectatorComponent) then
        uPlayerController.SpectatorComponent:ClientRPC_HawkReportSuccess(false)
      end
      if slua.isValid(uReporterComp.Object) then
        uReporterComp.Object:ClientRPC_HawkReportSuccess(true)
      else
        FormatLog("invalid uReporterComp")
      end
    end
  end
end

function DSHawkEyePatrolSubsystem:CheckInspectorBroadcast(uReporterComp)
  if not slua.isValid(uReporterComp) then
    FormatLog("invalid uReporterComp")
    return
  end
  local uReporterController = uReporterComp:GetOwner()
  if not slua.isValid(uReporterController) then
    FormatLog("invalid uReporterController")
    return
  end
  local nReporterUID = uReporterController.UID
  local RealTimeBan = require("GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan")
  local nCount = RealTimeBan.GetUIDInspectorBroadcastCount(nReporterUID)
  local nLimit = RealTimeBan.GetUIDInspectorBroadcastLimit(nReporterUID)
  if type(nLimit) ~= "number" or nLimit <= 0 then
    nLimit = self.nMaxInspectorBroadcastCount
  end
  FormatLog("nCount[%s] nLimit[%s] nReporterUID[%s]", nCount, nLimit, nReporterUID)
  if 0 <= nCount and nCount < nLimit then
    FormatLog("CheckInspectorBroadcast DoInspectorBroadcast")
    self:DoInspectorBroadcast(uReporterComp, nReporterUID, nCount)
  end
end

function DSHawkEyePatrolSubsystem:DoInspectorBroadcast(uReporterComp, nReporterUID, nCount)
  if not slua.isValid(uReporterComp) then
    FormatLog("invalid uReporterComp")
    return
  end
  if self.nInspectorBroadcastTotalCount >= self.nMaxInspectorBroadcastTotalCount then
    FormatLog("reach total broadcast limit nTotal[%s] nMax[%s]", self.nInspectorBroadcastTotalCount, self.nMaxInspectorBroadcastTotalCount)
    uReporterComp:ClientRPC_NotifyInspectorBroadcastResult(EInspectorBroadcastResult.ReachLimit)
    return
  end
  local nNow = os.time()
  if self.nLastInspectorBroadcastTime > 0 and nNow - self.nLastInspectorBroadcastTime < self.nInspectorBroadcastCDSec then
    FormatLog("broadcast CD not ready nNow[%s] nLast[%s] nCDSec[%s]", nNow, self.nLastInspectorBroadcastTime, self.nInspectorBroadcastCDSec)
    return
  end
  local EObserverType = import("EObserverType")
  if uReporterComp:GetObserverType() ~= EObserverType.EObserverType_HawkEyeObserver then
    FormatLog("invalid ObserverType")
    return
  end
  local uDSUtils = slua_DSHUD:GetUtils()
  if not slua.isValid(uDSUtils) then
    FormatLog("invalid uDSUtils")
    return
  end
  local sPlayerName = uReporterComp:GetOwnerPlayerName()
  local uDSPlayer = uDSUtils:FindPlayerByPlayerName(sPlayerName, "PureWatcher")
  if not slua.isValid(uDSPlayer) then
    FormatLog("invalid uDSPlayer")
    return
  end
  local nAliasID = uDSPlayer.InspectorAliasId
  if not nAliasID then
    FormatLog("invalid nAliasID")
    return
  end
  print(bWriteLog and "DoInspectorBroadcast AliasID = ", nAliasID)
  local ShowTipsAliasConfig = {
    [2493552] = {TipsID = 11700, AliasTitleID = 32701},
    [2493553] = {TipsID = 11701, AliasTitleID = 32702},
    [2493554] = {TipsID = 11702, AliasTitleID = 32704},
    [2493555] = {TipsID = 11703, AliasTitleID = 32703},
    [2493556] = {TipsID = 11704, AliasTitleID = 32705},
    [2493557] = {TipsID = 11705, AliasTitleID = 32706}
  }
  if nAliasID == 0 then
    nAliasID = 2493552
  end
  local aliasConfig = ShowTipsAliasConfig[nAliasID]
  local RealTimeBan = require("GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan")
  local bAnonymous = RealTimeBan.GetUIDInspectorBroadcastAnonymous(nReporterUID)
  local NameParam
  if bAnonymous then
    NameParam = {
      IsNeedTranslation = true,
      ParamValue = RealTimeBan.INSPECTOR_ANONYMOUS_NAME_LOCKEY
    }
  else
    NameParam = {IsNeedTranslation = false, ParamValue = sPlayerName}
  end
  local ParamTable = {
    [1] = NameParam,
    [2] = {
      IsNeedTranslation = true,
      ParamValue = aliasConfig.AliasTitleID
    }
  }
  local TipsID = aliasConfig.TipsID
  if RealTimeBan.IsUIDOnRankInspector(nReporterUID) then
    TipsID = 12490 + math.min(math.max(0, nAliasID - 2493552), 5) + RealTimeBan.GetTipsIDOffsetInspector(nReporterUID)
  end
  print(bWriteLog and string.format("DSHawkEyePatrolSubsystem:DoInspectorBroadcast nAliasID=%d, TipsID=%d, bAnonymous=%s", nAliasID, TipsID, tostring(bAnonymous)))
  IngameTipsTools.BattleGeneralTipWithTranslation(TipsID, ParamTable, -1)
  self.nInspectorBroadcastTotalCount = self.nInspectorBroadcastTotalCount + 1
  self.nLastInspectorBroadcastTime = os.time()
  FormatLog("total broadcast count updated nTotal[%s] nMax[%s] nLastTime[%s]", self.nInspectorBroadcastTotalCount, self.nMaxInspectorBroadcastTotalCount, self.nLastInspectorBroadcastTime)
  local tAllControllerList = Game and Game.GetAllPlayerControllers and Game:GetAllPlayerControllers()
  if tAllControllerList then
    for _, uPlayerController in pairs(tAllControllerList) do
      if slua.isValid(uPlayerController) and uPlayerController.IsHawkEyeSpectator and uPlayerController:IsHawkEyeSpectator() then
        local uSpectatorComp = uPlayerController.SpectatorComponent
        if slua.isValid(uSpectatorComp) then
          uSpectatorComp:ClientRPC_NotifyInspectorBroadcastResult(EInspectorBroadcastResult.Broadcasted)
        else
          FormatLog("invalid uSpectatorComp on inspector UID[%s]", tostring(uPlayerController.UID))
        end
      end
    end
  else
    FormatLog("invalid tAllControllerList, fallback to notify reporter only")
    uReporterComp:ClientRPC_NotifyInspectorBroadcastResult(EInspectorBroadcastResult.Broadcasted)
  end
  local nNewCount = nCount + 1
  RealTimeBan.SetInspectorBroadcastCountUID(nReporterUID, nNewCount)
  local nLimit = RealTimeBan.GetUIDInspectorBroadcastLimit(nReporterUID)
  uReporterComp:ClientRPC_SyncInspectorBroadcastCount(nNewCount, true, nLimit)
end

function DSHawkEyePatrolSubsystem:ImprisonPlayer(uPlayerController, bImprison)
  local nPlayerUID = uPlayerController.UID
  FormatLog("ImprisonPlayer nPlayerUID[%s] bImprison[%s]", tostring(nPlayerUID), tostring(bImprison))
  if not self._tPunishedPlayerSet[nPlayerUID] then
    FormatLog("not punished nPlayerUID")
    return
  end
  self._tImprisonPlayerSet[nPlayerUID] = bImprison
  local uPlayerPawn = uPlayerController:GetPlayerCharacterSafety()
  if slua.isValid(uPlayerPawn) then
    local bHasImprison = uPlayerPawn:HasState(EPawnState.Imprisonment)
    if bHasImprison == true and bImprison == false then
      FormatLog("Release")
      uPlayerPawn:LeaveState(EPawnState.Imprisonment)
    elseif bHasImprison == false and bImprison == true then
      FormatLog("Imprison")
      uPlayerPawn:EnterState(EPawnState.Imprisonment)
    end
  else
    FormatLog("invalid uPlayerPawn")
  end
end

function DSHawkEyePatrolSubsystem:MarkSuspiciousPlayer(nUID)
  nUID = tonumber(nUID)
  if not nUID then
    FormatLog("invalid nUID")
    return
  end
  self._tSuspiciousPlayerSet[nUID] = true
  FormatLog("nUID=%s", nUID)
end

function DSHawkEyePatrolSubsystem:_ReportCharacterDied(uDeadCharacter, _, __, ___)
  local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
  if SecurityCommonUtils.IsTeamDeathMatchInBattle() then
    return
  end
  if not Game:IsClassOf(uDeadCharacter, ASTExtraPlayerCharacter) then
    return
  end
  local nUID = tonumber(uDeadCharacter.PlayerUID)
  if not nUID then
    return
  end
  if not self._tSuspiciousPlayerSet[nUID] then
    FormatLog("not suspicious player")
    return
  end
  if self._tDeathSentFlag[nUID] then
    return
  end
  self._tDeathSentFlag[nUID] = true
  NetUtil.SendPacket(MsgToLobby.hawkeye_suspicious_player_death, nUID)
  FormatLog("nUID=%s", nUID)
end

function DSHawkEyePatrolSubsystem:IsExitedPlayerWantNextPatrol(nUID)
  nUID = tonumber(nUID)
  if not nUID then
    FormatLog("invalid nUID")
    return
  end
  local bIsExitedPlayerWantNextPatrol = false
  if self._tWantNextPatrolPlayerSet[nUID] then
    bIsExitedPlayerWantNextPatrol = true
  end
  FormatLog("bIsExitedPlayerWantNextPatrol=%s", bIsExitedPlayerWantNextPatrol)
  return bIsExitedPlayerWantNextPatrol
end

local class = require("class")
local SubsystemBase = require("GameLua.GameCore.Module.Subsystem.SubsystemBase")
return class(SubsystemBase, nil, DSHawkEyePatrolSubsystem)
