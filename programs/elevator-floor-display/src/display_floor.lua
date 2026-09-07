local CHANNEL = 9000
local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

monitor.setTextScale(1)
local termW, termH = monitor.getSize()

local myFloor = nil
if fs.exists("floor.txt") then
    local file = fs.open("floor.txt", "r")
    myFloor = file.readLine()
    file.close()
else
    print("What floor is this computer on?")
    io.write("Floor Name/Number: ")
    myFloor = read()
    local file = fs.open("floor.txt", "w")
    file.write(myFloor)
    file.close()
end

local currentFloor = "--"
local isElevatorMoving = false

local function writeCentered(text, y, fgColor)
    monitor.setCursorPos(1, y)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(fgColor or colors.white)
    
    local str = tostring(text)
    local padding = math.floor((termW - #str) / 2)
    if padding < 0 then padding = 0 end
    
    local line = string.rep(" ", padding) .. str .. string.rep(" ", termW - #str - padding)
    monitor.write(line)
end

local function drawDisplay(floor, isMoving)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local floorColor = isMoving and colors.yellow or colors.lime
    writeCentered(floor, 2, floorColor)
    
    local isHere = (tostring(floor) == tostring(myFloor)) and not isMoving
    local btnFg = isHere and colors.gray or colors.cyan
    local btnText = isHere and "[ HERE ]" or "[ CALL ]"
    
    writeCentered(btnText, termH, btnFg)
end

drawDisplay("--", false)

while true do
    local event, p1, p2, p3, p4 = os.pullEvent()
    
    if event == "modem_message" and p2 == CHANNEL and type(p4) == "table" and p4.floor then
        currentFloor = p4.floor
        isElevatorMoving = p4.moving or false
        drawDisplay(currentFloor, isElevatorMoving)
        
    elseif event == "monitor_touch" and p3 >= termH - 1 then
        modem.transmit(CHANNEL, CHANNEL, { 
            action = "call", 
            targetFloor = myFloor 
        })
        
        writeCentered("[ WAIT ]", termH, colors.lime)
        
        sleep(0.4)
        drawDisplay(currentFloor, isElevatorMoving)
    end
end