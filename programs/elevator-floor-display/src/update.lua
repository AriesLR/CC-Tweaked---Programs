local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local baseUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/"
local launcherUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/elevator_floor_display.lua"

if not http then
    printError("Error: HTTP API is disabled in ComputerCraft config.")
    return
end

local activeScript
local displayExists = fs.exists(displayScript)
local sendExists = fs.exists(sendScript)

if displayExists and not sendExists then
    activeScript = "display_floor.lua"
elseif sendExists and not displayExists then
    activeScript = "send_floor.lua"
elseif displayExists and sendExists then
    print("Multiple operational scripts detected in " .. targetDir)
    write("Update mode (1: Display, 2: Send, 3: Both): ")
    local choice = read()
    if choice == "1" or choice:lower() == "display" then
        activeScript = "display_floor.lua"
    elseif choice == "2" or choice:lower() == "send" then
        activeScript = "send_floor.lua"
    else
        activeScript = "both"
    end
else
    printError("Error: Neither display_floor.lua nor send_floor.lua found in " .. targetDir)
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

if activeScript == "both" then
    if not downloadFile(baseUrl .. "display_floor.lua", displayScript) then success = false end
    if not downloadFile(baseUrl .. "send_floor.lua", sendScript) then success = false end
else
    if not downloadFile(baseUrl .. activeScript, targetDir .. "/" .. activeScript) then
        success = false
    end
end

local companionScripts = {
    "update.lua",
    "create_startup.lua",
    "uninstall.lua"
}

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
