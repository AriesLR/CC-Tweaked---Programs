local CHANNEL = 9000

-- Local Source Block directly attached to this computer
local source = peripheral.find("create_source") or peripheral.find("source")
local modem = peripheral.find("modem")

if not source then error("Source Block not found next to this computer!") end
if not modem then error("Ender/Wireless Modem not found!") end

local lastFloor = nil

while true do
    local currentFloor = nil
    
    -- Query floor from CC:C Bridge Source Block
    if source.getCurrentFloor then
        currentFloor = source.getCurrentFloor()
    elseif source.getDetail then
        local detail = source.getDetail()
        currentFloor = detail and detail.floor
    end

    -- Broadcast wirelessly when floor changes
    if currentFloor and currentFloor ~= lastFloor then
        modem.transmit(CHANNEL, CHANNEL, { floor = currentFloor })
        lastFloor = currentFloor
    end

    sleep(0.2)
end