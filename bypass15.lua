local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local FormatLog = FuncUtil.FormatLog
local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
local nInspectorBroadcastCDTipsID = 666026
local HawkEyeReportWindow = {}

function HawkEyeReportWindow:RegistEvents()
  FormatLog("regist event")
  self:AddOnClickedEventByControl(self.UIRoot.Button_2, self._OnClickHide, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self._OnClickSubmit, self)
  self._LoopGridReason:SetRefreshItemCallback(self._OnRefreshReasonItem, self)
  self._LoopGridReason:AddItemWidgetChildEvent("Button_6", "OnClicked", self._OnClickReasonItem, self)
  self._LoopGridReason:AddItemWidgetChildEvent("Button_7", "OnClicked", self._OnClickReasonItem, self)
  self:AddControlEventByControl(self.UIRoot.CheckBox_0, "OnCheckStateChanged", self._OnCheckStateChanged, self)
end

function HawkEyeReportWindow:OnInitialize()
  FormatLog("on initialize")
  self._LoopGridReason = self:InitScrollBox(self.UIRoot.LoopScrollGrid_0)
  self._SelectedReasonSet = {}
  self.nInspectorBroadcastCount = -1
  self.nMaxInspectorBroadcastCount = 3
  self.bIsBroadcastEnabled = false
  self.bBroadcastChecked = false
  FormatLog("on initialize bBroadcastChecked false")
end

function HawkEyeReportWindow:OnShow()
  FormatLog("on show")
  HawkEyeReportWindow.__super.OnShow(self)
  self:_RefreshWindow()
end

function HawkEyeReportWindow:_OnClickHide()
  FormatLog("on click hide")
  self:PlayAudio(sound_config.click_v1)
  self:Hide()
end

function HawkEyeReportWindow:OnAndroidBack()
  FormatLog("android back")
  self:PlayAudio(sound_config.click_v1)
  self:Hide()
end

function HawkEyeReportWindow:_RefreshWindow()
  FormatLog()
  self:_RefreshSubmitButton()
  self:_RefreshReasonPanel()
  self:_RefreshBroadCastPanel()
  self:_SetLocalizationText()
end

function HawkEyeReportWindow:_SetLocalizationText()
  FormatLog()
  self.UIRoot.TextBlock_4:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  self.UIRoot.TextBlock_0:SetText(LocUtil.GetLocalizeResStr(36662))
  self.UIRoot.TextBlock_39:SetText(LocUtil.GetLocalizeResStr(36664))
  self.UIRoot.TextBlock_41:SetText(LocUtil.GetLocalizeResStr(36664))
  self.UIRoot.TextBlock_63:SetText(LocUtil.GetLocalizeResStr(36665))
  self.UIRoot.Common_Popup_Large_UIBP.Title:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  self.UIRoot.Common_Popup_Large_UIBP.Title:SetText(LocUtil.GetLocalizeResStr(36661))
  self.UIRoot.Common_Popup_Large_UIBP.Button_Help:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  if self.UIRoot.TextBlock_0 then
    self.UIRoot.TextBlock_0:SetText(LocUtil.GetLocalizeResStr(49267))
  end
end

function HawkEyeReportWindow:_RefreshSubmitButton()
  FormatLog()
  local nButtonVisibility = UEnums.ESlateVisibility.Hidden
  local bIsButtonEnabled = false
  if #self:_GetSelectedReasonAsArray() > 0 then
    bIsButtonEnabled = true
  end
  if bIsButtonEnabled then
    nButtonVisibility = UEnums.ESlateVisibility.Visible
  end
  self.UIRoot.Button_0:SetWidgetVisibility(nButtonVisibility)
end

function HawkEyeReportWindow:_RefreshReasonPanel()
  FormatLog()
  self.UIRoot.VerticalBox_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  local ComplaintConfig = require("client.slua.umg.complaint.complaint_config")
  local nAbnormalSoundSubCode = ComplaintConfig.EComplaintSubReasonType.AbnormalSound
  local tCheatedReasonArray = ComplaintConfig.GetSubReasonConfig("Cheated")
  local tReasonArray = {}
  for _, tReason in ipairs(tCheatedReasonArray) do
    if tonumber(tReason.subCode) ~= nAbnormalSoundSubCode then
      table.insert(tReasonArray, tReason)
    end
  end
  local tHawkEyeReasonArray = ComplaintConfig.GetSubReasonConfig("HawkEye")
  if tHawkEyeReasonArray then
    for _, tReason in ipairs(tHawkEyeReasonArray) do
      table.insert(tReasonArray, tReason)
    end
  end
  self._LoopGridReason:SetData(tReasonArray)
  self._LoopGridReason:RefreshAllItems()
