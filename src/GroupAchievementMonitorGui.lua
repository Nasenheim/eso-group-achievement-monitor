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

function GAMGui.IsMainWindowOpen()
    return not GroupAchievementMonitorWindow:IsHidden()
end

function GAMGui.AddPlayerEntry(playerEntry)
    local guiHandle = {}
    playerEntry.guiHandle = guiHandle

    guiHandle.control = CreateControlFromVirtual(
        "$(parent)PlayerEntry",
        GAMGui.playerList,
        "GroupAchievementMonitorPlayerEntryTemplate"
    )

    guiHandle.display = GetControl(guiHandle.control, "Display")

    guiHandle.nameLabel = GetControl(guiHandle.display, "Name")
    guiHandle.nameLabel:SetText(playerEntry.playerName)

    guiHandle.achievementLabel = GetControl(guiHandle.display, "Achievement")
    GAMGui.UpdateAchievementLabel(playerEntry)

    guiHandle.edit = GetControl(guiHandle.control, "Edit")

    guiHandle.editAcceptManuallyButton = GetControl(guiHandle.edit, "AcceptManually")
    guiHandle.editAcceptManuallyButton:SetHandler(
        "OnMouseUp",
        function(self)
            GAM.AcceptAchievementManually(playerEntry)
        end,
        GAMGui.name
    )
    guiHandle.editRejectManuallyButton = GetControl(guiHandle.edit, "RejectManually")
    guiHandle.editRejectManuallyButton:SetHandler(
        "OnMouseUp",
        function(self)
            GAM.RejectAchievementManually(playerEntry)
        end,
        GAMGui.name
    )
end

function GAMGui.UpdateAchievementLabel(playerEntry)
    local newLabel = "→ "

    if not playerEntry.linkedAchievement then
        newLabel = newLabel .. "No achievement linked."
    elseif playerEntry.linkedAchievement.submissionType == GAM.SUBMISSION_TYPES.AUTO then
        newLabel = newLabel .. "Auto"
    elseif playerEntry.linkedAchievement.submissionType == GAM.SUBMISSION_TYPES.MANUAL then
        newLabel = newLabel .. "Manually accepted."
    end

    playerEntry.guiHandle.achievementLabel:SetText(newLabel)
end
