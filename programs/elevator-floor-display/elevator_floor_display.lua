local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local baseUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/"

if fs.exists(displayScript) then
    print("Starting Elevator Floor Display...")
    shell.run(displayScript)
    return
elseif fs.exists(sendScript) then
    print("Starting Elevator Floor Sender...")
    shell.run(sendScript)
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
print()

local selectedScript
while true do
    write("Enter choice [1-2]: ")
    local input = read()
    if input == "1" or input:lower() == "display" then
        selectedScript = "display_floor.lua"
        break
    elseif input == "2" or input:lower() == "send" then
        selectedScript = "send_floor.lua"
        break
    else
        print("Invalid selection. Please choose 1 or 2.")
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
    "create_startup.lua",
    "uninstall.lua"
}

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

print()
shell.run(targetDir .. "/create_startup.lua")

print("\nSetup complete!")

local mainScriptPath = targetDir .. "/" .. selectedScript
print("Running " .. mainScriptPath .. "...\n")
shell.run(mainScriptPath)
