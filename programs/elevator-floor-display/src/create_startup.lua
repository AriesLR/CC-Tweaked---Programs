local targetDir = "/alr/elevator-floor-display"
local displayScript = targetDir .. "/display_floor.lua"
local sendScript = targetDir .. "/send_floor.lua"
local selectScript = targetDir .. "/select_floor.lua"
local startupPath = "/startup.lua"

local scriptToRun
local displayExists = fs.exists(displayScript)
local sendExists = fs.exists(sendScript)
local selectExists = fs.exists(selectScript)

local existingCount = (displayExists and 1 or 0) + (sendExists and 1 or 0) + (selectExists and 1 or 0)

if existingCount == 1 then
    if displayExists then
        scriptToRun = displayScript
    elseif sendExists then
        scriptToRun = sendScript
    elseif selectExists then
        scriptToRun = selectScript
    end
elseif existingCount > 1 then
    print("Multiple operational scripts found in " .. targetDir)
    write("Select startup mode (1: Display, 2: Send, 3: Selector): ")
    local choice = read()
    if choice == "2" or choice:lower() == "send" then
        scriptToRun = sendScript
    elseif choice == "3" or choice:lower() == "selector" or choice:lower() == "select" then
        scriptToRun = selectScript
    else
        scriptToRun = displayScript
    end
elseif fs.exists(targetDir .. "/broadcast_update.lua") then
    print("Master computer (broadcast_update.lua) detected. Startup script is not needed for master.")
    return
else
    printError("Error: No valid startup script found in " .. targetDir .. " (neither display_floor.lua, send_floor.lua, nor select_floor.lua exists).")
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