end

function HawkEyeReportWindow:_RefreshBroadCastPanel()
  FormatLog()
  local tClientHawkEyePatrolSubsystem = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
  if tClientHawkEyePatrolSubsystem then
    self.bIsBroadcastEnabled = tClientHawkEyePatrolSubsystem:CanInspectorBroadcast()
    self.nInspectorBroadcastCount = tClientHawkEyePatrolSubsystem:GetInspectorBroadcastCount()
    self.nMaxInspectorBroadcastCount = tClientHawkEyePatrolSubsystem:GetMaxInspectorBroadcastCount()
    FormatLog("bIsBroadcastEnabled[%s] nInspectorBroadcastCount[%s] nMaxInspectorBroadcastCount[%s]", self.bIsBroadcastEnabled, self.nInspectorBroadcastCount, self.nMaxInspectorBroadcastCount)
  else
    FormatLog("invalid tClientHawkEyePatrolSubsystem")
  end
  local UIRoot = self.UIRoot
  local CheckBox = UIRoot.CheckBox_0
  local WidgetSwitcher = UIRoot.WidgetSwitcher_0
  if self.nInspectorBroadcastCount >= 0 then
    CheckBox:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    WidgetSwitcher:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    CheckBox:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    WidgetSwitcher:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local WidgetSwitcherText = LocUtil.LocalizeResFormat(180006, self.nInspectorBroadcastCount, self.nMaxInspectorBroadcastCount)
  if self.bIsBroadcastEnabled then
    WidgetSwitcher:SetActiveWidgetIndex(1)
    UIRoot.UTRichTextBlock_1:SetText(WidgetSwitcherText)
  else
    WidgetSwitcher:SetActiveWidgetIndex(0)
    UIRoot.UTRichTextBlock_0:SetText(WidgetSwitcherText)
  end
  CheckBox:SetIsChecked(self.bBroadcastChecked)
end

function HawkEyeReportWindow:_OnClickSubmit()
  FormatLog("on click submit")
  self:PlayAudio(sound_config.click_v1)
  self:Hide()
  
  local function _OnClickMatchNextPatrol()
    FormatLog("on click match next patrol")
    SubsystemMgr:Get("ClientHawkEyePatrolSubsystem"):WantMatchNextPatrol()
  end
  
  local function _OnClickExitWatching()
    FormatLog("on click exit watching")
    SubsystemMgr:Get("ClientHawkEyePatrolSubsystem"):ReturnLobbyAndOpenH5()
  end
  
  local function _OnClickSubmitReport()
    local tReportReasonArray = self:_GetSelectedReasonAsArray()
    local tClientHawkEyePatrolSubsystem = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
    if not tClientHawkEyePatrolSubsystem then
      FormatLog("invalid tClientHawkEyePatrolSubsystem")
      return
    end
    local bInspectorBroadcast = self.UIRoot.CheckBox_0:IsChecked()
    if bInspectorBroadcast then
      local nRemainSec = tClientHawkEyePatrolSubsystem:GetInspectorBroadcastCDRemainSec()
      if 0 < nRemainSec then
        FormatLog("inspector broadcast still in CD, remain[%s]s", nRemainSec)
        IngameTipsTools.BattleNormalTipsByTextID(nInspectorBroadcastCDTipsID, nRemainSec)
        return
      end
    end
    local UIUtil = require("client.common.ui_util")
    local WatchGame_UIBP_UIRoot = UIUtil.GetWidgetByName("watchgame", "WatchGame_UIBP")
    if WatchGame_UIBP_UIRoot and WatchGame_UIBP_UIRoot.Button_OpenHawkEyeReport then
      WatchGame_UIBP_UIRoot.Button_OpenHawkEyeReport:SetIsEnabled(false)
    end
    local ComplaintConfig = require("client.slua.umg.complaint.complaint_config")
    local nUnfairCooperationSubCode = ComplaintConfig.EComplaintSubReasonType.UnfairCooperation
    local tExtraMainReason
    local tFilteredReportReasonArray = {}
    for _, nReasonCode in ipairs(tReportReasonArray) do
      if nReasonCode == nUnfairCooperationSubCode then
        tExtraMainReason = {
          ComplaintConfig.EComplaintReasonType.TEAMUP
        }
      else
        table.insert(tFilteredReportReasonArray, nReasonCode)
      end
    end
    tClientHawkEyePatrolSubsystem:SendReportTLog(tFilteredReportReasonArray, bInspectorBroadcast, tExtraMainReason)
    tClientHawkEyePatrolSubsystem:ReportCheat(bInspectorBroadcast)
    if bInspectorBroadcast then
      self.nInspectorBroadcastCount = self.nInspectorBroadcastCount + 1
      FormatLog("update nInspectorBroadcastCount[%s]", self.nInspectorBroadcastCount)
    end
    FormatLog("on click submit report")
  end
  
  local function _OnClickLastStep()
    FormatLog("on click last step")
    UIManager.ShowUI(UIManager.UI_Config_InGame.HawkEyeReportWindow)
  end
  
  local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
  IngameTipsTools.ShowMsgBox(IngameTipsTools.MSGBOX_SHOW_TYPE_TWO, nil, LocUtil.GetLocalizeResStr(36666), _OnClickSubmitReport, _OnClickLastStep, nil, LocUtil.GetLocalizeResStr(4142), {androidCallback = _OnClickLastStep})
