Enterlocal function DisableHawkEye()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubsystemMgr then return end
        local hawkEye = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
        if not hawkEye then return end

        hawkEye.IsDuringHawkEyePatrol             = function() return false end
        hawkEye.HasReported                        = function() return false end
        hawkEye.HasShownWatchEndedTips             = function() return false end
        hawkEye.CheckShowReportedTips              = function() return false end
        hawkEye.CanInspectorBroadcast              = function() return false end
        hawkEye.GetForbidNextPatrolRemainingTimeInSeconds = function() return 0 end
        hawkEye.GetInspectorBroadcastCount         = function() return 0 end
        hawkEye.GetMaxInspectorBroadcastCount      = function() return 0 end
        hawkEye.ReportCheat                        = function() end
        hawkEye.SendReportTLog                     = function() end
        hawkEye.RequestImprison                    = function() end
        hawkEye.ExitWatching                       = function() end
        hawkEye.WantMatchNextPatrol                = function() end
        hawkEye.ShowWatchEndedTips                 = function() end
        hawkEye.TryShowReportedTips                = function() end
        hawkEye._OnHawkSync                        = function() end
        hawkEye._OnHawkReportSuccess               = function() end
        hawkEye._OnRecvInspectorBroadcastCount     = function() end
        hawkEye._OnInspectorBroadcastResult        = function() end
        hawkEye._OnPlayerKilledOtherPlayer         = function() end
        hawkEye._CollectBeWatchedPlayerInfo        = function() end
        hawkEye._InitHawkEyePatrolSubsystem        = function() end
        hawkEye.InitHawkEyePatrolSubsystem         = function() end
        hawkEye._StartFrameUIRefreshTimer          = function() end
        hawkEye._StartHideUITimer                  = function() end
        hawkEye._StartShowDistanceUITimer          = function() end
        hawkEye._StartCloseBattleEndedTipsTimer    = function() end
        hawkEye._StartBattleTimeUsageTimer         = function() end
        hawkEye._StartQuitVoiceRoomTimer           = function() end
        hawkEye._StartExitGameTimer                = function() end

        if hawkEye._nInitializeTimerID then
            Game:ClearTimer(hawkEye._nInitializeTimerID)
            hawkEye._nInitializeTimerID = nil
        end

        local timers = {
            "_nFrameUIRefreshTimerID","_nHideUITimerID",
            "_nShowDistanceUITimerID","_nCloseBattleEndedTipsTimerID",
            "_nBattleTimeUsageTimerID","_nQuitVoiceRoomTimerID",
            "_nExitGameTimerID","_NextPatrolOvertimeTimerID",
        }
        for _, t in ipairs(timers) do
            if hawkEye[t] then
                pcall(function() Game:ClearTimer(hawkEye[t]) end)
                hawkEye[t] = nil
            end
        end
    end)
end

pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if IsValid(pc) then
        pc:AddGameTimer(6.0, false, DisableHawkEye)
    end
end)
