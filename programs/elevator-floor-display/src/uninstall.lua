-- Delete the /alr/elevator-floor-display folder and everything inside it
if fs.exists("/alr/elevator-floor-display") then
    print("Deleting /alr/elevator-floor-display folder and its contents...")
    fs.delete("/alr/elevator-floor-display")
else
    print("/alr/elevator-floor-display folder not found, skipping...")
end

-- Delete launcher and installer scripts
local filesToDelete = {
    "/elevator_floor_display.lua",
    "/install.lua",
    "/install_send.lua",
    "/install_display.lua",
    "/install_select.lua",
    "/floor.txt"
}

for _, path in ipairs(filesToDelete) do
    if fs.exists(path) then
        print("Deleting " .. path .. "...")
        fs.delete(path)
    end
end

-- Clean up /startup.lua if it points to elevator-floor-display
if fs.exists("/startup.lua") and not fs.isDir("/startup.lua") then
    local f = fs.open("/startup.lua", "r")
    if f then
        local content = f.readAll()
        f.close()
        if content:find("/alr/elevator%-floor%-display") then
            print("Removing elevator /startup.lua...")
            fs.delete("/startup.lua")
        end
    end
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