end

function HawkEyeReportWindow:_OnRefreshReasonItem(uWidget, nIndex)
  local tData = self._LoopGridReason:GetItemData(nIndex)
  local nReasonCode = tonumber(tData.subCode)
  if not nReasonCode then
    return
  end
  uWidget.TextBlock_38:SetText(tData.subReaName)
  uWidget.TextBlock_40:SetText(tData.subReaName)
  self:_ToggleReasonSelection(uWidget, self._SelectedReasonSet[nReasonCode])
end

function HawkEyeReportWindow:_ToggleReasonSelection(uWidget, bIsWantSelect)
  local nActiveWidgetIndex = 0
  if bIsWantSelect then
    nActiveWidgetIndex = 1
  end
  uWidget.WidgetSwitcher_3:SetActiveWidgetIndex(nActiveWidgetIndex)
end

function HawkEyeReportWindow:_OnClickReasonItem(uWidget, nIndex)
  self:PlayAudio(sound_config.click_v1)
  local nReasonCode = tonumber(self._LoopGridReason:GetItemData(nIndex).subCode)
  if not nReasonCode then
    return
  end
  if self._SelectedReasonSet[nReasonCode] then
    self._SelectedReasonSet[nReasonCode] = nil
  else
    self._SelectedReasonSet[nReasonCode] = true
  end
  self:_ToggleReasonSelection(uWidget, self._SelectedReasonSet[nReasonCode])
  FormatLog("on click reason item, nIndex=%s, nReasonCode=%s", nIndex, nReasonCode)
  self:_RefreshWindow()
end

function HawkEyeReportWindow:_OnCheckStateChanged(bChecked)
  self.bBroadcastChecked = bChecked
  FormatLog("_OnCheckStateChanged bBroadcastChecked %s", self.bBroadcastChecked)
  if bChecked and self.nInspectorBroadcastCount >= self.nMaxInspectorBroadcastCount then
    FormatLog("nInspectorBroadcastCount[%s] >= nMaxInspectorBroadcastCount[%s]", self.nInspectorBroadcastCount, self.nMaxInspectorBroadcastCount)
    self.UIRoot.CheckBox_0:SetIsChecked(false)
    IngameTipsTools.BattleNormalTipsByTextID(180007)
    self.bBroadcastChecked = false
    FormatLog("_OnCheckStateChanged invalid count bBroadcastChecked %s", self.bBroadcastChecked)
  end
end

function HawkEyeReportWindow:_GetSelectedReasonAsArray()
  local tReasonArray = {}
  for nReasonCode, bIsSelected in pairs(self._SelectedReasonSet) do
    if bIsSelected then
      table.insert(tReasonArray, nReasonCode)
    end
  end
  return tReasonArray
end

local class = require("class")
local object = require("client.slua_ui_framework.base")
return class(object, nil, HawkEyeReportWindow)
