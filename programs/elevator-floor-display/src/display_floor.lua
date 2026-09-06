local CHANNEL = 9000

local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

monitor.setTextScale(2)
local w, h = monitor.getSize()

local myFloor = nil
if fs.exists("floor.txt") then
    local file = fs.open("floor.txt", "r")
    myFloor = file.readLine()
    file.close()
else
    print("--------------------------------")
    print("What floor is this computer on?")
    io.write("Floor Number (1-18): ")
    myFloor = read()
    local file = fs.open("floor.txt", "w")
    file.write(myFloor)
    file.close()
end

local currentElevatorFloor = "--"

local function drawDisplay()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("FLOOR")
    
    monitor.setCursorPos(1, 2)
    if tostring(currentElevatorFloor) == tostring(myFloor) then
        monitor.setTextColor(colors.lime)
    else
        monitor.setTextColor(colors.orange)
    end
    monitor.write(tostring(currentElevatorFloor))
    
    local btnY = h
    monitor.setCursorPos(1, btnY)
    
    if tostring(currentElevatorFloor) == tostring(myFloor) then
        monitor.setBackgroundColor(colors.gray)
        monitor.setTextColor(colors.white)
        monitor.write("[HERE]")
    else
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        monitor.write("[CALL]")
    end
    
    monitor.setBackgroundColor(colors.black)
end

drawDisplay()

while true do
    local event, side, x, y, message = os.pullEvent()

    if event == "modem_message" and side == CHANNEL and type(y) == "table" then
        currentElevatorFloor = y.floor or "--"
        drawDisplay()
        
    elseif event == "monitor_touch" then
        if y >= h - 1 then
            modem.transmit(CHANNEL, CHANNEL, { 
                action = "call", 
                targetFloor = myFloor 
            })
            
            monitor.setCursorPos(1, h)
            monitor.setBackgroundColor(colors.lime)
            monitor.setTextColor(colors.black)
            monitor.write("[WAIT]")
            sleep(0.3)
            drawDisplay()
        end
    end
end