require 'ISUI/ISWorldObjectContextMenu';
require "TimedActions/ISBaseTimedAction";
local TimedActionUtils = require "Starlit/client/timedActions/TimedActionUtils"

local ConnectLampAction = ISBaseTimedAction:derive("ConnectLampAction")
local LampUtils = require "LampUtils"

local function predicateNotBroken(item)
	return not item:isBroken()
end

local function findClosestAdjacentFreeSquare(object, character)
    if not object or not character then return nil end

    local objectSquare = object:getSquare()
    if not objectSquare then return nil end

    local charSquare = character:getSquare()
    if not charSquare then return nil end

    local x, y, z = objectSquare:getX(), objectSquare:getY(), objectSquare:getZ()

    local candidateSquares = {
        getCell():getGridSquare(x + 1, y, z),
        getCell():getGridSquare(x - 1, y, z),
        getCell():getGridSquare(x, y + 1, z),
        getCell():getGridSquare(x, y - 1, z),
    }

    local minDist = math.huge
    local closest = nil

    for _, square in ipairs(candidateSquares) do
        if square and square:isFree(false) then
            local dx = square:getX() - charSquare:getX()
            local dy = square:getY() - charSquare:getY()
            local distSq = dx * dx + dy * dy

            if distSq < minDist then
                minDist = distSq
                closest = square
            end
        end
    end

    return closest
end

function ConnectLampAction:isValidStart()
    return self.character:getInventory():contains("ElectricWire") and self.lamp and self.lamp:getSquare()
end

function ConnectLampAction:waitToStart()
    self.character:faceThisObject(self.lamp)
    return self.character:shouldBeTurning()
end

function ConnectLampAction:isValid()
    return self.lamp and self.lamp:getSquare() ~= nil
end

function ConnectLampAction:perform()
    local playerObj = self.character
    local playerInv = playerObj:getInventory()
    playerInv:RemoveOneOf("ElectricWire")
    
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
    end

    local square = self.lamp:getSquare()
    if square and self.dir then
        LampUtils.spawnWiredLampWithDir(square, self.dir, self.lamp)
    end
    ISBaseTimedAction.perform(self)
end

function ConnectLampAction:new(character, lamp, dir)
    local o = ISBaseTimedAction.new({}, character)
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.lamp = lamp
    o.dir = dir
    o.maxTime = 200
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    o.sound = nil

    return o
end

function ConnectLampAction:start()
    self:setActionAnim("disassembleElectrical")
    self:setOverrideHandModels(nil, nil)

    -- for i, name in ipairs(FMODSound.getSoundNames()) do
    --     if string.find(name, "Connect") then
    --         print("Son trouvé : " .. name)
    --     end
    -- end

    self.sound = self.character:getEmitter():playSound("GeneratorConnect")
end

function ConnectLampAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end

    ISBaseTimedAction.stop(self)
end

function ConnectLampAction.queueNew(character, lamp, dir)
    local square = findClosestAdjacentFreeSquare(lamp, character)
    if not square then return end

    local playerInv = character:getInventory()
    local walkAction = ISWalkToTimedAction:new(character, square)
    local connectAction = ConnectLampAction:new(character, lamp, dir)

    local screwdriver = playerInv:getFirstTagEvalRecurse("Screwdriver", predicateNotBroken)

    ISTimedActionQueue.add(walkAction)
    TimedActionUtils.transferAndEquip(character, screwdriver, "primary")
    ISTimedActionQueue.add(connectAction)

end

return {
    ConnectLampAction = ConnectLampAction
}