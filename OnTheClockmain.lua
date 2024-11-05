-- The verbose and frequent nature of messages is only for debugging. Release versions will contain less messages if I continue development. 
local AddonFrame = CreateFrame("Frame")

-- Default idle time (in seconds)
local MAX_IDLE_TIME = 30  
local idleTime = 0

-- Function to check inactivity and teleport if needed
local function CheckInactivity()
    -- Check if the player is in an instance, delves excluded
    local inInstance, instanceType = IsInInstance()

    if inInstance then
        if idleTime >= MAX_IDLE_TIME then
            if C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
                print("Currently in a delve; teleportation will not be performed.")
                return
            end
            
            -- Handle different instance types
            if instanceType == "pvp" or instanceType == "arena" then
                LeaveBattlefield()
            elseif instanceType == "party" or instanceType == "raid" then
                print("Leaving party or raid to exit dungeon.")
                C_PartyInfo.LeaveParty()
            elseif instanceType == "scenario" then
                print("In a scenario; skipping teleportation.")
            else
                print("Unknown instance type; unable to teleport.")
            end
        end
    else
        idleTime = 0
    end
end

-- Reset idle time on player action
local function ResetIdleTimer()
    idleTime = 0
end

-- Slash command to change idle time
SLASH_SETIDLETIME1 = "/setidle"
SlashCmdList["SETIDLETIME"] = function(msg)
    local newTime = tonumber(msg)
    if newTime and newTime > 0 then
        MAX_IDLE_TIME = newTime
        print("Idle time set to " .. MAX_IDLE_TIME .. " seconds.")
    else
        print("Please enter a valid number of seconds.")
    end
end

-- OnUpdate function to increment idle time
AddonFrame:SetScript("OnUpdate", function(self, elapsed)
    idleTime = idleTime + elapsed
    CheckInactivity()
end)

-- Registering events to reset idle time and check instance status
AddonFrame:RegisterEvent("PLAYER_STARTED_MOVING")
AddonFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
AddonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

AddonFrame:SetScript("OnEvent", function(self, event)
    ResetIdleTimer()
    if event == "PLAYER_ENTERING_WORLD" then
        -- Debugging output to check instance status, will probably do away with in release
        local inInstance, instanceType = IsInInstance()
        print("Entered world: In Instance? " .. tostring(inInstance) .. " Type: " .. tostring(instanceType))
    end
end)

-- Add error handling
local function SafeCheck()
    local success, err = pcall(CheckInactivity)
    if not success then
        print("Error in CheckInactivity: " .. err)
    end
end

AddonFrame:SetScript("OnUpdate", function(self, elapsed)
    idleTime = idleTime + elapsed
    SafeCheck()  -- Use safe check to handle any errors gracefully
end)
