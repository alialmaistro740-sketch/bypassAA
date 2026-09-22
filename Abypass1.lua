local ReplayReportHandler = {}

function ReplayReportHandler:ctor(ReplayRecordManager)
  print(bWriteLog and "ReplayReportHandler:ctor", ReplayRecordManager)
  self.ReplayRecordManager = ReplayRecordManager
  self.PlayerKeyToUIStateInfo = {}
  self.PlayerKeyToRescueBtnTraceInfo = {}
end

function ReplayReportHandler:SetCustomMessageData(PlayerKey, DataName, Str)
  local uGameState = slua_GameFrontendHUD:GetGameState()
  if slua.isValid(uGameState) and slua.isValid(uGameState.ReplayRecordManager) then
    uGameState.ReplayRecordManager:SetCustomMessageData(PlayerKey, DataName, Str)
  end
end

function ReplayReportHandler:AddCustomMessageData(PlayerKey, DataName, Str)
  local uGameState = slua_GameFrontendHUD:GetGameState()
  if slua.isValid(uGameState) and slua.isValid(uGameState.ReplayRecordManager) then
    uGameState.ReplayRecordManager:AddCustomMessageData(PlayerKey, DataName, Str)
  end
end

function ReplayReportHandler:GetCustomMessageDataInStr(PlayerKey, DataName)
  local uGameState = slua_GameFrontendHUD:GetGameState()
  if slua.isValid(uGameState) and slua.isValid(uGameState.ReplayRecordManager) then
    return uGameState.ReplayRecordManager:GetCustomMessageDataInStr(PlayerKey, DataName)
  end
end

local UIStateNames = {
  [0] = "NormalFightingState",
  [1] = "BattleResultState",
  [2] = "PetSpectatorState",
  [3] = "SpectatorOrReplayStateMachine",
  [4] = "TeamShowState",
  [5] = "VehicleStateMachine",
  [6] = "JumpShowState",
  [7] = "LifterControlState",
  [8] = "DeadState",
  [9] = "DeadStateForNoHideUI",
  [10] = "SwimState",
  [11] = "DivingState",
  [12] = "ParachuteState",
  [13] = "DeadGhostState",
  [14] = "DummyState",
  [15] = "NormalSpectatorState",
  [16] = "HawkEyeSpectatorState"
}

function ReplayReportHandler:GetPlayerUIStateInfo(PlayerKey)
  return self.PlayerKeyToUIStateInfo[PlayerKey]
end

function ReplayReportHandler:OnReportUIState(PlayerKey, Array)
  if Array:Num() < 3 then
    return
  end
  if not self.PlayerKeyToUIStateInfo[PlayerKey] then
    self.PlayerKeyToUIStateInfo[PlayerKey] = {}
  end
  self.PlayerKeyToUIStateInfo[PlayerKey].OldState = Array:Get(0) and UIStateNames[Array:Get(0)] or "Empty"
  self.PlayerKeyToUIStateInfo[PlayerKey].CurrentState = Array:Get(1) and UIStateNames[Array:Get(1)] or "Empty"
  self.PlayerKeyToUIStateInfo[PlayerKey].bReconnect = Array:Get(2) and Array:Get(2) or "0"
  local DebugStr = "OldState: " .. self.PlayerKeyToUIStateInfo[PlayerKey].OldState .. " CurrentState: " .. self.PlayerKeyToUIStateInfo[PlayerKey].CurrentState .. " bReconnect: " .. self.PlayerKeyToUIStateInfo[PlayerKey].bReconnect
  self:SetCustomMessageData(PlayerKey, "UIState", DebugStr)
end

function ReplayReportHandler:OnReceiveBattleResult(PlayerKey, Array)
  if Array:Num() < 4 then
    return
  end
  local isTeamResult = Array:Get(0) and Array:Get(0) or "0"
  local Reason = Array:Get(1) and Array:Get(1) or "0"
  local is_last_survive = Array:Get(2) and Array:Get(2) or "0"
  local IsSolo = Array:Get(3) and Array:Get(3) or "0"
  local DebugStr = "isTeamResult: " .. isTeamResult .. " Reason: " .. Reason .. " is_last_survive: " .. is_last_survive .. " IsSolo: " .. IsSolo
  self:AddCustomMessageData(PlayerKey, "ReceiveBattleResult", DebugStr)
