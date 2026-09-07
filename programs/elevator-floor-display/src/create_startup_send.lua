local file = fs.open("/startup.lua", "w")
file.writeLine('shell.run("/alr/elevator-floor-display/send_floor.lua")')
file.close()
print("Created /startup.lua successfully.")