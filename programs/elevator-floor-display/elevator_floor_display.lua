local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local selectScript = targetDir .. "/select_floor.lua"
local baseUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/"

if fs.exists(displayScript) then
    print("Starting Elevator Floor Display...")
    shell.run(displayScript)
    return
elseif fs.exists(sendScript) then
    print("Starting Elevator Floor Sender...")
    shell.run(sendScript)
    return
elseif fs.exists(selectScript) then
    print("Starting Elevator Floor Selector...")
    shell.run(selectScript)
    return
end

if not http then
    printError("Error: HTTP API is disabled in ComputerCraft config.")
    return
end

print("========================================")
print("     Elevator Floor Display Setup       ")
print("========================================")
print("Select operational mode:")
print("  1. Display (Monitor Computer)")
print("  2. Send (Elevator Computer)")
print("  3. Master (Broadcast Update Computer)")
print("  4. Selector (Floor Selector Panel)")
print()

local selectedScript
while true do
    write("Enter choice [1-4]: ")
    local input = read()
    if input == "1" or input:lower() == "display" then
        selectedScript = "display_floor.lua"
        break
    elseif input == "2" or input:lower() == "send" then
        selectedScript = "send_floor.lua"
        break
    elseif input == "3" or input:lower() == "master" or input:lower() == "broadcast" then
        selectedScript = "broadcast_update.lua"
        break
    elseif input == "4" or input:lower() == "selector" or input:lower() == "select" or input:lower() == "panel" then
        selectedScript = "select_floor.lua"
        break
    else
        print("Invalid selection. Please choose 1, 2, 3, or 4.")
    end
end

if not fs.exists(targetDir) then
    print("Creating directory " .. targetDir .. "...")
    fs.makeDir(targetDir)
end

local function downloadFile(url, destPath)
    local fileName = fs.getName(destPath)
    write("Downloading " .. fileName .. "... ")

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

local filesToDownload = {
    selectedScript,
    "update.lua",
    "uninstall.lua"
}

if selectedScript ~= "broadcast_update.lua" then
    table.insert(filesToDownload, 3, "create_startup.lua")
end

print()
local success = true
for _, fileName in ipairs(filesToDownload) do
    local url = baseUrl .. fileName
    local dest = targetDir .. "/" .. fileName
    if not downloadFile(url, dest) then
        success = false
    end
end

if not success then
    printError("\nSetup encountered errors during download. Please try again.")
    return
end

if selectedScript ~= "broadcast_update.lua" then
    print()
    shell.run(targetDir .. "/create_startup.lua")
end

print("\nSetup complete!")

if selectedScript ~= "broadcast_update.lua" then
    local mainScriptPath = targetDir .. "/" .. selectedScript
    print("Running " .. mainScriptPath .. "...\n")
    shell.run(mainScriptPath)
else
    print("\nMaster setup complete. To broadcast an update when ready, run:")
    print("  " .. targetDir .. "/broadcast_update.lua\n")
end
