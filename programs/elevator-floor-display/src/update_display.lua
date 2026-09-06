-- Delete uninstall.lua
if fs.exists("/alr/elevator-floor-display/uninstall.lua") then
    print("Deleting uninstall.lua...")
    fs.delete("/alr/elevator-floor-display/uninstall.lua")
else
    print("uninstall.lua not found, skipping...")
end

-- Delete display_floor.lua
if fs.exists("/alr/elevator-floor-display/display_floor.lua") then
    print("Deleting display_floor.lua...")
    fs.delete("/alr/elevator-floor-display/display_floor.lua")
else
    print("display_floor.lua not found, skipping...")
end

-- Delete install_display.lua
if fs.exists("/install_display.lua") then
    print("Deleting install_display.lua...")
    fs.delete("/install_display.lua")
else
    print("install_display.lua not found, skipping...")
end

-- Temporary script to delete this script after it finishes
local selfPath = "/alr/elevator-floor-display/update_display.lua"
local temp = fs.open("/delete_self.lua", "w")
temp.write([[
sleep(0.5)
fs.delete("]] .. selfPath .. [[")
fs.delete("/delete_self.lua")

-- Download the latest version of install_display.lua
shell.run("wget https://raw.githubusercontent.com/AriesLR/CC-Tweaked---Programs/refs/heads/main/programs/elevator-floor-display/install_display.lua /install_display.lua")

-- Run the updated script
shell.run("/install_display.lua")
]])
temp.close()

-- Run the temporary delete_self script
shell.run("/delete_self.lua")
print("Update complete!")