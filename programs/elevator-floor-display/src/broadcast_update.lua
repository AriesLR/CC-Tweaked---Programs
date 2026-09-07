local CHANNEL = 9000
local modem = peripheral.find("modem")

if not modem then
    printError("Error: No modem attached! Please attach a wireless or Ender modem.")
    return
end

print("========================================")
print("   Elevator Master - Broadcast Update   ")
print("========================================")
print("Target channel: " .. CHANNEL)
print()
write("Broadcast update command to all display computers? (y/n): ")
local confirm = read()

if confirm:lower() ~= "y" and confirm:lower() ~= "yes" then
    print("Broadcast cancelled.")
    return
end

print("Broadcasting update signal...")

modem.transmit(CHANNEL, CHANNEL, {
    action = "update",
    target = "display"
})

print("Update command broadcast sent successfully on channel " .. CHANNEL .. "!")
