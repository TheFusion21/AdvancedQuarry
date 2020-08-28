print("Advanced Quarry Program [Version 0.0.1]")
print("(c) 2020 Kay Hennig.\nAll rights reserved")
local position =
{
    x = 0,
    y = 0,
    z = 0,
}
local facingDir = 0

local stopPosition = 
{
    x = 0,
    y = 0,
    z = 0,
}
local stopFacingDir = 0

local size = 64

local MAXTRIES = 50


local setS = false
local tArgs = {...}
for i = 1,#tArgs do
    local arg = tArgs[i]
    if string.find(arg, "-") == 1 then
        for c=2,string.len(arg) do
            local argChar = string.sub(arg,c,c)
            if argChar == "s" then
                setS = true
            end
        end
    else
        if setS then
            size = tonumber(arg)
            setS = false
        end
    end
end

function log(s)
    str = s .. " [" .. position.x .. ", " .. position.y .. ", " .. position.z .. "]"

    print(str)
end

log("boring with size: " .. size .. "x" .. size)

function fuelNeededToGoBack()
	return -position.y + position.x + position.z + 2
end
function refuelIfNeeded()
    if turtle.getFuelLevel() <= fuelNeededToGoBack() then
        log("refueling")
        for i = 1, 16 do
            turtle.select(i)

            item = turtle.getItemDetail()

            if item and item.name == "minecraft:coal" and turtle.refuel(1) then
                return
            else
                --no fuel
                log("no fuel")
            end
        end
    end
end

function adjPosition()
    if facingDir == 0 then
        position.z = position.z + 1
    elseif facingDir == 1 then
        position.x = position.x + 1
    elseif facingDir == 2 then
        position.z = position.z - 1
    else
        position.x = position.x - 1
    end
end

function forward()
    refuelIfNeeded()
    local tries = 0
    turtle.digUp()
    turtle.digDown()
    while turtle.forward() ~= true do
        turtle.dig()
        
        turtle.attack()

        tries = tries+1

        if tries > MAXTRIES then
            log("failed to move forward")
            return false
        end
    end
    
    adjPosition()
    return true
end
function down()
    refuelIfNeeded()
    local tries = 0
    while turtle.down() ~= true do
        turtle.digDown()

        turtle.attackDown()

        tries = tries + 1

        if tries > MAXTRIES then
            return false
        end
    end
    position.y = position.y - 1
    return true
end
function up()
    refuelIfNeeded()
    local tries = 0
    while turtle.up() ~= true do
        turtle.diUp()

        turtle.attackUp()

        tries = tries + 1

        if tries > MAXTRIES then
            return false
        end
    end
    position.y = position.y + 1
    return true
end

function rotRight()
    facingDir = facingDir + 1
    facingDir = facingDir % 4
    turtle.turnRight()
end
function rotLeft()
    facingDir = facingDir - 1
    if facingDir < 0 then
        facingDir = 3
    end
    turtle.turnLeft()
end

function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
			return false
		end
    end
    return true
end

function dropOff()
    local dif = math.abs(position.y)
    for i = 1,dif do
        up()
    end
    rotRight()
    rotRight()
    for i = 1, 16 do
        turtle.select(i)

        item = turtle.getItemDetail()
        if item then
            if item.name ~= "minecraft:coal" then
                turtle.drop()
            end
        end
        
    end
    rotRight()
    rotRight()
    for i = 1,dif do
        down()
    end
end

function clearInventory()
    if isInventoryFull() then
        -- drop stuff and try to stack and check again
        dropTrash()
        stack()
        if isInventoryFull() then
            log("inventory full")
            log("stopping at ")
            stopPosition.x = position.x
            stopPosition.y = position.y
            stopPosition.z = position.z
            stopFacingDir = facingDir
            -- move back to chest
            if back then
                rotRight()
            else
                rotLeft()
            end
            for i = 1,stopPosition.x do
                forward()
            end
            rotLeft()
            for i = 1,stopPosition.z do
                forward()
            end
            dif = math.abs(stopPosition.y)
            for i = 1,dif do
                up()
            end
            -- drop of into chest
            for i = 1, 16 do
                turtle.select(i)
                item = turtle.getItemDetail()
                if item then
                    if item.name ~= "minecraft:coal" then
                        turtle.drop()
                    end
                end
            end
            -- go back to postion where we stopped at
            log("going back to [" .. stopPosition.x .. ", " .. stopPosition.y .. ", " .. stopPosition.z .. "]")
            rotLeft()
            rotLeft()

            for i = 1,stopPosition.z do
                forward()
            end

            rotRight()

            for i = 1,stopPosition.x do
                forward()
            end

            while facingDir ~= stopFacingDir do
                rotRight()
            end

            dif = math.abs(stopPosition.y)
            for i = 1,dif do
                down()
            end
        end
    end
end
local depth =
{
    x = 0,
    z = 0
}
local back = false

function stack()
    log("trying to stack items")
    for i = 1, 16 do
        item = turtle.getItemDetail(i)

        if item then
            for j = i, 16 do
                turtle.select(j)
                item2 = turtle.getItemDetail()

                if item2 then
                    if item.name == item.name then
                        turtle.transferTo(i)
                    end
                end
            end
        end
    end
    turtle.select(1)
end
function dropTrash()
    local useless = {
        "undergroundbiomes:sedimentary_stone",
        "minecraft:stone",
        "minecraft:dirt",
        "undergroundbiomes:igneous_cobble",
        "undergroundbiomes:igneous_gravel",
        "undergroundbiomes:metamorphic_cobble",
        "minecraft:sand",
        "minecraft:sandstone",
        "minecraft:cobblestone",
        "minecraft:gravel",
        "minecraft:flint",
        "minecraft:rotten_flesh",
        "thaumcraft:brain",
        "undergroundbiomes:fossil_piece"
    }
    for i = 1, 16 do
        details = turtle.getItemDetail(i)
        if details then
            for j = 1,#useless do
                if details.name == useless[j] then
                    turtle.select(i)
                    turtle.drop()
                end
            end
        end
    end
    turtle.select(1)
end

while true do
    -- go to chest if inventory is full
    clearInventory()
    if forward() then
        depth.z = depth.z + 1
    end
    if depth.x +1 >= size and depth.z +1 >= size then
        dropTrash()
        log("end of layer")
        
        --go to layers origin
        rotRight()
        for i = 1,size-1 do
            forward()
        end
        rotRight()
        log("dropping off")
        dropOff()
        down()
        down()
        down()
        depth.z = 0
        depth.x = 0
        back = false
    end
    if depth.z + 1 >= size then
        dropTrash()
        if back then
            log("turning left")
            rotLeft()
            forward()
            depth.x = depth.x + 1
            rotLeft()
        else
            log("turning right")
            rotRight()
            forward()
            depth.x = depth.x + 1
            rotRight()
        end
        back = not back
        depth.z = 0
    end
end