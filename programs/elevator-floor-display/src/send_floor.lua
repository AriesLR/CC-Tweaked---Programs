local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local lastFloor = nil

while true do
    -- Check for incoming modem call requests or broadcast updates
    local event, side, sendChannel, replyChannel, message = os.pullEvent()
    
    if event == "modem_message" and sendChannel == CHANNEL and type(message) == "table" then
        -- Handle elevator call from a floor monitor
        if message.action == "call" and message.targetFloor then
            if lift.callToFloor then
                lift.callToFloor(tostring(message.targetFloor))
            end
        end
    end
    
    -- Periodic Floor Broadcast
    local floorData = lift.getNearestFloor()
    if type(floorData) == "table" and floorData.name then
        local floorName = floorData.name
        
        modem.transmit(CHANNEL, CHANNEL, { 
            floor = floorName,
            moving = lift.isMoving()
        })
    end
end