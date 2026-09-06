local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

modem.open(CHANNEL)

local timerID = os.startTimer(0.1)

while true do
    local event, p1, p2, p3, message = os.pullEventRaw()
    
    if event == "modem_message" and p1 == CHANNEL and type(message) == "table" then
        if message.action == "call" and message.targetFloor then
            if lift.callToFloor then
                lift.callToFloor(tostring(message.targetFloor))
            end
        end

    elseif event == "timer" and p1 == timerID then
        local floorData = lift.getNearestFloor()
        local isMoving = lift.isMoving()
        
        if type(floorData) == "table" and floorData.name then
            modem.transmit(CHANNEL, CHANNEL, { 
                floor = tostring(floorData.name),
                moving = isMoving
            })
        end
        
        timerID = os.startTimer(0.1)
    end
end