GroupAchievementMonitor = {}

GroupAchievementMonitor.name = "GroupAchievementMonitor"
local GAM = GroupAchievementMonitor

function GAM.Init()

end

function GAM.OnAddOnLoaded(event, addonName)
    if addonName == GAM.name then
        GAM.Init()

        EVENT_MANAGER:UnregisterForEvent(GAM.name, EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent(GAM.name, EVENT_ADD_ON_LOADED, GAM.OnAddOnLoaded)