end

function ReplayReportHandler:OnUpdateBattleResultPeriod(PlayerKey, Array)
  if Array:Num() < 2 then
    return
  end
  local CurResultProcessIndex = Array:Get(0)
  local startSuc = Array:Get(1)
  local DebugStr = "CurResultProcessIndex: " .. CurResultProcessIndex .. " startSuc: " .. startSuc
  self:AddCustomMessageData(PlayerKey, "UpdateBattleResultPeriod", DebugStr)
end

function ReplayReportHandler:OnReportAvatarNetData(PlayerKey, Array)
  local Num = Array:Num()
  if Num <= 0 or Num % 3 ~= 0 then
    return
  end
  local DebugStr = "SlotSyncData:"
  for i = 0, Num - 1, 3 do
    local SlotID = Array:Get(i)
    local ItemID = Array:Get(i + 1)
    local HideState = Array:Get(i + 2)
    DebugStr = DebugStr .. " [SlotID:" .. tostring(SlotID) .. " ItemID:" .. tostring(ItemID) .. " HideState:" .. tostring(HideState) .. "]"
  end
  self:SetCustomMessageData(PlayerKey, "AvatarNetData", DebugStr)
end

local ControlRotationChangeSourceNames = {
  [0] = "YawInput",
  [1] = "PitchInput",
  [2] = "ControlRotation",
  [3] = "Unknown"
}

function ReplayReportHandler:OnReportControlRotationSuddenChange(PlayerKey, Array)
  if Array:Num() < 3 then
    return
  end
  local ChangeSourceID = Array:Get(0)
  local DeltaValue = Array:Get(1)
  local TimestampSeconds = Array:Get(2)
  local ChangeSourceName = ControlRotationChangeSourceNames[math.floor(ChangeSourceID or 3)] or "Unknown"
  local DebugStr = string.format("[Source:%s Delta:%.2f Ts:%.2f]", ChangeSourceName, DeltaValue or 0, TimestampSeconds or 0)
  self:AddCustomMessageData(PlayerKey, "ControlRotationSuddenChange", DebugStr)
end

function ReplayReportHandler:OnReportForbiddenMoveException(PlayerKey, Array)
  if Array:Num() < 9 then
    return
  end
  local CurrentStates = math.floor(Array:Get(0) or 0)
  local MoveableBits = math.floor(Array:Get(1) or 0)
  local ClientStateType = math.floor(Array:Get(2) or 0)
  local FollowState = math.floor(Array:Get(3) or 0)
  local MovementMode = math.floor(Array:Get(4) or 0)
  local SpeedRate = Array:Get(5) or 0
  local MaxWalkSpeed = Array:Get(6) or 0
  local VelocitySize = Array:Get(7) or 0
  local TimestampSeconds = Array:Get(8) or 0
  
  local function Bit(nValue, nBit)
    return math.floor(nValue / 2 ^ nBit) % 2 == 1 and 1 or 0
  end
  
  local DebugStr = string.format("[States:%d Move:%d Pickup:%d Air:%d Tick:%d IgnoreIn:%d Land:%d RepMove:%d PawnKnown:%d CST:%d Follow:%d MM:%d SR:%.2f MaxWS:%.2f Vel:%.2f Ts:%.2f]", CurrentStates, Bit(MoveableBits, 0), Bit(MoveableBits, 1), Bit(MoveableBits, 2), Bit(MoveableBits, 3), Bit(MoveableBits, 4), Bit(MoveableBits, 5), Bit(MoveableBits, 6), Bit(MoveableBits, 7), ClientStateType, FollowState, MovementMode, SpeedRate, MaxWalkSpeed, VelocitySize, TimestampSeconds)
  self:AddCustomMessageData(PlayerKey, "ForbiddenMoveException", DebugStr)
end

local ParachuteAvgSpeedSideNames = {
  [0] = "Client",
  [1] = "DS"
}

