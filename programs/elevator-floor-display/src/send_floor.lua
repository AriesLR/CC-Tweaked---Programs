local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local function transmitLoop()
    local lastFloor = nil
    local lastMoving = nil
    
    while true do
        local floorData = lift.getNearestFloor()
        
        if type(floorData) == "table" and floorData.name then
            local floorName = floorData.name
            
            local movingState = false
            if lift.getSpeed then
                movingState = math.abs(lift.getSpeed()) > 0
            else
                movingState = lift.isMoving()
            end
            
            if floorName ~= lastFloor or movingState ~= lastMoving then
                modem.transmit(CHANNEL, CHANNEL, { 
                    floor = floorName,
                    moving = movingState
                })
                lastFloor = floorName
                lastMoving = movingState
            end
        end
        
        sleep(0.1)
    end
end

local function listenForCalls()
    while true do
        local _, _, sendChannel, _, message = os.pullEvent("modem_message")
        if sendChannel == CHANNEL and type(message) == "table" and message.action == "call" then
            if message.targetFloor and lift.callToFloor then
                lift.callToFloor(tostring(message.targetFloor))
            end
        end
    end
end

parallel.waitForAny(transmitLoop, listenForCalls)