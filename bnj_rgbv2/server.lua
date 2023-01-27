--https://github.com/BNJ-Homme-Efficace/bnj_rgbv2
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj)
  ESX = obj
end)

ESX.RegisterUsableItem('pilotergb', function(source)
	local _source = source	
	TriggerClientEvent('esx_bnj:rgb', _source)
end) 

RegisterServerEvent('esx_bnj:Sync')
AddEventHandler('esx_bnj:Sync', function()
	local _source = source
  	local xPlayer = ESX.GetPlayerFromId(_source)
	xPlayer.removeInventoryItem('pilotergb', 1)
end)

ESX.RegisterServerCallback("esx_bnj:pharesrgb", function(source, cb, vehProps,color)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local plate = vehProps["plate"]
	local color = color
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles_phares WHERE `plate` LIKE  "%' .. plate .. '%"', {}, function(result)
			if result[1] ~= nil then
				local wyniki = MySQL.Sync.fetchAll('UPDATE `owned_vehicles_phares` SET `color`=@color WHERE `plate`=@plate', {['@color'] = color,['@plate'] = plate})
				cb(true)
			else
				local wyniki = MySQL.Sync.fetchAll('INSERT INTO `owned_vehicles_phares` (`id`, `plate`, `color`) VALUES (NULL,@plate,@color)', {['@plate'] = plate,['@color'] = color})
				cb(true)
			end
		end)
end)

ESX.RegisterServerCallback("esx_bnj:SyncRGB", function(source, cb, vehProps,color)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local color = color
	plate = vehProps
	if plate == nil then
		plate = "AA0000"
	end
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles_phares WHERE `plate` LIKE  "%' .. plate .. '%"', {}, function(result)
			if result[1] ~= nil then
				color = result[1].color
				cb(color)
			else
				color = 0
				cb(color)
			end
		end)
end)