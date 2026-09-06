local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local lastFloor = nil
local lastMoving = nil

-- Timer for non-blocking loop
local timerID = os.startTimer(0.1)

while true do
    local event, side, sendChannel, replyChannel, message = os.pullEvent()
    
    -- Handle incoming call requests from display monitors
    if event == "modem_message" and sendChannel == CHANNEL and type(message) == "table" then
        if message.action == "call" and message.targetFloor then
            if lift.callToFloor then
                lift.callToFloor(tostring(message.targetFloor))
            end
        end
    
    -- Non-blocking timer tick to update elevator state
    elseif event == "timer" and side == timerID then
        local floorData = lift.getNearestFloor()
        local isMoving = lift.isMoving()
        
        if type(floorData) == "table" and floorData.name then
            local floorName = floorData.name
            
            -- Broadcast updates to all monitors
            modem.transmit(CHANNEL, CHANNEL, { 
                floor = floorName,
                moving = isMoving
            })
        end
        
        -- Restart timer for next tick
        timerID = os.startTimer(0.1)
    end
end