function ReplayReportHandler:OnReportParachuteAvgSpeed(PlayerKey, Array)
  if Array:Num() < 10 then
    return
  end
  local Side = math.floor(Array:Get(0) or 0)
  local AvgVelX = Array:Get(1) or 0
  local AvgVelY = Array:Get(2) or 0
  local AvgVelZ = Array:Get(3) or 0
  local AvgSpeed = Array:Get(4) or 0
  local LimitF = Array:Get(5) or 0
  local LimitR = Array:Get(6) or 0
  local LimitFall = Array:Get(7) or 0
  local ParachuteState = math.floor(Array:Get(8) or 0)
  local TimestampSeconds = Array:Get(9) or 0
  local CurVelX = Array:Num() >= 14 and (Array:Get(10) or 0) or 0
  local CurVelY = Array:Num() >= 14 and (Array:Get(11) or 0) or 0
  local CurVelZ = Array:Num() >= 14 and (Array:Get(12) or 0) or 0
  local CurSpeed = Array:Num() >= 14 and (Array:Get(13) or 0) or 0
  local SideName = ParachuteAvgSpeedSideNames[Side] or "Unknown"
  local DebugStr = string.format("[Side:%s AvgVel:(%.1f,%.1f,%.1f) AvgSpeed:%.1f CurVel:(%.1f,%.1f,%.1f) CurSpeed:%.1f Limit(F/R/Fall):%.1f/%.1f/%.1f PState:%d Ts:%.2f]", SideName, AvgVelX, AvgVelY, AvgVelZ, AvgSpeed, CurVelX, CurVelY, CurVelZ, CurSpeed, LimitF, LimitR, LimitFall, ParachuteState, TimestampSeconds)
  self:AddCustomMessageData(PlayerKey, "ParachuteAvgSpeedOverLimit", DebugStr)
end

local SpectatorScopeReasonNames = {
  [1] = "EntityMissing",
  [2] = "MeshComponentMissing",
  [3] = "MeshComponentUnregistered",
  [4] = "MeshAssetMissing",
  [5] = "SyncDataMissingOrMismatch",
  [6] = "WeaponPartsCutoffApplied",
  [7] = "EntityItemMismatch"
}

function ReplayReportHandler:OnReportNaNPositionEvent(PlayerKey, Array)
  if Array:Num() < 19 then
    return
  end
  
  local function FmtScalar(v)
    if v == math.huge or v == -math.huge or v ~= v then
      return "NaN"
    end
    return string.format("%.2f", v or 0)
  end
  
  local function FmtVec(x, y, z)
    return string.format("(%s,%s,%s)", FmtScalar(x), FmtScalar(y), FmtScalar(z))
  end
  
  local NaNPlayerKey = math.floor(Array:Get(0) or 0)
  local EventTypeID = math.floor(Array:Get(1) or 1)
  local bResolved = math.floor(Array:Get(2) or 0)
  local LocStr = FmtVec(Array:Get(3), Array:Get(4), Array:Get(5))
  local VelStr = FmtVec(Array:Get(6), Array:Get(7), Array:Get(8))
  local RepLocStr = FmtVec(Array:Get(9), Array:Get(10), Array:Get(11))
  local LastValidStr = FmtVec(Array:Get(12), Array:Get(13), Array:Get(14))
  local MovementMode = math.floor(Array:Get(15) or -1)
  local CustomMovementMode = math.floor(Array:Get(16) or -1)
  local ParachuteState = math.floor(Array:Get(17) or -1)
  local TimestampSeconds = Array:Get(18) or 0
  local EventTypeName = "Unrecoverable"
  if EventTypeID == 0 then
    EventTypeName = "Recovered"
  elseif EventTypeID == 1 then
    EventTypeName = "Unrecoverable"
  else
    EventTypeName = "Unknown(" .. tostring(EventTypeID) .. ")"
  end
  local DebugStr = string.format("[NaNPK:%d Event:%s Resolved:%d Loc:%s Vel:%s RepLoc:%s LastValid:%s MM:%d CMM:%d PState:%d Ts:%.2f]", NaNPlayerKey, EventTypeName, bResolved, LocStr, VelStr, RepLocStr, LastValidStr, MovementMode, CustomMovementMode, ParachuteState, TimestampSeconds)
  local Tag = "NaNPositionEvent:" .. EventTypeName
  self:AddCustomMessageData(PlayerKey, Tag, DebugStr)
