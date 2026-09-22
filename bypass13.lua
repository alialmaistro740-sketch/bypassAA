local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local FormatLog = FuncUtil.FormatLog
local HawkEyeDistanceUI = {_nDistanceUIItemCount = 10}

local function _GetItemNameByIndex(nItemIndex)
  nItemIndex = tonumber(nItemIndex)
  if not nItemIndex then
    return ""
  end
  return string.format("DistanceItem_%d", nItemIndex)
end

function HawkEyeDistanceUI:OnShow()
  HawkEyeDistanceUI.__super.OnShow(self)
  self:_StartRefreshUITimer()
end

function HawkEyeDistanceUI:_IsShouldShow()
  local ClientHawkEyePatrolSubsystem = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
  if not ClientHawkEyePatrolSubsystem then
    FormatLog("invalid ClientHawkEyePatrolSubsystem")
    return false
  end
  return ClientHawkEyePatrolSubsystem:IsDuringHawkEyePatrol()
end

function HawkEyeDistanceUI:_ShowHideAccordingly()
  local bIsShouldShow = self:_IsShouldShow()
  if bIsShouldShow then
    UIManager.ShowUI(UIManager.UI_Config_InGame.HawkEyeDistanceUI)
  else
    UIManager.HideUI(UIManager.UI_Config_InGame.HawkEyeDistanceUI)
  end
  FormatLog("%s", bIsShouldShow)
  return bIsShouldShow
end

function HawkEyeDistanceUI:_StartRefreshUITimer()
  if self._nRefreshUITimerID then
    FormatLog("timer exists")
    return
  end
  self._nRefreshUITimerID = self:AddGameTimer(0.3333333333333333, true, function()
    self:_RefreshUI()
  end)
end

function HawkEyeDistanceUI:_RefreshUI()
  local ClientHawkEyePatrolSubsystem = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
  if not ClientHawkEyePatrolSubsystem then
    FormatLog("invalid ClientHawkEyePatrolSubsystem")
    return
  end
  local tBeWatchedPlayerInfo = ClientHawkEyePatrolSubsystem:GetBeWatchedPlayerInfo()
  if not tBeWatchedPlayerInfo then
    FormatLog("invalid tBeWatchedPlayerInfo")
    return
  end
  if not self:_ShowHideAccordingly() then
    return
  end
  local uMyController = slua_GameFrontendHUD:GetPlayerController()
  if not Game:IsClassOf(uMyController, ASTExtraPlayerController) then
    FormatLog("invalid uMyController")
    return
  end
  self:_InitializeUIIfNotYet()
  local uMyLocation = uMyController:GetCurPawnLocation()
  local tPlayerInfoArray = {}
  local uPlayerCharacterArray = Game:GetAllPlayerPawns()
  local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
  for _, uPlayerCharacter in pairs(uPlayerCharacterArray) do
    if slua.isValid(uPlayerCharacter) and uPlayerCharacter.TeamID ~= tBeWatchedPlayerInfo.nTeamID and SecurityCommonUtils.IsHealthStatusAlive(uPlayerCharacter.HealthStatus) then
      local uCharacterLocation = uPlayerCharacter:K2_GetActorLocation()
      if ClientHawkEyePatrolSubsystem:IsCharacterLocationShouldDraw(uMyLocation, uCharacterLocation) then
        table.insert(tPlayerInfoArray, {
          uLocation = uPlayerCharacter:GetHeadLocation(true) + FVector(100, 0, 300),
          nDistance = FVector.Dist2D(uMyLocation, uCharacterLocation)
        })
      end
    end
  end
  table.sort(tPlayerInfoArray, function(tInfo1, tInfo2)
    return tInfo1.nDistance < tInfo2.nDistance
  end)
  local nPlayerInfoArrayIndex = 1
  for nItemIndex = 1, HawkEyeDistanceUI._nDistanceUIItemCount do
    local sItemName = _GetItemNameByIndex(nItemIndex)
    local uDistanceItemUI = self.UIRoot[sItemName]
    if uDistanceItemUI then
      local tPlayerInfo = tPlayerInfoArray[nPlayerInfoArrayIndex]
      if tPlayerInfo then
        nPlayerInfoArrayIndex = nPlayerInfoArrayIndex + 1
        uDistanceItemUI:StartShow(0, tPlayerInfo.uLocation)
        uDistanceItemUI:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
      else
        uDistanceItemUI:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
      end
    end
  end
end

function HawkEyeDistanceUI:_InitializeUIIfNotYet()
  FormatLog()
  if self._bHasInitializedUI then
    FormatLog("has been initialized")
    return
  end
  self._bHasInitializedUI = true
  for nItemIndex = 1, HawkEyeDistanceUI._nDistanceUIItemCount do
    local sItemName = _GetItemNameByIndex(nItemIndex)
    local uDistanceItemUI = self.UIRoot[sItemName]
    if uDistanceItemUI then
      uDistanceItemUI:ConstructFunc()
      uDistanceItemUI:HideTipImage()
      uDistanceItemUI:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  end
end

local class = require("class")
local object = require("client.slua_ui_framework.base")
return class(object, nil, HawkEyeDistanceUI)
