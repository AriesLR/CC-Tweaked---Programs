local modem = peripheral.find("modem")

if not modem then
    printError("Error: No modem attached! Please attach a wireless or Ender modem.")
    return
end

print("========================================")
print("   Elevator Master - Broadcast Update   ")
print("========================================")
print()

local channel
while not channel do
    write("Broadcast on channel [default: 9000]: ")
    local input = read()
    if input == "" then
        channel = 9000
    else
        local num = tonumber(input)
        if num and num > 0 and num <= 65535 then
            channel = num
        else
            printError("Invalid channel. Must be a number between 1 and 65535.")
        end
    end
end

print()
write(string.format("Broadcast update command on channel %d to all computers? (y/n): ", channel))
local confirm = read()

if confirm:lower() ~= "y" and confirm:lower() ~= "yes" then
    print("Broadcast cancelled.")
    return
end

print("\nBroadcasting update signal...")

modem.transmit(channel, channel, {
    action = "update",
    target = "all"
})

print(string.format("Update command broadcast sent successfully on channel %d!\n", channel))