end

function ReplayReportHandler:OnReportSpectatorScopeAvatarInconsistency(PlayerKey, Array)
  if Array:Num() ~= 6 then
    return
  end
  local Meta = math.floor(Array:Get(0) or 0)
  local Version = Meta % 16
  local Reason = math.floor(Meta / 16) % 16
  local SlotID = math.floor(Meta / 256) % 256
  local StateFlags = math.floor(Meta / 65536) % 65536
  local bValidSlot = SlotID == 4 or SlotID == 10
  if not (Version == 1 and SpectatorScopeReasonNames[Reason]) or not bValidSlot then
    return
  end
  local ObservedPlayerKey = math.floor(Array:Get(1) or 0)
  local WeaponID = math.floor(Array:Get(2) or 0)
  local ExpectedScopeID = math.floor(Array:Get(3) or 0)
  local SynDataItemID = math.floor(Array:Get(4) or 0)
  local EntityItemID = math.floor(Array:Get(5) or 0)
  local DebugStr = string.format("[Reporter:%d Target:%d Weapon:%d Slot:%d Reason:%s Flags:%d Expected:%d Syn:%d Entity:%d]", PlayerKey, ObservedPlayerKey, WeaponID, SlotID, SpectatorScopeReasonNames[Reason], StateFlags, ExpectedScopeID, SynDataItemID, EntityItemID)
  self:AddCustomMessageData(PlayerKey, "SpectatorScopeAvatarInconsistency", DebugStr)
end

local FPP_UNKNOWN = 255
local FPPAnimEventNames = {
  [0] = "PerspChanged",
  [1] = "PerspChangedSim",
  [2] = "CamModeChange",
  [3] = "PerspChangedDelay",
  [4] = "PerspChangedSimDelay",
  [5] = "CamModeChangeDelay",
  [6] = "Manual"
}
local FPPCameraModeNames = {
  [0] = "Normal",
  [1] = "FPP",
  [2] = "Aim",
  [3] = "Plane"
}
local FPPMeshUpdateFlagNames = {
  [0] = "AlwaysTick+Refresh",
  [1] = "AlwaysTickPose",
  [2] = "MontageOnlyWhenHidden",
  [3] = "OnlyWhenRendered"
}

local function FPPBoolStr(v)
  if v == FPP_UNKNOWN or v == nil then
    return "?"
  end
  return v ~= 0 and "Y" or "N"
end

local function FPPEnumStr(tbl, v)
  if v == FPP_UNKNOWN or v == nil then
    return "?"
  end
  return tbl[v] or "#" .. tostring(v)
end

