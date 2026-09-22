Enterlocal sTitleName = "_sTitle"
local sMessageName = "_sMessage"
local sRemainingPatrolName = "_sRemainingPatrol"
local HawkEyeNextPatrolWindow = {}

function HawkEyeNextPatrolWindow:OnShow()
  HawkEyeNextPatrolWindow.__super.OnShow(self)
  local tConstructParams = self:GetConstructParams()
  local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
  SecurityCommonUtils.SetStringMember(self, tConstructParams.sTitle, sTitleName, {ClearValue = nil})
  SecurityCommonUtils.SetStringMember(self, tConstructParams.sMessage, sMessageName, {ClearValue = nil})
  SecurityCommonUtils.SetStringMember(self, tConstructParams.sRemainingPatrol, sRemainingPatrolName, {ClearValue = nil})
  self:_SetLocalizationText()
end

function HawkEyeNextPatrolWindow:_SetLocalizationText()
  if self[sTitleName] then
    self.UIRoot.TextBlock_Title:SetText(self[sTitleName])
  end
  if self[sMessageName] then
    self.UIRoot.TextBlock_Message:SetText(self[sMessageName])
  end
  if self[sRemainingPatrolName] then
    self.UIRoot.UTRichTextBlock_0:SetText(self[sRemainingPatrolName])
  end
end

function HawkEyeNextPatrolWindow:GetConfirmButtonName()
  return "Button_Confirm1"
end

function HawkEyeNextPatrolWindow:GetCancelButtonName()
  return "Button_Cancel"
end

function HawkEyeNextPatrolWindow:GetConfirmTextBlockName()
  return "TextBlock_Confirm1"
end

function HawkEyeNextPatrolWindow:GetCancelTextBlockName()
  return "TextBlock_Cancel"
end

function HawkEyeNextPatrolWindow:GetConfirmCountDownTextBlockName()
  return "TextBlock_Confirm2"
end

function HawkEyeNextPatrolWindow:OnBeginForbidConfirmButton()
  FuncUtil.FormatLog()
  self.UIRoot.WidgetSwitcher_Confirm:SetActiveWidgetIndex(1)
end

function HawkEyeNextPatrolWindow:OnEndForbidConfirmButton()
  FuncUtil.FormatLog()
  self.UIRoot.WidgetSwitcher_Confirm:SetActiveWidgetIndex(0)
end

local class = require("class")
local object = require("GameLua.Mod.BaseMod.Client.Security.UI.AbstractConfirmCancelWindow")
return class(object, nil, HawkEyeNextPatrolWindow)
