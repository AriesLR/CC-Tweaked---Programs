local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local function getFloorList()
    if not lift.listFloors then return nil end
    local ok, floors = pcall(lift.listFloors)
    if not ok or type(floors) ~= "table" then return nil end
    
    local list = {}
    local detectedTarget = nil
    for _, fl in pairs(floors) do
        if type(fl) == "table" and fl.name then
            local isTarget = fl.isTarget or false
            if isTarget then
                detectedTarget = tostring(fl.name)
            end
            table.insert(list, {
                name = tostring(fl.name),
                shortName = fl.shortName and tostring(fl.shortName) or tostring(fl.name),
                longName = fl.longName and tostring(fl.longName) or "",
                y = tonumber(fl.y) or 0,
                isCurrent = fl.isCurrent or false,
                isTarget = isTarget
            })
        end
    end
    return list, detectedTarget
end

local function getFloorDisplayName(nameOrObj, floorList)
    if not nameOrObj then return "--", nil end
    local rawName = type(nameOrObj) == "table" and nameOrObj.name or tostring(nameOrObj)
    local longName = type(nameOrObj) == "table" and nameOrObj.longName or nil

    if longName and tostring(longName) ~= "" then
        return tostring(longName), rawName
    end

    if floorList then
        for _, fl in ipairs(floorList) do
            if tostring(fl.name) == rawName or (fl.longName and fl.longName ~= "" and tostring(fl.longName) == rawName) then
                if fl.longName and tostring(fl.longName) ~= "" then
                    return tostring(fl.longName), tostring(fl.name)
                else
                    return tostring(fl.name), tostring(fl.name)
                end
            end
        end
    end

    return rawName, rawName
end

local function sendStatus(targetFloorOverride)
    local floorList, detectedTarget = getFloorList()
    local floorData = lift.getNearestFloor()
    
    local floorName, rawFloor = getFloorDisplayName(floorData, floorList)

    local movingState = false
    if lift.getSpeed then
        movingState = math.abs(lift.getSpeed()) > 0
    elseif lift.isMoving then
        movingState = lift.isMoving()
    end

    local rawTarget = targetFloorOverride or detectedTarget
    local displayTarget, resolvedTarget = getFloorDisplayName(rawTarget, floorList)

    modem.transmit(CHANNEL, CHANNEL, { 
        floor = floorName,
        rawFloor = rawFloor,
        moving = movingState,
        targetFloor = displayTarget,
        rawTargetFloor = resolvedTarget,
        floors = floorList
    })
    return floorName, movingState, displayTarget
end

local function transmitLoop()
    local lastFloor = nil
    local lastMoving = nil
    local lastTarget = nil
    local tickCounter = 0
    
    while true do
        local floorName, movingState, activeTarget = sendStatus()
        
        -- Broadcast on state change or periodically every ~5 seconds (50 ticks)
        tickCounter = tickCounter + 1
        if floorName ~= lastFloor or movingState ~= lastMoving or activeTarget ~= lastTarget or tickCounter >= 50 then
            lastFloor = floorName
            lastMoving = movingState
            lastTarget = activeTarget
            tickCounter = 0
        end
        
        sleep(0.1)
    end
end

local function listenForCalls()
    while true do
        local _, _, sendChannel, _, message = os.pullEvent("modem_message")
        if sendChannel == CHANNEL and type(message) == "table" then
            local isUpdate = (message.action == "update" or message == "update")
            local targetMatch = not message.target or message.target == "all" or message.target == "send"
            
            if isUpdate and targetMatch then
                print("Received update command from master.")
                local updateScript = "/alr/elevator-floor-display/update.lua"
                if fs.exists(updateScript) then
                    shell.run(updateScript)
                    sleep(1)
                    if fs.exists("/startup.lua") then
                        os.reboot()
                    end
                else
                    printError("Update script not found at " .. updateScript)
                end
            elseif message.action == "call" and message.targetFloor and lift.callToFloor then
                local floorList = getFloorList()
                local _, resolvedTarget = getFloorDisplayName(message.targetFloor, floorList)
                lift.callToFloor(tostring(resolvedTarget or message.targetFloor))
                sendStatus(tostring(resolvedTarget or message.targetFloor))
            elseif message.action == "get_floors" then
                sendStatus()
            end
        end
    end
end

parallel.waitForAny(transmitLoop, listenForCalls)