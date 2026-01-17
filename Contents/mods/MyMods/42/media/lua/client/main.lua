require "TimedActions/ISBaseTimedAction"

local LampActions = require "ConnectLampAction"

local function predicateNotBroken(item)
	return not item:isBroken()
end

local function onRightClickWiredLamp(player, context, worldobjects)
    for _, v in ipairs(worldobjects) do
        if v and v.getName and v:getName() then
            print("Nom de l'objet :", v:getName())
        end
    end

    for _, object in ipairs(worldobjects) do
        if instanceof(object, "IsoThumpable") and object:getName() == "WoodLampPillar" then
            local square = object:getSquare()
            local playerObj = getSpecificPlayer(player)
            local playerInv = playerObj:getInventory()
            local spriteName = object:getSprite():getName()
            local dir = "N"
            if spriteName == "carpentry_02_59" then
                dir = "S"
            elseif spriteName == "carpentry_02_61" then
                dir = "W"
            elseif spriteName == "carpentry_02_62" then
                dir = "E"
            end
            local hasElectricityLevel = playerObj:getPerkLevel(Perks.Electricity) >= 3
            local hasScrewdriver = playerInv:containsTagEvalRecurse("Screwdriver", predicateNotBroken)
            local option = context:addOption("Connect pillar", worldobjects, function()
                LampActions.ConnectLampAction.queueNew(playerObj, object, dir)
            end)

            if not (hasElectricityLevel and hasScrewdriver and playerInv:contains("ElectricWire")) then
                option.notAvailable = true
                option.toolTip = ISToolTip:new()
                option.toolTip:initialise()
                option.toolTip.description = ""

                if not hasElectricityLevel then
                    option.toolTip.description = option.toolTip.description .. "Electricity skill 3 required\n"
                end
                if not hasScrewdriver then
                    option.toolTip.description = option.toolTip.description .. "Screwdriver required\n"
                end
                if not playerInv:contains("ElectricWire") then
                    option.toolTip.description = option.toolTip.description .. "Electric Wire required\n"
                end

                option.toolTip.description = option.toolTip.description:trim()
            end
        break
        end
    end
end 

Events.OnFillWorldObjectContextMenu.Add(onRightClickWiredLamp)