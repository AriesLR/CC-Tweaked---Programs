local modem = peripheral.find("modem")

if not modem then
    printError("Error: No modem attached! Please attach a wireless or Ender modem.")
    return
end

print("========================================")
print("    Elevator Master - Change Channel    ")
print("========================================")
print()

local currentChannel
while not currentChannel do
    write("Current channel [default: 9000]: ")
    local input = read()
    if input == "" then
        currentChannel = 9000
    else
        local num = tonumber(input)
        if num and num > 0 and num <= 65535 then
            currentChannel = num
        else
            printError("Invalid channel. Must be a number between 1 and 65535.")
        end
    end
end

local newChannel
while not newChannel do
    write("New target channel: ")
    local input = read()
    local num = tonumber(input)
    if num and num > 0 and num <= 65535 then
        if num == currentChannel then
            printError("New channel must be different from current channel (" .. currentChannel .. ").")
        else
            newChannel = num
        end
    else
        printError("Invalid channel. Must be a number between 1 and 65535.")
    end
end

print()
write(string.format("Broadcast channel change from %d to %d? (y/n): ", currentChannel, newChannel))
local confirm = read()

if confirm:lower() ~= "y" and confirm:lower() ~= "yes" then
    print("Broadcast cancelled.")
    return
end

print("\nBroadcasting channel change signal...")

modem.transmit(currentChannel, currentChannel, {
    action = "set_channel",
    newChannel = newChannel
})

print(string.format("Command broadcast sent successfully on channel %d!", currentChannel))
print(string.format("Listening computers should now update their channel to %d and reboot.\n", newChannel))
