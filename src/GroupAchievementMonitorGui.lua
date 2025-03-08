GroupAchievementMonitor = GroupAchievementMonitor or {}
local GAM = GroupAchievementMonitor

GAM.gui = GAM.gui or {}
local GAMGui = GAM.gui

function GAMGui.Init()
    GAMGui.name = GAM.name .. "Gui"

    GAMGui.SetupWindow()
end

function GAMGui.SetupWindow()
    GAMGui.mainWindowHeader = GetControl(GroupAchievementMonitorWindow, "Header")

    GAMGui.closeButton = GetControl(GAMGui.mainWindowHeader, "Hide")
    GAMGui.closeButton:SetHandler(
        "OnMouseUp",
        function(self)
            GAMGui.CloseMainWindow()
        end,
        GAMGui.name
    )

    GAMGui.playerList = GetControl(GroupAchievementMonitorWindow, "PlayerList")
end

function GAMGui.OpenMainWindow()
    GroupAchievementMonitorWindow:SetHidden(false)
    PlaySound(SOUNDS.DEFAULT_WINDOW_OPEN)
end

function GAMGui.CloseMainWindow()
    GroupAchievementMonitorWindow:SetHidden(true)
    PlaySound(SOUNDS.DEFAULT_WINDOW_CLOSE)
end

function GAMGui.isMainWindowOpen()
    return not GroupAchievementMonitorWindow:IsHidden()
end