function ReplayReportHandler:OnReportFPPAnimState(PlayerKey, Array)
  local Num = Array:Num()
  if Num < 10 then
    return
  end
  local EventID = Array:Get(0)
  local bIsFPP = Array:Get(1)
  local CamMode = Array:Get(2)
  local CharIsFPP = Array:Get(3)
  local CharNetFPP = Array:Get(4)
  local MainFPPMode = Array:Get(5)
  local HasFPPInst = Array:Get(6)
  local FPPShouldUpd = Array:Get(7)
  local TPPShouldUpd = Array:Get(8)
  local Mismatch = Array:Get(9)
  local SkillLock = 10 < Num and Array:Get(10) or FPP_UNKNOWN
  local EmoteLock = 11 < Num and Array:Get(11) or FPP_UNKNOWN
  local AllowSwitchPP = 12 < Num and Array:Get(12) or FPP_UNKNOWN
  local CamCooling = 13 < Num and Array:Get(13) or FPP_UNKNOWN
  local MeshFlag = 14 < Num and Array:Get(14) or FPP_UNKNOWN
  local Rendered = 15 < Num and Array:Get(15) or FPP_UNKNOWN
  local EveryFrame = 16 < Num and Array:Get(16) or FPP_UNKNOWN
  local HitTag = Mismatch == 1 and "[!!!BUG] " or ""
  local DebugStr = string.format("%s[FPPAnim] Evt:%s" .. " | Perspective{ IsFPP:%s Cam:%s CharIsFPP:%s NetFPP:%s }" .. " | AnimGate{ MainSelFPP:%s HasFPPInst:%s FPPUpd:%s TPPUpd:%s Mismatch:%s }" .. " | SwitchGate{ SkillLock:%s EmoteLock:%s AllowPP:%s CamCooling:%s }" .. " | Render{ MeshFlag:%s Rendered:%s EveryFrame:%s }", HitTag, FPPEnumStr(FPPAnimEventNames, EventID), FPPBoolStr(bIsFPP), FPPEnumStr(FPPCameraModeNames, CamMode), FPPBoolStr(CharIsFPP), FPPBoolStr(CharNetFPP), FPPBoolStr(MainFPPMode), FPPBoolStr(HasFPPInst), FPPBoolStr(FPPShouldUpd), FPPBoolStr(TPPShouldUpd), FPPBoolStr(Mismatch), FPPBoolStr(SkillLock), FPPBoolStr(EmoteLock), FPPBoolStr(AllowSwitchPP), FPPBoolStr(CamCooling), FPPEnumStr(FPPMeshUpdateFlagNames, MeshFlag), FPPBoolStr(Rendered), FPPBoolStr(EveryFrame))
  self:SetCustomMessageData(PlayerKey, "FPPAnimState", DebugStr)
  print(bWriteLog and "ReplayReportHandler:OnReportFPPAnimState " .. DebugStr)
end

local RescueBtnTraceEventNames = {
  [1] = "OnSearchAvailableChanged",
  [2] = "OnAllSearchAvailableChanged",
  [3] = "OnCompositeSearchAvailableChanged",
  [4] = "OnCanRescueOtherChange",
  [5] = "OnCanCarryAnyActorChange",
  [6] = "NewOnCanRescueOtherEvent",
  [7] = "NewShowCarryBackBtn",
  [8] = "NewHideCarryBackBtn",
  [9] = "SetBtnVisibleFlag_BtnRescue",
  [10] = "SetBtnVisibleFlag_ButtonPutDown",
  [11] = "Tick_RescueConditionMet",
  [12] = "Tick_CarryConditionMet",
  [13] = "Tick_Started",
  [14] = "Tick_Stopped",
  [15] = "Tick_Heartbeat"
}

function ReplayReportHandler:GetPlayerRescueBtnTraceInfo(PlayerKey)
  return self.PlayerKeyToRescueBtnTraceInfo[PlayerKey]
end

function ReplayReportHandler:OnReportRescueBtnTrace(PlayerKey, Array)
  local Num = Array:Num()
  if Num < 1 then
    return
  end
  local EventType = Array:Get(0)
  local EventName = RescueBtnTraceEventNames[EventType] or "Unknown_" .. tostring(EventType)
  if not self.PlayerKeyToRescueBtnTraceInfo[PlayerKey] then
    self.PlayerKeyToRescueBtnTraceInfo[PlayerKey] = {
      LatestEvents = {}
    }
  end
  local TraceInfo = self.PlayerKeyToRescueBtnTraceInfo[PlayerKey]
  local RawData = {}
  for i = 0, Num - 1 do
    RawData[#RawData + 1] = Array:Get(i)
  end
  TraceInfo.LatestEvents[EventType] = {EventName = EventName, RawData = RawData}
  local DebugStr = "Event:"
  for i = 2, #RawData do
    DebugStr = DebugStr .. " P" .. tostring(i - 1) .. "=" .. tostring(RawData[i])
  end
  self:AddCustomMessageData(PlayerKey, "RescueBtnTrace", DebugStr)
end

local class = require("class")
local object = require("object")
local CReplayReportHandler = class(object, nil, ReplayReportHandler)
return CReplayReportHandler
