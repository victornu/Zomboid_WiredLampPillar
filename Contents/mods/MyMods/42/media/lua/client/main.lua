local function onFillWorldObjectContextMenu(player, context, worldobjects)
    for _, object in ipairs(worldobjects) do
        if instanceof(object, "IsoGenerator") then
            context:addOption(
                "custom",
                object,
                function(generator)
                    print("Activate")
                end
            )
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
