local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local function transmitLoop()
    local lastFloor = nil
    while true do
        local floorData = lift.getNearestFloor()
        
        if type(floorData) == "table" and floorData.name then
            local floorName = floorData.name
            
            if floorName ~= lastFloor then
                modem.transmit(CHANNEL, CHANNEL, { 
                    floor = floorName,
                    moving = lift.isMoving()
                })
                lastFloor = floorName
            end
        end
        
        sleep(0.1)
    end
end

local function listenForCalls()
    while true do
        local _, _, sendChannel, _, message = os.pullEvent("modem_message")
        if sendChannel == CHANNEL and type(message) == "table" and message.action == "call" then
            if message.targetFloor then
                lift.callToFloor(tostring(message.targetFloor))
            end
        end
    end
end

parallel.waitForAny(transmitLoop, listenForCalls)