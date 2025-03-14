GroupAchievementMonitor = GroupAchievementMonitor or {}
local GAM = GroupAchievementMonitor

GAM.name = "GroupAchievementMonitor"
GAM.slashCommand = "/gam"

GAM.selfPlayerName = GetDisplayName()
GAM.groupSize = 0

GAM.MAX_PLAYER_COUNT = 12
GAM.MIN_PLAYER_COUNT = 2
GAM.SUBMISSION_TYPES = {
    MANUAL = 1,
    AUTO = 2
}

GAM.ACHIEVEMENT_TEXT_MATCH_STRING = "|H(%d):achievement:(%d+):(%d+):(%d+)|h(.-)|h"

function GAM.ExtractLinkedAchievementsFromText(text)
    local achievements = {}
    local achievementCount = 0

    for type, achievementId, progress, timestamp in string.gmatch(
        text,
        GAM.ACHIEVEMENT_TEXT_MATCH_STRING
    ) do
        local newType = tonumber(type)
        local newAchievementId = tonumber(achievementId)
        local newProgress = tonumber(progress)
        local newTimestamp = tonumber(timestamp)

        local newAchievementLink = GAM.CreateAchievementLink(
            newType,
            newAchievementId,
            newProgress,
            newTimestamp
        )
        local newLinkedAchievement = GAM.CreateLinkedAchievement(
            GAM.SUBMISSION_TYPES.AUTO,
            newAchievementLink
        )

        achievementCount = achievementCount + 1
        achievements[achievementCount] = newLinkedAchievement
    end

    return achievements
end

function GAM.OnChatMessage(eventId, channelType, fromName, text, isCustomerService, fromDisplayName)
    d("New Chat Message.")
    local playerEntry = GAM.playerList[fromDisplayName]

    if not playerEntry then
        return
    end

    local linkedAchievements = GAM.ExtractLinkedAchievementsFromText(text)

    for _, linkedAchievement in pairs(linkedAchievements) do
        GAM.AddLinkedAchievement(playerEntry, linkedAchievement)
    end
end

function GAM.AddLinkedAchievement(playerEntry, linkedAchievement)
    playerEntry.linkedAchievementsCount = playerEntry.linkedAchievementsCount + 1
    playerEntry.linkedAchievements[playerEntry.linkedAchievementsCount] = linkedAchievement

    if linkedAchievement.isValid then
        playerEntry.selectedLinkedAchievement = linkedAchievement
    end

    GAM.gui.UpdateAchievementLabel(playerEntry)
end

function GAM.AcceptAchievementManually(playerEntry)
    local newLinkedAchievement = GAM.CreateLinkedAchievement(GAM.SUBMISSION_TYPES.MANUAL, nil)
    GAM.AddLinkedAchievement(playerEntry, newLinkedAchievement)
end

function GAM.RejectAchievementManually(playerEntry)
    for _, linkedAchievement in pairs(playerEntry.linkedAchievements) do
        linkedAchievement.isValid = false
    end

    playerEntry.selectedLinkedAchievement = nil

    GAM.gui.UpdateAchievementLabel(playerEntry)
end

function GAM.CreateAchievementLink(linkType, achievementId, progress, timestamp)
    local date, time = FormatAchievementLinkTimestamp(tostring(timestamp))

    return {
        linkType = linkType,
        achievementId = achievementId,
        progress = progress,
        timestamp = timestamp,
        date = date,
        time = time
    }
end

function GAM.CreateLinkedAchievement(submissionType, achievementLink)
    local name = nil
    if achievementLink then
        name = GetAchievementInfo(achievementLink.achievementId)
    end

    return {
        name = name,
        submission = {
            type = submissionType,
            createdAt = os.clock()
        },
        achievementLink = achievementLink,
        isValid = true
    }
end

function GAM.CreatePlayerEntry(index, playerName)
    return {
        index = index,
        playerName = playerName,
        selectedLinkedAchievement = nil,
        linkedAchievements = {},
        linkedAchievementsCount = 0
    }
end

function GAM.AddGroupMember(playerName)
    GAM.groupSize = GAM.groupSize + 1

    local newPlayerEntry = GAM.CreatePlayerEntry(GAM.groupSize, playerName)
    GAM.playerList[playerName] = newPlayerEntry

    GAM.gui.UpdatePlayerEntry(newPlayerEntry)
end

function GAM.RemoveGroupMember(playerName)
    local playerEntryToRemove = GAM.playerList[playerName]

    if not playerEntryToRemove then
        return
    end

    GAM.groupSize = GAM.groupSize - 1
    for _, playerEntry in pairs(GAM.playerList) do
        if playerEntry.index > GAM.groupSize then
            GAM.gui.HidePlayerEntryHandle(playerEntry)
        end

        if playerEntry.index > playerEntryToRemove.index then
            playerEntry.index = playerEntry.index - 1
            GAM.gui.UpdatePlayerEntry(playerEntry)
        end
    end

    GAM.playerList[playerName] = nil
end

function GAM.SyncGroupMembers()
    GAM.playerList = {}
    GAM.groupSize = GetGroupSize()

    if GAM.groupSize < GAM.MIN_PLAYER_COUNT then
        GAM.groupSize = 0
        GAM.AddGroupMember(GAM.selfPlayerName)
    else
        for index = 1, GAM.groupSize do
            local unitTag = GetGroupUnitTagByIndex(index)

            if unitTag then
                local displayName = GetUnitDisplayName(unitTag)

                local newPlayerEntry = GAM.CreatePlayerEntry(index, displayName)
                GAM.playerList[displayName] = newPlayerEntry
            else
                d("Could not find GroupUnitTag " .. index)
            end
        end
    end

    GAM.gui.SyncPlayerEntries()
end

function GAM.OnGroupMemberJoined(eventCode, memberCharacterName, memberDisplayName, isLocalPlayer)
    if memberDisplayName == GAM.selfPlayerName then
        GAM.SyncGroupMembers()
    else
        GAM.AddGroupMember(memberDisplayName)
    end
end

function GAM.OnGroupMemberLeft(
    eventCode,
    memberCharacterName,
    reason,
    isLocalPlayer,
    isLeader,
    memberDisplayName
)
    if memberDisplayName == GAM.selfPlayerName then
        GAM.SyncGroupMembers()
    else
        GAM.RemoveGroupMember(memberDisplayName)
    end
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
    -- SLASH_COMMANDS["/gam_sync"] = GAM.SyncGroupMembers

    EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_GROUP_MEMBER_JOINED, GAM.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_GROUP_MEMBER_LEFT, GAM.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_CHAT_MESSAGE_CHANNEL, GAM.OnChatMessage)
end

function GAM.OnAddOnLoaded(event, addonName)
    if (addonName ~= GAM.name) then return end

    GAM.Init()
    GAM.gui.Init()

    GAM.SyncGroupMembers()

    EVENT_MANAGER:UnregisterForEvent(GAM.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_ADD_ON_LOADED, GAM.OnAddOnLoaded)
