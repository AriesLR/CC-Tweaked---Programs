local CHANNEL = 9000
local lift = peripheral.find("create_elevator")
local modem = peripheral.find("modem")

if not lift then error("Create Elevator peripheral not found!") end
if not modem then error("Ender Modem not found!") end

local lastFloor = nil

while true do
    -- getNearestFloor() returns a table as its first return value
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