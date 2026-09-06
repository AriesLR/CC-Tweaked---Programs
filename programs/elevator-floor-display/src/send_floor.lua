local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

local lastFloor = nil

while true do
    -- getNearestFloor() returns the nearest floor name/identifier
    local floorName, floorY = lift.getNearestFloor()
    
    if floorName and floorName ~= lastFloor then
        modem.transmit(CHANNEL, CHANNEL, { 
            floor = floorName,
            moving = lift.isMoving(),
            state = lift.getState()
        })
        lastFloor = floorName
    end
    
    sleep(0.1)
end