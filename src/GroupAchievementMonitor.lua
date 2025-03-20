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

GAM.ACHIEVEMENT_LINK_MATCH_STRING = "|H1:achievement:(%d+):(%d+):(%d+)|h(.-)|h"
GAM.ACHIEVEMENT_LINK_FORMAT_STRING = "|H1:achievement:<<1>>:<<2>>:<<3>>|h|h"

function GAM.ExtractLinkedAchievementsFromText(text)
    local achievements = {}
    local achievementCount = 0

    for achievementId, progress, timestamp in string.gmatch(
        text,
        GAM.ACHIEVEMENT_LINK_MATCH_STRING
    ) do
        local newAchievementId = tonumber(achievementId)
        local newProgress = tonumber(progress)
        local newTimestamp = tonumber(timestamp)

        local newAchievementLink = GAM.CreateAchievementLink(
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

        GAM.gui.UpdatePlayerEntry(playerEntry)
    end
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

    GAM.gui.UpdatePlayerEntry(playerEntry)
end

function GAM.CreateAchievementLink(achievementId, progress, timestamp)
    local linkString = zo_strformat(
        GAM.ACHIEVEMENT_LINK_FORMAT_STRING,
        achievementId,
        progress,
        timestamp
    )

    local date, time = FormatAchievementLinkTimestamp(tostring(timestamp))

    return {
        linkString = linkString,
        achievementId = achievementId,
        progress = progress,
        timestamp = timestamp,
        date = date,
        time = time
    }
end

function GAM.CreateLinkedAchievement(submissionType, achievementLink)
    local name = nil
    local isCompleted = false
    if achievementLink then
        name = GetAchievementInfo(achievementLink.achievementId)
        isCompleted = achievementLink.progress > 0 and achievementLink.timestamp > 0
    end

    return {
        name = name,
        submission = {
            type = submissionType,
            createdAt = os.clock()
        },
        achievementLink = achievementLink,
        isValid = submissionType == GAM.SUBMISSION_TYPES.MANUAL or
            (submissionType == GAM.SUBMISSION_TYPES.AUTO and isCompleted)
    }
end

function GAM.CreatePlayerEntry(index, unitTag)
    local displayName = GetUnitDisplayName(unitTag)
    local isChampion = IsUnitChampion(unitTag)

    local level
    if isChampion then
        level = GetUnitChampionPoints(unitTag)
    else
        level = GetUnitLevel(unitTag)
    end

    return {
        index = index,
        playerName = displayName,
        isChampion = isChampion,
        level = level,
        selectedLinkedAchievement = nil,
        linkedAchievements = {},
        linkedAchievementsCount = 0
    }
end

function GAM.AddGroupMember(unitTag)
    local newPlayerEntry = GAM.CreatePlayerEntry(GAM.groupSize, unitTag)
    GAM.playerList[newPlayerEntry.playerName] = newPlayerEntry

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

-- This function needs to be called with zo_callLater() because some values might not be queryable
-- yet with GroupUnitTags.
function GAM.SyncGroupMembers()
    GAM.playerList = {}
    GAM.groupSize = GetGroupSize()

    if GAM.groupSize < GAM.MIN_PLAYER_COUNT then
        GAM.groupSize = 1
        GAM.AddGroupMember('player')
    else
        local entryIndex = 1
        for index = 1, GAM.MAX_PLAYER_COUNT do
            local unitTag = GetGroupUnitTagByIndex(index)

            if unitTag then
                local newPlayerEntry = GAM.CreatePlayerEntry(entryIndex, unitTag)
                GAM.playerList[newPlayerEntry.playerName] = newPlayerEntry

                entryIndex = entryIndex + 1
            end
        end
    end

    GAM.gui.SyncPlayerEntries()
end

function GAM.OnGroupMemberJoined(eventCode, memberCharacterName, memberDisplayName, isLocalPlayer)
    if memberDisplayName == GAM.selfPlayerName then
        zo_callLater(GAM.SyncGroupMembers, 50)
    else
        GAM.groupSize = GAM.groupSize + 1
        for index = 1, GAM.MAX_PLAYER_COUNT do
            local unitTag = GetGroupUnitTagByIndex(index)

            if unitTag then
                local displayName = GetUnitDisplayName(unitTag)
                if memberDisplayName == displayName then
                    GAM.AddGroupMember(unitTag)
                    break
                end
            end
        end
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
        zo_callLater(GAM.SyncGroupMembers, 50)
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
