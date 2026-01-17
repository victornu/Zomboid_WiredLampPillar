local LampUtils = {}

function LampUtils.spawnWiredLampWithDir(square, direction, object)
    local spriteName = "wired_lamp_59"
    if direction == "N" then
        spriteName = "wired_lamp_60"
    elseif direction == "W" then
        spriteName = "wired_lamp_61"
    elseif direction == "E" then
        spriteName = "wired_lamp_62"
    end

    square:RemoveTileObject(object)
    square:transmitRemoveItemFromSquare(object)

    local sprite = getSprite(spriteName)
    if not sprite then return end

    local cell = getWorld():getCell()
    local lamp = IsoLightSwitch.new(cell, square, sprite, square:getRoomID())
    lamp:setName("WiredLampCustom")
    lamp:addLightSourceFromSprite()
    square:AddSpecialObject(lamp)
    lamp:addToWorld()
end

return LampUtils
