local CHANNEL = 9000

local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

-- Set scale for 1x3 monitors
monitor.setTextScale(1)
local w, h = monitor.getSize()

-- Read/Set Local Floor Identity
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
local isMoving = false

local function drawDisplay()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    -- Line 1: Header / Title
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.gray)
    monitor.write("ELEVATOR")
    
    -- Carousel Rendering (Line 2 to 5)
    -- Display range around the elevator's current position
    local numCurr = tonumber(currentFloor) or 1
    local startF = math.max(1, numCurr - 1)
    local endF = math.min(18, numCurr + 1)
    
    monitor.setCursorPos(1, 3)
    monitor.setTextColor(colors.gray)
    monitor.write("FL: ")
    
    for f = startF, endF do
        if tostring(f) == tostring(currentFloor) then
            if isMoving then
                monitor.setTextColor(colors.orange)
            else
                monitor.setTextColor(colors.lime)
            end
        else
            monitor.setTextColor(colors.red)
        end
        monitor.write("[" .. f .. "] ")
    end

    -- Bottom Section: CALL BUTTON
    local btnY = h - 1
    monitor.setCursorPos(1, btnY)
    
    if tostring(currentFloor) == tostring(myFloor) and not isMoving then
        monitor.setBackgroundColor(colors.gray)
        monitor.setTextColor(colors.white)
        monitor.write("   [ HERE ]   ")
    else
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        monitor.write(" [ CALL LIFT ] ")
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
        local btnY = h - 1
        -- Touch detected on call button row
        if y >= btnY then
            modem.transmit(CHANNEL, CHANNEL, { 
                action = "call", 
                targetFloor = myFloor 
            })
            
            -- Feedback flash
            monitor.setCursorPos(1, btnY)
            monitor.setBackgroundColor(colors.lime)
            monitor.setTextColor(colors.black)
            monitor.write(" [ CALLING.. ] ")
            sleep(0.4)
            drawDisplay()
        end
    end
end