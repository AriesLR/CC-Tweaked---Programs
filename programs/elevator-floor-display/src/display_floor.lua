local CHANNEL = 9000
local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)
monitor.setTextScale(3)

local function drawDisplay(floor, isMoving)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    -- Header
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("FLOOR")
    
    -- Floor Name / Number
    monitor.setCursorPos(1, 2)
    if isMoving then
        monitor.setTextColor(colors.yellow)
    else
        monitor.setTextColor(colors.lime)
    end
    monitor.write(tostring(floor))
end

drawDisplay("--", false)

while true do
    local _, _, sendChannel, _, message = os.pullEvent("modem_message")
    
    if sendChannel == CHANNEL and type(message) == "table" and message.floor then
        drawDisplay(message.floor, message.moving)
    end
end