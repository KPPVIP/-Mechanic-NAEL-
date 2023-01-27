ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

POLO_Grooveshops_Config = {
    Positions = {
        -- TwentyFourSeven
        {name = '', x = -100.63,   y = -1797.33,  z = 21.77}
    },

    -- You can change that
    Items = {
        {Label = '~r~Tablette RGB', Value = 'pilotergb', Price = 500},
		{Label = '~b~Nitro', Value = 'nitro', Price = 1500}
    }
}

--[[Citizen.CreateThread(function()
	for k, v in pairs(POLO_Grooveshops_Config.Positions) do
		local blip = AddBlipForCoord(v.x, v.y, v.z)

		SetBlipSprite(blip, 89)
		SetBlipScale (blip, 0.8)
		SetBlipColour(blip, 66)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(_U('shop') .. ' '.. v.name .. '')
		EndTextCommandSetBlipName(blip)
	end
end)]]

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())

		for k, v in pairs(POLO_Grooveshops_Config.Positions) do
			local distance = GetDistanceBetweenCoords(playerCoords, v.x, v.y, v.z, true)

            if distance < 10.0 then
                actualZone = v

                zoneDistance = GetDistanceBetweenCoords(playerCoords, actualZone.x, actualZone.y, actualZone.z, true)

				DrawMarker(29, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
            end
            
            if distance <= 1.5 then
                ESX.ShowHelpNotification(_U('open_menu'))

                if IsControlJustPressed(1, 51) then
                    RageUI.Visible(RMenu:Get('showcase', 'shopMenu'), not RageUI.Visible(RMenu:Get('showcase', 'shopMenu')))
                end
            end

            if zoneDistance ~= nil then
                if zoneDistance > 1.5 then
                    RageUI.CloseAll()
                end
            end
		end
	end
end)

local max = 10 -- number of items that can be selected
Numbers = {}

Citizen.CreateThread(function()
    for i = 1, max do
        table.insert(Numbers, i)
    end
end)