local CHANNEL = 9000
local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

monitor.setTextScale(1.5)
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

local function drawDisplay(floor, isMoving)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("FLOOR")
    
    monitor.setCursorPos(1, 2)
    if isMoving then
        monitor.setTextColor(colors.yellow)
    else
        monitor.setTextColor(colors.lime)
    end
    monitor.write(tostring(floor))
    
    local isHere = (tostring(floor) == tostring(myFloor)) and not isMoving
    
    local btnBg = isHere and colors.gray or colors.cyan
    local btnText = isHere and colors.lightGray or colors.black
    local btnLabel = isHere and " HERE " or " CALL "
    
    for lineY = termH - 1, termH do
        monitor.setCursorPos(1, lineY)
        monitor.setBackgroundColor(btnBg)
        monitor.setTextColor(btnText)
        
        if lineY == termH - 1 then
            monitor.write(btnLabel)
        else
            monitor.write(string.rep(" ", termW))
        end
    end
    
    monitor.setBackgroundColor(colors.black)
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
        
        for lineY = termH - 1, termH do
            monitor.setCursorPos(1, lineY)
            monitor.setBackgroundColor(colors.lime)
            monitor.setTextColor(colors.black)
            if lineY == termH - 1 then
                monitor.write(" WAIT ")
            else
                monitor.write(string.rep(" ", termW))
            end
        end
        
        sleep(0.4)
        drawDisplay(currentFloor, isElevatorMoving)
    end
end