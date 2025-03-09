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

    GAMGui.playerEntryHandles = {}
    for i = 1, GAM.MAX_PLAYER_COUNT do
        local newPlayerEntryHandle = {}
        GAMGui.playerEntryHandles[i] = newPlayerEntryHandle

        newPlayerEntryHandle.control = CreateControlFromVirtual(
            "$(parent)Entry" .. i,
            GAMGui.playerList,
            "GroupAchievementMonitorPlayerListEntryTemplate"
        )
        if i > 1 then
            newPlayerEntryHandle.control:ClearAnchors()
            newPlayerEntryHandle.control:SetAnchor(TOP, GAMGui.playerEntryHandles[i - 1].control, BOTTOM, 0, 5)
        end

        newPlayerEntryHandle.display = GetControl(newPlayerEntryHandle.control, "Display")

        newPlayerEntryHandle.nameLabel = GetControl(newPlayerEntryHandle.display, "Name")
        newPlayerEntryHandle.nameLabel:SetText("@PlayerName")

        newPlayerEntryHandle.achievementLabel = GetControl(newPlayerEntryHandle.display, "Achievement")
        newPlayerEntryHandle.achievementLabel:SetText("→ Achievement")

        newPlayerEntryHandle.edit = GetControl(newPlayerEntryHandle.control, "Edit")

        newPlayerEntryHandle.editAcceptManuallyButton = GetControl(newPlayerEntryHandle.edit, "AcceptManually")
        newPlayerEntryHandle.editRejectManuallyButton = GetControl(newPlayerEntryHandle.edit, "RejectManually")
    end
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

function GAMGui.SyncPlayerEntries()
    for _, playerEntry in pairs(GAM.playerList) do
        GAMGui.UpdatePlayerEntry(playerEntry)
    end

    for index = GAM.groupSize + 1, GAM.MAX_PLAYER_COUNT do
        local playerEntryHandle = GAMGui.playerEntryHandles[index]

        playerEntryHandle.control:SetHidden(true)
    end
end

function GAMGui.UpdatePlayerEntry(playerEntry)
    local playerEntryHandle = GAMGui.GetPlayerEntryHandle(playerEntry)

    playerEntryHandle.control:SetHidden(false)

    playerEntryHandle.nameLabel:SetText(playerEntry.playerName)

    local newAchievementLabelString = GAMGui.GetAchievementLabelString(playerEntry)
    playerEntryHandle.achievementLabel:SetText(newAchievementLabelString)

    playerEntryHandle.editAcceptManuallyButton:SetHandler(
        "OnMouseUp",
        function(self)
            GAM.AcceptAchievementManually(playerEntry)
        end,
        GAMGui.name
    )
    playerEntryHandle.editRejectManuallyButton:SetHandler(
        "OnMouseUp",
        function(self)
            GAM.RejectAchievementManually(playerEntry)
        end,
        GAMGui.name
    )
end

function GAMGui.HidePlayerEntryHandle(playerEntry)
    local playerEntryHandle = GAMGui.GetPlayerEntryHandle(playerEntry)
    playerEntryHandle.control:SetHidden(true)
end

function GAMGui.GetPlayerEntryHandle(playerEntry)
    return GAMGui.playerEntryHandles[playerEntry.index]
end

function GAMGui.UpdateAchievementLabel(playerEntry)
    local playerEntryHandle = GAMGui.GetPlayerEntryHandle(playerEntry)

    local newLabelString = GAMGui.GetAchievementLabelString(playerEntry)
    playerEntryHandle.achievementLabel:SetText(newLabelString)
end

function GAMGui.GetAchievementLabelString(playerEntry)
    local newLabelString = "→ "

    if not playerEntry.linkedAchievement then
        newLabelString = newLabelString .. "No achievement linked."
    elseif playerEntry.linkedAchievement.submissionType == GAM.SUBMISSION_TYPES.AUTO then
        newLabelString = newLabelString .. "Auto"
    elseif playerEntry.linkedAchievement.submissionType == GAM.SUBMISSION_TYPES.MANUAL then
        newLabelString = newLabelString .. "Manually accepted."
    end

    return newLabelString
end
