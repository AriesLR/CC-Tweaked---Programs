local CHANNEL = 9000

local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

monitor.setTextScale(1)
local monitorWidth, monitorHeight = monitor.getSize()

local myFloor = nil
if fs.exists("floor.txt") then
    local file = fs.open("floor.txt", "r")
    myFloor = file.readLine()
    file.close()
else
    print("What floor is this computer on?")
    io.write("Floor Name/Number (1-18): ")
    myFloor = read()
    local file = fs.open("floor.txt", "w")
    file.write(myFloor)
    file.close()
end

local currentFloor = "--"
local isMoving = false

local function drawDisplay()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("FLOORS (1-18)")
    
    local startY = 3
    local currentY = startY
    local currentX = 1
    
    for f = 1, 18 do
        local strF = tostring(f)
        
        if strF == tostring(currentFloor) then
            if isMoving then
                monitor.setTextColor(colors.orange)
            else
                monitor.setTextColor(colors.lime)
            end
        else
            monitor.setTextColor(colors.red)
        end
        
        local itemText = string.format("%2d ", f)
        if currentX + #itemText - 1 > monitorWidth then
            currentX = 1
            currentY = currentY + 1
        end
        
        if currentY < monitorHeight - 1 then
            monitor.setCursorPos(currentX, currentY)
            monitor.write(itemText)
            currentX = currentX + #itemText
        end
    end

    local btnY = monitorHeight
    monitor.setCursorPos(1, btnY)
    
    if tostring(currentFloor) == tostring(myFloor) and not isMoving then
        monitor.setBackgroundColor(colors.gray)
        monitor.setTextColor(colors.white)
        monitor.write(string.rep(" ", math.floor((monitorWidth - 8) / 2)) .. "[ HERE ]")
    else
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        monitor.write(string.rep(" ", math.floor((monitorWidth - 8) / 2)) .. "[ CALL ]")
    end
    
    monitor.setBackgroundColor(colors.black)
end

drawDisplay()

while true do
    local event, side, x, y, message = os.pullEvent()
    
    if event == "modem_message" and side == CHANNEL and type(y) == "table" then
        currentFloor = y.floor or "--"
        isMoving = y.moving or false
        drawDisplay()
        
    elseif event == "monitor_touch" then
        if y >= monitorHeight - 1 then
            modem.transmit(CHANNEL, CHANNEL, { 
                action = "call", 
                targetFloor = myFloor 
            })
            
            monitor.setCursorPos(1, monitorHeight)
            monitor.setBackgroundColor(colors.lime)
            monitor.setTextColor(colors.black)
            monitor.write(string.rep(" ", math.floor((monitorWidth - 11) / 2)) .. "[ CALLING ]")
            sleep(0.4)
            drawDisplay()
        end
    end
end