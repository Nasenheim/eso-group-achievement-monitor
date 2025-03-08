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

function GAM.acceptAchievementManually(playerEntry)
    playerEntry.linkedAchievement = GAM.createLinkedAchievement(GAM.SUBMISSION_TYPES.MANUAL)
    GAM.gui.updateAchievementLabel(playerEntry)
end

function GAM.rejectAchievementManually(playerEntry)
    playerEntry.linkedAchievement = nil
    GAM.gui.updateAchievementLabel(playerEntry)
end

function GAM.createLinkedAchievement(submissionType)
    return {
        submissionType = submissionType
    }
end

function GAM.createPlayerEntry(playerName)
    return {
        playerName = playerName,
        linkedAchievement = nil,
        guiHandle = nil
    }
end

function GAM.addPlayerEntry(playerName)
    local newPlayerEntry = GAM.createPlayerEntry(playerName)

    GAM.gui.addPlayerEntry(newPlayerEntry)

    GAM.playerList[playerName] = newPlayerEntry
end

function GAM.ProcessSlashCommand()
    if GAM.gui.isMainWindowOpen() then
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

    GAM.addPlayerEntry(GAM.selfPlayerName)

    EVENT_MANAGER:UnregisterForEvent(GAM.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_ADD_ON_LOADED, GAM.OnAddOnLoaded)
