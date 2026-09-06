-- Delete the /alr/elevator-floor-display folder and everything inside it
if fs.exists("/alr/elevator-floor-display") then
    print("Deleting /alr/elevator-floor-display folder and its contents...")
    fs.delete("/alr/elevator-floor-display")
else
    print("/alr/elevator-floor-display folder not found, skipping...")
end

-- Delete install_send.lua
if fs.exists("/install_send.lua") then
    print("Deleting install_send.lua...")
    fs.delete("/install_send.lua")
else
    print("install_send.lua not found, skipping...")
end

-- Delete install_display.lua
if fs.exists("/install_display.lua") then
    print("Deleting install_display.lua...")
    fs.delete("/install_display.lua")
else
    print("install_display.lua not found, skipping...")
end

-- Temporary script to delete this script after it finishes
local selfPath = "/alr/elevator-floor-display/uninstall.lua"
local temp = fs.open("/delete_self.lua", "w")
temp.write([[
sleep(0.5)
fs.delete("]] .. selfPath .. [[")
fs.delete("/delete_self.lua")
]])
temp.close()

-- Run the temporary delete_self script
shell.run("/delete_self.lua")
print("Uninstall complete!")
