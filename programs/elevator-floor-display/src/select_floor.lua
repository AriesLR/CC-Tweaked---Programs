local CHANNEL = 9000
local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")

if not monitor then error("No Advanced Monitor attached!") end
if not modem then error("No Ender Modem attached!") end

modem.open(CHANNEL)

monitor.setTextScale(1)
local termW, termH = monitor.getSize()

local currentFloor = "--"
local isElevatorMoving = false
local targetFloor = nil
local callingFloor = nil

local floors = {}
local currentPage = 1
local totalPages = 1

-- Bounding boxes for touch handling
local activeButtons = {}
local navButtons = {
    prev = nil,
    next = nil
}

local function centerText(text, width)
    local str = tostring(text)
    if #str >= width then
        return str:sub(1, width)
    end
    local padLeft = math.floor((width - #str) / 2)
    local padRight = width - #str - padLeft
    return string.rep(" ", padLeft) .. str .. string.rep(" ", padRight)
end

local function drawText(x, y, text, fgColor, bgColor)
    monitor.setCursorPos(x, y)
    if bgColor then monitor.setBackgroundColor(bgColor) end
    if fgColor then monitor.setTextColor(fgColor) end
    monitor.write(tostring(text))
end

local function writeCentered(text, y, fgColor, bgColor)
    local str = tostring(text)
    local x = math.max(1, math.floor((termW - #str) / 2) + 1)
    if bgColor then monitor.setBackgroundColor(bgColor) end
    if fgColor then monitor.setTextColor(fgColor) end
    monitor.setCursorPos(x, y)
    monitor.write(str)
end

-- Sort floors descending by Y level (Elevator Panel Order: top floors first)
local function sortFloors(floorList)
    table.sort(floorList, function(a, b)
        local yA = tonumber(a.y) or 0
        local yB = tonumber(b.y) or 0
        if yA ~= yB then
            return yA > yB
        end
        local numA = tonumber(a.name)
        local numB = tonumber(b.name)
        if numA and numB then
            return numA > numB
        end
        return tostring(a.name) > tostring(b.name)
    end)
end

local function calculateLayout()
    local startY = 4
    local footerY = termH
    local availableHeight = footerY - 2 - startY + 1
    
    -- Two columns layout
    local colGap = 1
    local margin = 1
    local colWidth = math.max(5, math.floor((termW - (margin * 2) - colGap) / 2))
    
    -- Spacing: 1 row button + 1 row gap if space allows, otherwise compact
    local rowStep = (availableHeight >= 8) and 2 or 1
    local rowsPerPage = math.max(1, math.floor((availableHeight + (rowStep - 1)) / rowStep))
    local buttonsPerPage = rowsPerPage * 2

    totalPages = math.max(1, math.ceil(#floors / buttonsPerPage))
    if currentPage > totalPages then
        currentPage = totalPages
    elseif currentPage < 1 then
        currentPage = 1
    end

    return {
        startY = startY,
        footerY = footerY,
        colWidth = colWidth,
        margin = margin,
        colGap = colGap,
        rowStep = rowStep,
        rowsPerPage = rowsPerPage,
        buttonsPerPage = buttonsPerPage
    }
end

local function drawDisplay()
    local layout = calculateLayout()
    activeButtons = {}
    navButtons.prev = nil
    navButtons.next = nil

    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    -- Header (Rows 1-3)
    local headerTitle = "ELEVATOR CONTROL"
    writeCentered(headerTitle, 1, colors.white, colors.black)

    local statusText
    local statusFg
    if isElevatorMoving then
        statusText = currentFloor .. " [MOVING]"
        statusFg = colors.yellow
    else
        statusText = currentFloor .. " [IDLE]"
        statusFg = colors.lime
    end
    writeCentered(statusText, 2, statusFg, colors.black)

    if targetFloor and targetFloor ~= "" and isElevatorMoving then
        writeCentered("-> TO: " .. targetFloor .. " <-", 3, colors.cyan, colors.black)
    else
        monitor.setCursorPos(1, 3)
        monitor.setTextColor(colors.gray)
        monitor.write(string.rep("-", termW))
    end

    -- If no floors received yet
    if #floors == 0 then
        writeCentered("Searching for", math.floor(termH / 2) - 1, colors.lightGray, colors.black)
        writeCentered("elevator floors...", math.floor(termH / 2), colors.lightGray, colors.black)
        writeCentered("[ RETRY ]", math.floor(termH / 2) + 2, colors.cyan, colors.black)
        activeButtons[1] = {
            name = "__retry__",
            x1 = math.floor((termW - 9) / 2) + 1,
            x2 = math.floor((termW - 9) / 2) + 9,
            y1 = math.floor(termH / 2) + 2,
            y2 = math.floor(termH / 2) + 2
        }
        return
    end

    -- Render floor buttons for the current page in column-major order
    local startIndex = (currentPage - 1) * layout.buttonsPerPage + 1
    local endIndex = math.min(#floors, startIndex + layout.buttonsPerPage - 1)

    local function renderButton(idx, col, row)
        if idx > endIndex then return end
        local btnX = layout.margin + col * (layout.colWidth + layout.colGap)
        local btnY = layout.startY + row * layout.rowStep
        local fl = floors[idx]
        local flName = tostring(fl.name)
        local displayName = (fl.longName and fl.longName ~= "") and tostring(fl.longName) or flName

        local isCurrent = (flName == tostring(currentFloor)) or (displayName == tostring(currentFloor))
        local isTarget = (flName == tostring(targetFloor)) or (displayName == tostring(targetFloor)) or (flName == tostring(callingFloor)) or (displayName == tostring(callingFloor))

        local btnFg
        local label

        if isCurrent then
            btnFg = isElevatorMoving and colors.yellow or colors.lime
            label = centerText("*" .. displayName .. "*", layout.colWidth)
        elseif isTarget then
            btnFg = colors.cyan
            label = centerText(">" .. displayName .. "<", layout.colWidth)
        else
            btnFg = colors.white
            label = centerText("[" .. displayName .. "]", layout.colWidth)
        end

        drawText(btnX, btnY, label, btnFg, colors.black)

        table.insert(activeButtons, {
            name = flName,
            displayName = displayName,
            isCurrent = isCurrent,
            x1 = btnX,
            x2 = btnX + layout.colWidth - 1,
            y1 = btnY,
            y2 = btnY
        })
    end

    for r = 0, layout.rowsPerPage - 1 do
        renderButton(startIndex + r, 0, r)
        renderButton(startIndex + layout.rowsPerPage + r, 1, r)
    end

    -- Footer Navigation (Row footerY)
    local prevLabel = "[ < ]"
    local nextLabel = "[ > ]"
    local pageLabel = currentPage .. "/" .. totalPages

    local prevX = 1
    local nextX = termW - #nextLabel + 1

    local prevFg = (currentPage > 1) and colors.cyan or colors.gray
    local nextFg = (currentPage < totalPages) and colors.cyan or colors.gray

    drawText(prevX, layout.footerY, prevLabel, prevFg, colors.black)
    writeCentered(pageLabel, layout.footerY, colors.white, colors.black)
    drawText(nextX, layout.footerY, nextLabel, nextFg, colors.black)

    navButtons.prev = {
        x1 = prevX,
        x2 = prevX + #prevLabel - 1,
        y = layout.footerY,
        enabled = (currentPage > 1)
    }

    navButtons.next = {
        x1 = nextX,
        x2 = nextX + #nextLabel - 1,
        y = layout.footerY,
        enabled = (currentPage < totalPages)
    }
end

-- Request floors immediately from send_floor
local function requestFloors()
    modem.transmit(CHANNEL, CHANNEL, { action = "get_floors" })
end

requestFloors()
drawDisplay()

local retryTimer = os.startTimer(2)

while true do
    local event, p1, p2, p3, p4 = os.pullEvent()

    if event == "timer" then
        if p1 == retryTimer then
            if #floors == 0 then
                requestFloors()
                retryTimer = os.startTimer(3)
            end
        end

    elseif event == "modem_message" and p2 == CHANNEL then
        local msg = p4
        if type(msg) == "table" then
            local isUpdate = (msg.action == "update" or msg == "update")
            local targetMatch = not msg.target or msg.target == "all" or msg.target == "selector" or msg.target == "display"

            if isUpdate and targetMatch then
                print("Received update command from master.")
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                writeCentered("UPDATING...", math.floor(termH / 2), colors.yellow, colors.black)

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
                    drawDisplay()
                end

            else
                local stateChanged = false

                if msg.floor then
                    currentFloor = tostring(msg.floor)
                    stateChanged = true
                end

                if msg.moving ~= nil then
                    isElevatorMoving = msg.moving
                    if not isElevatorMoving then
                        callingFloor = nil
                    end
                    stateChanged = true
                end

                if msg.targetFloor ~= nil then
                    targetFloor = msg.targetFloor
                    if targetFloor == currentFloor and not isElevatorMoving then
                        targetFloor = nil
                    end
                    stateChanged = true
                end

                if type(msg.floors) == "table" and #msg.floors > 0 then
                    floors = msg.floors
                    sortFloors(floors)
                    stateChanged = true
                end

                if stateChanged then
                    drawDisplay()
                end
            end
        end

    elseif event == "monitor_touch" then
        local tx, ty = p2, p3

        -- Check footer nav
        if navButtons.prev and navButtons.prev.enabled and ty == navButtons.prev.y and tx >= navButtons.prev.x1 and tx <= navButtons.prev.x2 then
            currentPage = currentPage - 1
            drawDisplay()

        elseif navButtons.next and navButtons.next.enabled and ty == navButtons.next.y and tx >= navButtons.next.x1 and tx <= navButtons.next.x2 then
            currentPage = currentPage + 1
            drawDisplay()

        else
            -- Check floor buttons
            for _, btn in ipairs(activeButtons) do
                if ty >= btn.y1 and ty <= btn.y2 and tx >= btn.x1 and tx <= btn.x2 then
                    if btn.name == "__retry__" then
                        requestFloors()
                        drawDisplay()
                        break
                    elseif not btn.isCurrent then
                        callingFloor = btn.displayName
                        targetFloor = btn.displayName
                        modem.transmit(CHANNEL, CHANNEL, {
                            action = "call",
                            targetFloor = btn.name
                        })
                        drawDisplay()
                        break
                    end
                end
            end
        end
    end
end
