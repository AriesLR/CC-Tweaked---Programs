local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local startupPath = "/startup.lua"

local scriptToRun
local displayExists = fs.exists(displayScript)
local sendExists = fs.exists(sendScript)

if displayExists and not sendExists then
    scriptToRun = displayScript
elseif sendExists and not displayExists then
    scriptToRun = sendScript
elseif displayExists and sendExists then
    print("Both display and send scripts found in " .. targetDir)
    write("Select startup mode (1: Display, 2: Send): ")
    local choice = read()
    if choice == "2" or choice:lower() == "send" then
        scriptToRun = sendScript
    else
        scriptToRun = displayScript
    end
elseif fs.exists(targetDir .. "/broadcast_update.lua") then
    print("Master computer (broadcast_update.lua) detected. Startup script is not needed for master.")
    return
else
    printError("Error: No valid startup script found in " .. targetDir .. " (neither display_floor.lua nor send_floor.lua exists).")
    return
end

-- If /startup.lua exists and is a directory, remove it first
if fs.exists(startupPath) and fs.isDir(startupPath) then
    fs.delete(startupPath)
end

local file, err = fs.open(startupPath, "w")
if not file then
    printError("Failed to open " .. startupPath .. ": " .. tostring(err))
    return
end

file.writeLine(string.format('shell.run("%s")', scriptToRun))
file.close()

print("Created " .. startupPath .. " successfully (set to launch " .. fs.getName(scriptToRun) .. ").")
