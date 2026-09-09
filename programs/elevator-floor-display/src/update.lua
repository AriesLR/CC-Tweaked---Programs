local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local selectScript = targetDir .. "/select_floor.lua"
local masterScript = targetDir .. "/broadcast_update.lua"
local baseUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/"
local launcherUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/elevator_floor_display.lua"

if not http then
    printError("Error: HTTP API is disabled in ComputerCraft config.")
    return
end

local activeScript
local displayExists = fs.exists(displayScript)
local sendExists = fs.exists(sendScript)
local selectExists = fs.exists(selectScript)
local masterExists = fs.exists(masterScript)

local existingCount = (displayExists and 1 or 0) + (sendExists and 1 or 0) + (selectExists and 1 or 0) + (masterExists and 1 or 0)

if existingCount == 1 then
    if displayExists then
        activeScript = "display_floor.lua"
    elseif sendExists then
        activeScript = "send_floor.lua"
    elseif selectExists then
        activeScript = "select_floor.lua"
    elseif masterExists then
        activeScript = "broadcast_update.lua"
    end
elseif existingCount > 1 then
    print("Multiple operational scripts detected in " .. targetDir)
    write("Update mode (1: Display, 2: Send, 3: Selector, 4: Master, 5: All): ")
    local choice = read()
    if choice == "1" or choice:lower() == "display" then
        activeScript = "display_floor.lua"
    elseif choice == "2" or choice:lower() == "send" then
        activeScript = "send_floor.lua"
    elseif choice == "3" or choice:lower() == "selector" or choice:lower() == "select" then
        activeScript = "select_floor.lua"
    elseif choice == "4" or choice:lower() == "master" then
        activeScript = "broadcast_update.lua"
    else
        activeScript = "all"
    end
else
    printError("Error: No elevator installation found in " .. targetDir)
    return
end

local function downloadFile(url, destPath)
    local fileName = fs.getName(destPath)
    write("Updating " .. fileName .. "... ")

    local res, err = http.get(url)
    if not res then
        print("FAILED")
        printError("Error: " .. tostring(err or "Failed to connect to host."))
        return false
    end

    local content = res.readAll()
    res.close()

    local f, openErr = fs.open(destPath, "w")
    if not f then
        print("FAILED")
        printError("Error writing file: " .. tostring(openErr or "Unable to open file."))
        return false
    end

    f.write(content)
    f.close()
    print("OK")
    return true
end

print("========================================")
print("     Elevator Floor Display Updater     ")
print("========================================")
print()

local success = true

if activeScript == "all" then
    if displayExists and not downloadFile(baseUrl .. "display_floor.lua", displayScript) then success = false end
    if sendExists and not downloadFile(baseUrl .. "send_floor.lua", sendScript) then success = false end
    if selectExists and not downloadFile(baseUrl .. "select_floor.lua", selectScript) then success = false end
    if masterExists and not downloadFile(baseUrl .. "broadcast_update.lua", masterScript) then success = false end
else
    if not downloadFile(baseUrl .. activeScript, targetDir .. "/" .. activeScript) then
        success = false
    end
end

local companionScripts = {
    "update.lua",
    "uninstall.lua"
}

if activeScript ~= "broadcast_update.lua" then
    table.insert(companionScripts, 2, "create_startup.lua")
end

for _, fileName in ipairs(companionScripts) do
    if not downloadFile(baseUrl .. fileName, targetDir .. "/" .. fileName) then
        success = false
    end
end

local launcherPath = "/elevator_floor_display.lua"
if fs.exists(launcherPath) or fs.exists("/install.lua") or fs.exists("/install_display.lua") or fs.exists("/install_send.lua") then
    if not downloadFile(launcherUrl, launcherPath) then
        success = false
    end
end

local legacyFiles = {
    "/install.lua",
    "/install_display.lua",
    "/install_send.lua",
    targetDir .. "/update_display.lua",
    targetDir .. "/update_send.lua",
    targetDir .. "/create_startup_display.lua",
    targetDir .. "/create_startup_send.lua"
}

for _, legacyPath in ipairs(legacyFiles) do
    if fs.exists(legacyPath) then
        fs.delete(legacyPath)
    end
end

if success then
    print("\nAll files successfully updated!")
else
    printError("\nUpdate completed with errors. Some files may not have updated.")
end
