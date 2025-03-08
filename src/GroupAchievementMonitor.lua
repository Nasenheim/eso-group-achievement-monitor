GroupAchievementMonitor = GroupAchievementMonitor or {}
local GAM = GroupAchievementMonitor

GAM.name = "GroupAchievementMonitor"
GAM.slashCommand = "/gam"

GAM.selfPlayerName = GetDisplayName()

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
end

function GAM.OnAddOnLoaded(event, addonName)
    if (addonName ~= GAM.name) then return end

    GAM.Init()
    GAM.gui.Init()

    EVENT_MANAGER:UnregisterForEvent(GAM.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_ADD_ON_LOADED, GAM.OnAddOnLoaded)
