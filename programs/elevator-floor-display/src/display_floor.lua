local CHANNEL = 9000

local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)
monitor.setTextScale(3)

local function drawDisplay(floor)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("FLOOR")
    
    monitor.setCursorPos(1, 2)
    monitor.setTextColor(colors.lime)
    monitor.write(tostring(floor))
end

drawDisplay("--")

while true do
    local _, _, sendChannel, _, message = os.pullEvent("modem_message")
    
    if sendChannel == CHANNEL and type(message) == "table" and message.floor then
        drawDisplay(message.floor)
    end
end