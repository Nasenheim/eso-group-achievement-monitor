GroupAchievementMonitor = GroupAchievementMonitor or {}
local GAM = GroupAchievementMonitor

GAM.name = "GroupAchievementMonitor"
GAM.slashCommand = "/gam"

GAM.selfPlayerName = GetDisplayName()

GAM.SUBMISSION_TYPES = {
    MANUAL = 1,
    AUTO = 2
}

function GAM.OnChatMessage(eventId, channelType, fromName, text, isCustomerService, fromDisplayName)
    d("New Chat Message.")
end

function GAM.AcceptAchievementManually(playerEntry)
    playerEntry.linkedAchievement = GAM.CreateLinkedAchievement(GAM.SUBMISSION_TYPES.MANUAL)
    GAM.gui.UpdateAchievementLabel(playerEntry)
end

function GAM.RejectAchievementManually(playerEntry)
    playerEntry.linkedAchievement = nil
    GAM.gui.UpdateAchievementLabel(playerEntry)
end

function GAM.CreateLinkedAchievement(submissionType)
    return {
        submissionType = submissionType
    }
end

function GAM.CreatePlayerEntry(playerName)
    return {
        playerName = playerName,
        linkedAchievement = nil,
        guiHandle = nil
    }
end

function GAM.AddPlayerEntry(playerName)
    local newPlayerEntry = GAM.CreatePlayerEntry(playerName)

    GAM.gui.AddPlayerEntry(newPlayerEntry)

    GAM.playerList[playerName] = newPlayerEntry
end

function GAM.ProcessSlashCommand()
    if GAM.gui.IsMainWindowOpen() then
        GAM.gui.CloseMainWindow()
    else
        GAM.gui.OpenMainWindow()
    end
end

function GAM.Init()
    GAM.playerList = {}

    SLASH_COMMANDS[GAM.slashCommand] = GAM.ProcessSlashCommand

    EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_CHAT_MESSAGE_CHANNEL, GAM.OnChatMessage)
end

function GAM.OnAddOnLoaded(event, addonName)
    if (addonName ~= GAM.name) then return end

    GAM.Init()
    GAM.gui.Init()

    GAM.AddPlayerEntry(GAM.selfPlayerName)

    EVENT_MANAGER:UnregisterForEvent(GAM.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_ADD_ON_LOADED, GAM.OnAddOnLoaded)
