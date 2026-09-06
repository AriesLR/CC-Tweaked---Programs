local scriptUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/send_floor.lua"
local updateUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/update_send.lua"
local uninstallUrl = "https://cccdn.arieslr.xyz/programs/elevator-floor-display/src/uninstall.lua"
local targetDir = "/alr/elevator-floor-display"

-- Ensure the directory exists
if not fs.exists(targetDir) then
    print("Creating directory " .. targetDir)
    fs.makeDir(targetDir)
end

-- Download from raw URL
local function downloadFile(url, dir)
    local fileName = url:match(".+/([^/]+)$")
    local fullPath = dir .. "/" .. fileName

    print("Downloading " .. fileName .. " to " .. dir .. "...")
    local res = http.get(url)
    if res then
        local f = fs.open(fullPath, "w")
        f.write(res.readAll())
        f.close()
        res.close()
        print(fileName .. " downloaded successfully.")
    else
        print("Failed to download " .. fileName)
    end

    return fullPath
end

-- Download main script
local mainScriptPath = downloadFile(scriptUrl, targetDir)

-- Download uninstaller
downloadFile(uninstallUrl, targetDir)

-- Download updater
downloadFile(updateUrl, targetDir)

-- Run the main script
print("Running " .. mainScriptPath .. "...")
shell.run(mainScriptPath)
