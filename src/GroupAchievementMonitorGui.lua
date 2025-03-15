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

        newPlayerEntryHandle.controlBackdrop = GetControl(newPlayerEntryHandle.control, "BG")

        newPlayerEntryHandle.display = GetControl(newPlayerEntryHandle.control, "Display")

        newPlayerEntryHandle.playerNameLabel = GetControl(newPlayerEntryHandle.display, "PlayerName")
        newPlayerEntryHandle.playerNameLabel:SetText("@PlayerName")

        newPlayerEntryHandle.achievementLabel = GetControl(newPlayerEntryHandle.display, "Achievement")
        newPlayerEntryHandle.achievementLabel:SetText("Achievement")

        newPlayerEntryHandle.achievementDateLabel = GetControl(newPlayerEntryHandle.display, "AchievementDate")
        newPlayerEntryHandle.achievementDateLabel:SetText("Date, Time")

        newPlayerEntryHandle.edit = GetControl(newPlayerEntryHandle.control, "Edit")

        newPlayerEntryHandle.editAcceptManuallyButton = GetControl(newPlayerEntryHandle.edit, "AcceptManually")
        newPlayerEntryHandle.editRejectManuallyButton = GetControl(newPlayerEntryHandle.edit, "RejectManually")

        GAMGui.SetupPlayerListEntryHandleEventHandlers(newPlayerEntryHandle)
    end
end

function GAMGui.SetupPlayerListEntryHandleEventHandlers(playerEntryHandle)
    GAMGui.SetupPlayerListEntryHandleHoverHandlers(playerEntryHandle.control, playerEntryHandle)

    GAMGui.SetupPlayerListEntryHandleHoverHandlers(playerEntryHandle.achievementLabel, playerEntryHandle)

    GAMGui.SetupPlayerListEntryHandleHoverHandlers(playerEntryHandle.editAcceptManuallyButton, playerEntryHandle)
    GAMGui.SetupPlayerListEntryHandleHoverHandlers(playerEntryHandle.editRejectManuallyButton, playerEntryHandle)
end

function GAMGui.SetupPlayerListEntryHandleHoverHandlers(control, playerEntryHandle)
    control:SetHandler("OnMouseEnter", function(self)
        playerEntryHandle.controlBackdrop:SetHidden(false)
    end, GAMGui.name)
    control:SetHandler("OnMouseExit", function(self)
        playerEntryHandle.controlBackdrop:SetHidden(true)
    end, GAMGui.name)
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

    playerEntryHandle.playerNameLabel:SetText(playerEntry.playerName)

    local newAchievementLabelString = GAMGui.GetAchievementLabelString(playerEntry)
    playerEntryHandle.achievementLabel:SetText(newAchievementLabelString)

    local newAchievementDateLabelString = GAMGui.GetAchievementDateLabelString(playerEntry)
    playerEntryHandle.achievementDateLabel:SetText(newAchievementDateLabelString)

    GAMGui.UpdatePlayerEntryHandleEventHandlers(playerEntry, playerEntryHandle)
end

function GAMGui.UpdatePlayerEntryHandleEventHandlers(playerEntry, playerEntryHandle)
    playerEntryHandle.editAcceptManuallyButton:SetHandler("OnMouseUp", function(self)
        GAM.AcceptAchievementManually(playerEntry)
    end, GAMGui.name)
    playerEntryHandle.editRejectManuallyButton:SetHandler("OnMouseUp", function(self)
        GAM.RejectAchievementManually(playerEntry)
    end, GAMGui.name)

    local selectedLinkedAchievement = playerEntry.selectedLinkedAchievement
    if selectedLinkedAchievement and selectedLinkedAchievement.submission.type == GAM.SUBMISSION_TYPES.AUTO then
        playerEntryHandle.achievementLabel:SetHandler(
            "OnMouseUp",
            function(self, button, ...)
                d("# Link mouse up")
                ZO_LinkHandler_OnLinkMouseUp(
                    selectedLinkedAchievement.achievementLink.linkString,
                    button,
                    self
                )
            end,
            GAMGui.name
        )
    else
        playerEntryHandle.achievementLabel:SetHandler("OnMouseUp", nil, GAMGui.name)
    end
end

function GAMGui.HidePlayerEntryHandle(playerEntry)
    local playerEntryHandle = GAMGui.GetPlayerEntryHandle(playerEntry)
    playerEntryHandle.control:SetHidden(true)
end

function GAMGui.GetPlayerEntryHandle(playerEntry)
    return GAMGui.playerEntryHandles[playerEntry.index]
end

function GAMGui.GetAchievementLabelString(playerEntry)
    local selectedLinkedAchievement = playerEntry.selectedLinkedAchievement

    if not selectedLinkedAchievement then
        return "No achievement linked."
    elseif selectedLinkedAchievement.submission.type == GAM.SUBMISSION_TYPES.MANUAL then
        return "Manually accepted."
    elseif selectedLinkedAchievement.submission.type == GAM.SUBMISSION_TYPES.AUTO then
        return selectedLinkedAchievement.achievementLink.linkString
    end
end

function GAMGui.GetAchievementDateLabelString(playerEntry)
    local selectedLinkedAchievement = playerEntry.selectedLinkedAchievement

    if not selectedLinkedAchievement or selectedLinkedAchievement.submission.type == GAM.SUBMISSION_TYPES.MANUAL then
        return ""
    elseif selectedLinkedAchievement.submission.type == GAM.SUBMISSION_TYPES.AUTO then
        return selectedLinkedAchievement.achievementLink.date .. ", " .. selectedLinkedAchievement.achievementLink.time
    end
end
