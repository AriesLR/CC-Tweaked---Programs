-- Delete uninstall.lua
if fs.exists("/alr/elevator-floor-display/uninstall.lua") then
    print("Deleting uninstall.lua...")
    fs.delete("/alr/elevator-floor-display/uninstall.lua")
else
    print("uninstall.lua not found, skipping...")
end

-- Delete send_floor.lua
if fs.exists("/alr/elevator-floor-display/send_floor.lua") then
    print("Deleting send_floor.lua...")
    fs.delete("/alr/elevator-floor-display/send_floor.lua")
else
    print("send_floor.lua not found, skipping...")
end

-- Delete install_send.lua
if fs.exists("/install_send.lua") then
    print("Deleting install_send.lua...")
    fs.delete("/install_send.lua")
else
    print("install_send.lua not found, skipping...")
end

-- Temporary script to delete this script after it finishes
local selfPath = "/alr/elevator-floor-display/update_send.lua"
local temp = fs.open("/delete_self.lua", "w")
temp.write([[
sleep(0.5)
fs.delete("]] .. selfPath .. [[")
fs.delete("/delete_self.lua")

-- Download the latest version of install_send.lua
shell.run("wget https://raw.githubusercontent.com/AriesLR/Spoticraft/refs/heads/main/install_send.lua /install_send.lua")

-- Run the updated script
shell.run("/install_send.lua")
]])
temp.close()

-- Run the temporary delete_self script
shell.run("/delete_self.lua")
print("Update complete!")