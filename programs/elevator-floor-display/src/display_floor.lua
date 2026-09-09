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
    print("Scanning for elevator floors...")
    modem.transmit(CHANNEL, CHANNEL, { action = "get_floors" })
    
    local timer = os.startTimer(1.5)
    local detectedFloors = nil
    
    while true do
        local ev, p1, p2, p3, p4 = os.pullEvent()
        if ev == "timer" and p1 == timer then
            break
        elseif ev == "modem_message" and p2 == CHANNEL and type(p4) == "table" and type(p4.floors) == "table" and #p4.floors > 0 then
            detectedFloors = p4.floors
            break
        end
    end
    
    if detectedFloors and #detectedFloors > 0 then
        table.sort(detectedFloors, function(a, b)
            local yA = tonumber(a.y) or 0
            local yB = tonumber(b.y) or 0
            if yA ~= yB then return yA > yB end
            return tostring(a.name) > tostring(b.name)
        end)
        
        print("\nElevator floors detected:")
        for idx, fl in ipairs(detectedFloors) do
            local dName = (fl.longName and fl.longName ~= "") and fl.longName or fl.name
            print(string.format("  %d. %s (Y: %s)", idx, tostring(dName), tostring(fl.y or "?")))
        end
        print()
        while not myFloor or myFloor == "" do
            write("Select floor [1-" .. #detectedFloors .. "] or type name: ")
            local input = read()
            local num = tonumber(input)
            if num and detectedFloors[num] then
                local chosen = detectedFloors[num]
                myFloor = (chosen.longName and chosen.longName ~= "") and tostring(chosen.longName) or tostring(chosen.name)
            elseif input and input:gsub("%s+", "") ~= "" then
                myFloor = input
            end
        end
    else
        print("Could not detect elevator floors automatically.")
        print("What floor is this computer on?")
        io.write("Floor Name/Number: ")
        myFloor = read()
    end

    local file = fs.open("floor.txt", "w")
    file.write(myFloor)
    file.close()
    print("Floor configured as: " .. myFloor)
end

local currentFloor = "--"
local currentRawFloor = "--"
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
    
    local isHere = (tostring(floor) == tostring(myFloor) or tostring(currentRawFloor) == tostring(myFloor)) and not isMoving
    local btnFg = isHere and colors.gray or colors.cyan
    local btnText = isHere and "[ HERE ]" or "[ CALL ]"
    
    writeCentered(btnText, termH, btnFg)
end

drawDisplay("--", false)

while true do
    local event, p1, p2, p3, p4 = os.pullEvent()
    
    if event == "modem_message" and p2 == CHANNEL then
        local isUpdate = (type(p4) == "table" and p4.action == "update") or (p4 == "update")
        if isUpdate then
            local targetMatch = true
            if type(p4) == "table" and p4.target and p4.target ~= "all" and p4.target ~= "display" then
                targetMatch = false
            end

            if targetMatch then
                print("Received update command from master.")
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                writeCentered("UPDATING...", math.floor(termH / 2), colors.yellow)

                local updateScript = "/alr/elevator-floor-display/update.lua"
                if fs.exists(updateScript) then
                    shell.run(updateScript)
                else
                    printError("Update script not found at " .. updateScript)
                end

                sleep(1)
                if fs.exists("/startup.lua") then
                    os.reboot()
                else
                    drawDisplay(currentFloor, isElevatorMoving)
                end
            end
        elseif type(p4) == "table" and p4.floor then
            currentFloor = p4.floor
            currentRawFloor = p4.rawFloor or p4.floor
            isElevatorMoving = p4.moving or false
            drawDisplay(currentFloor, isElevatorMoving)
        end

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