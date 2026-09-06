local CHANNEL = 9000

local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)
monitor.setTextScale(2)

-- Detect or Prompt for Floor ID
local myFloor = nil
if fs.exists("floor.txt") then
    local file = fs.open("floor.txt", "r")
    myFloor = file.readLine()
    file.close()
else
    print("-----------------------------------")
    print("FIRST TIME SETUP: What floor is this?")
    io.write("Floor Name/Number: ")
    myFloor = read()
    
    local file = fs.open("floor.txt", "w")
    file.write(myFloor)
    file.close()
    print("Saved to floor.txt!")
end

local currentElevatorFloor = "--"
local isMoving = false

local function drawDisplay()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("THIS FLOOR: " .. myFloor)
    
    monitor.setCursorPos(1, 3)
    monitor.setTextColor(colors.white)
    monitor.write("ELEVATOR: ")
    
    if isMoving then
        monitor.setTextColor(colors.yellow)
    else
        monitor.setTextColor(colors.lime)
    end
    monitor.write(tostring(currentElevatorFloor))
    
    monitor.setCursorPos(1, 5)
    if tostring(currentElevatorFloor) == tostring(myFloor) and not isMoving then
        -- Elevator is already here
        monitor.setBackgroundColor(colors.gray)
        monitor.setTextColor(colors.white)
        monitor.write(" [ HERE ] ")
    else
        -- Call button
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        monitor.write(" [ CALL ELEVATOR ] ")
    end
    
    -- Reset background color
    monitor.setBackgroundColor(colors.black)
end

drawDisplay()

while true do
    local event, side, x, y, message = os.pullEvent()
    
    -- Handle Modem Data Broadcasts
    if event == "modem_message" and side == CHANNEL and type(y) == "table" then
        currentElevatorFloor = y.floor or "--"
        isMoving = y.moving or false
        drawDisplay()
        
    -- Handle Monitor Touch Events
    elseif event == "monitor_touch" then
        if y == 5 then
            -- Send Call Command to the Elevator Computer over Modem
            modem.transmit(CHANNEL, CHANNEL, { 
                action = "call", 
                targetFloor = myFloor 
            })
            
            -- Feedback Flash
            monitor.setCursorPos(1, 5)
            monitor.setBackgroundColor(colors.lime)
            monitor.setTextColor(colors.black)
            monitor.write(" [ CALLING... ] ")
            sleep(0.5)
            drawDisplay()
        end
    end
end