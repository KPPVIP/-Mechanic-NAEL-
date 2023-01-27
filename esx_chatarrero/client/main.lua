ESX                             = nil
local PlayerData                = {}
local HasAlreadyEnteredMarker   = false
local LastZone                  = nil
local CurrentAction             = nil
local CurrentActionMsg          = ''
local CurrentActionData         = {}
local isDead                    = false
local CurrentTask               = {}
local menuOpen 				    = false
local wasOpen 				    = false
local pedIsTryingToChopVehicle  = false
local ChoppingInProgress        = false




--local spawncamion = { x = 0, y = 0, z = 0, h = 0 }
local venta = { x = -105.17, y = -1793.91, z = 21.77}


Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true
end)

AddEventHandler('playerSpawned', function(spawn)
    isDead = false
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if GetDistanceBetweenCoords(coords, Config.Zones.Shop.coords, true) < 3.0 then
            ESX.ShowHelpNotification(_U('shop_prompt'))

            if IsControlJustReleased(0, 38) then
                wasOpen = true
                OpenShop()
            end
        else
            if wasOpen then
                wasOpen = false
                ESX.UI.Menu.CloseAll()
            end

            Citizen.Wait(500)
        end
    end
end)

function OpenShop()
    local elements = {}
    menuOpen = true
    for k, v in pairs(ESX.GetPlayerData().inventory) do
        local price = Config.Itemsprice[v.name]

        if price and v.count > 0 then
            table.insert(elements, {
                label = ('%s - <span style="color:green;">%s</span>'):format(v.label, _U('item', ESX.Math.GroupDigits(price))),
                name = v.name,
                price = price,

                -- menu properties
                type = 'slider',
                value = 1,
                min = 1,
                max = v.count
            })
        end
    end
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'car_shop', {
        title    = _U('shop_title'),
        align    = 'bottom-right',
        elements = elements
    }, function(data, menu)
        TriggerServerEvent('esx_chatarrero:sell', data.current.name, data.current.value)
		exports.pNotify:SendNotification({text = "Allez retourner le camion", type = "success", timeout = 3000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
				--SetNewWaypoint(spawncamion.x,spawncamion.y)
    end, function(data, menu)
        menu.close()
        menuOpen = false
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if menuOpen then
            ESX.UI.Menu.CloseAll()
        end
    end
end)


function IsDriver()
    return GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()
end



function MaxSeats(vehicle)
    local vehpas = GetVehicleNumberOfPassengers(vehicle)
    return vehpas
end

local lastTested = 0
function ChopVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn( ped, false )
	local wheels = GetVehicleNumberOfWheels(vehicle)
	local doors = GetNumberOfVehicleDoors(vehicle)
    local seats = MaxSeats(vehicle)
    if seats ~= 0 then
        TriggerEvent('chat:addMessage', { args = { 'Il ne peut y avoir de passagers' } })
    elseif
        GetGameTimer() - lastTested > Config.CooldownMinutes * 60000 then
        lastTested = GetGameTimer()
        ESX.TriggerServerCallback('esx_chatarrero:anycops', function(anycops)
            --if anycops >= Config.CopsRequired then
                --if Config.CallCops then
                    --local randomReport = math.random(1, Config.CallCopsPercent)

                    --if randomReport == Config.CallCopsPercent then
                        --TriggerServerEvent('chopNotify')
                    --end
                --end
                ChoppingInProgress        = true
				if wheels == 4 then
			    if doors <= 4 then
		        VehiclePartsRemoval1()
                else
				VehiclePartsRemoval()
		        end
                else
                MotoPartsRemoval()
		        end
                if not HasAlreadyEnteredMarker then
                    HasAlreadyEnteredMarker =  true
                    ChoppingInProgress        = false
                    exports.pNotify:SendNotification({text = "Vous n'avez pas laissé les junkyards finir.", type = "error", timeout = 4000, layout = "centerRight", queue = "right", killer = true, animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
                    --SetVehicleAlarmTimeLeft(vehicle, 60000)
                end
            --else
                --ESX.ShowNotification(_U('not_enough_cops'))
            --end
        end)
    else
        local timerNewChop = Config.CooldownMinutes * 60000 - (GetGameTimer() - lastTested)
        exports.pNotify:SendNotification({
            text = "Puedes volver en " ..math.floor(timerNewChop / 60000).. " minutos",
            type = "error",
            timeout = 1000,
            layout = "centerRight",
            queue = "right",
            killer = true,
            animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}
        })
    end
end



function VehiclePartsRemoval()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn( ped, false )
	
    SetVehicleNumberPlateText(vehicle, "Robado")
    SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleUndriveable(vehicle, false)
    if ChoppingInProgress == true then
	puerta1 = CreatePed(1, Config.NPCHash1, -75.211, -1812.34, 25.81, 277.09, false, true)
	SetCurrentPedWeapon(puerta1, -2067956739, true)
	--LoadAnimDict("timetable@gardener@filling_can")
	--TaskPlayAnim(puerta1, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	    TaskStartScenarioInPlace(puerta1, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenFrontLeftTime, "Ouverture de la porte avant gauche")
        Citizen.Wait(Config.DoorOpenFrontLeftTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 0, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenFrontLeftTime, "Démontage de la porte avant gauche")
        Citizen.Wait(Config.DoorBrokenFrontLeftTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 0, true)
		DeleteEntity(puerta1)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	puerta2 = CreatePed(1, Config.NPCHash1, -72.86, -1809.79, 25.81, 203.33, false, true)
	SetCurrentPedWeapon(puerta2, -2067956739, true)
	TaskStartScenarioInPlace(puerta2, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenFrontRightTime, "Ouverture de la porte avant droite")
        Citizen.Wait(Config.DoorOpenFrontRightTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 1, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenFrontRightTime, "Démontage de la porte avant droite")
        Citizen.Wait(Config.DoorBrokenFrontRightTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 1, true)
				DeleteEntity(puerta2)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	puerta3 = CreatePed(1, Config.NPCHash1, -74.38, -1812.95, 25.81, 278.42, false, true)
	SetCurrentPedWeapon(puerta3, -2067956739, true)
	TaskStartScenarioInPlace(puerta3, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenRearLeftTime, "Ouverture de la porte arrière gauche")
        Citizen.Wait(Config.DoorOpenRearLeftTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 2, false, false)

    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenRearLeftTime, "Démontage de la porte arrière gauche")
        Citizen.Wait(Config.DoorBrokenRearLeftTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 2, true)
		DeleteEntity(puerta3)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
		puerta4 = CreatePed(1, Config.NPCHash1, -72.19, -1810.47, 25.81, 199.47, false, true)
	SetCurrentPedWeapon(puerta4, -2067956739, true)
	TaskStartScenarioInPlace(puerta4, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenRearRightTime, "Ouverture de la porte arrière droite")
        Citizen.Wait(Config.DoorOpenRearRightTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 3, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenRearRightTime, "Démontage de la porte arrière droite")
        Citizen.Wait(Config.DoorBrokenRearRightTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 3, true)
		DeleteEntity(puerta4)
		TriggerServerEvent("esx_chatarrero:puerta")
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	capo = CreatePed(1, Config.NPCHash1, -75.44, -1809.70, 25.81, 224.81, false, true)
	SetCurrentPedWeapon(capo, -2067956739, true)
	TaskStartScenarioInPlace(capo, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenHoodTime, "Capot ouvrant")
        Citizen.Wait(Config.DoorOpenHoodTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 4, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenHoodTime, "Capot démontable")
        Citizen.Wait(Config.DoorBrokenHoodTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false),4, true)
				DeleteEntity(capo)
		TriggerServerEvent("esx_chatarrero:capo")
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	trunk = CreatePed(1, Config.NPCHash1, -71.40, -1813.48, 25.81, 41.34, false, true)
	SetCurrentPedWeapon(trunk, -2067956739, true)
	TaskStartScenarioInPlace(trunk, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenTrunkTime, "Ouverture du coffre")
        Citizen.Wait(Config.DoorOpenTrunkTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 5, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenTrunkTime, "Démontage du coffre")
        Citizen.Wait(Config.DoorBrokenTrunkTime)
		DeleteEntity(trunk)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false),5, true)
    end
    Citizen.Wait(1000)
    exports['progressBars']:startUI(Config.DeletingVehicleTime, "Fin de la mise au rebut")
    Citizen.Wait(Config.DeletingVehicleTime)
    if ChoppingInProgress == true then
        DeleteVehicle()
		TriggerServerEvent("esx_chatarrero:piezas")
		TriggerServerEvent("esx_chatarrero:llanta")
        exports.pNotify:SendNotification({text = "Véhicule mis au rebut, prenez maintenant ce camion et allez vendre les pièces. Si vous ne voulez pas vendre les pièces, retournez le camion", type = "success", timeout = 5000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
		Spawn()
	SetNewWaypoint(venta.x,venta.y)
	final = CreatePed(1, Config.NPCHash1, -75.211, -1812.34, 25.81, 277.09, false, true)
	SetCurrentPedWeapon(capo, -2067956739, true)
	LoadAnimDict("gestures@m@standing@casual")
	TaskPlayAnim(final, "gestures@m@standing@casual", "gesture_hello", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	    Citizen.Wait(1000)
		DeleteEntity(final)
    end
end




function VehiclePartsRemoval1()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn( ped, false )
	
    SetVehicleNumberPlateText(vehicle, "Robado")
    SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleUndriveable(vehicle, false)
    if ChoppingInProgress == true then
	puerta1 = CreatePed(1, Config.NPCHash1, -75.211, -1812.34, 25.81, 277.09, false, true)
	SetCurrentPedWeapon(puerta1, -2067956739, true)
	    TaskStartScenarioInPlace(puerta1, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenFrontLeftTime, "Ouverture de la porte avant gauche")
        Citizen.Wait(Config.DoorOpenFrontLeftTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 0, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenFrontLeftTime, "Démontage de la porte avant gauche")
        Citizen.Wait(Config.DoorBrokenFrontLeftTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 0, true)
		DeleteEntity(puerta1)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	puerta2 = CreatePed(1, Config.NPCHash1, -72.86, -1809.79, 25.81, 203.33, false, true)
	SetCurrentPedWeapon(puerta2, -2067956739, true)
	TaskStartScenarioInPlace(puerta2, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenFrontRightTime, "Ouverture de la porte avant droite")
        Citizen.Wait(Config.DoorOpenFrontRightTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 1, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenFrontRightTime, "Démontage de la porte avant droite")
        Citizen.Wait(Config.DoorBrokenFrontRightTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false), 1, true)
				DeleteEntity(puerta2)
		TriggerServerEvent("esx_chatarrero:puerta2")
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	capo = CreatePed(1, Config.NPCHash1, -75.44, -1809.70, 25.81, 224.81, false, true)
	SetCurrentPedWeapon(capo, -2067956739, true)
	TaskStartScenarioInPlace(capo, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenHoodTime, "Capot ouvrant")
        Citizen.Wait(Config.DoorOpenHoodTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 4, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenHoodTime, "Capot démontable")
        Citizen.Wait(Config.DoorBrokenHoodTime)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false),4, true)
				DeleteEntity(capo)
		TriggerServerEvent("esx_chatarrero:capo")
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
	trunk = CreatePed(1, Config.NPCHash1, -71.40, -1813.48, 25.81, 41.34, false, true)
	SetCurrentPedWeapon(trunk, -2067956739, true)
	TaskStartScenarioInPlace(trunk, "PROP_HUMAN_BUM_BIN", 0, 1)
        exports['progressBars']:startUI(Config.DoorOpenTrunkTime, "Ouverture du coffre")
        Citizen.Wait(Config.DoorOpenTrunkTime)
        SetVehicleDoorOpen(GetVehiclePedIsIn(ped, false), 5, false, false)
    end
    Citizen.Wait(1000)
    if ChoppingInProgress == true then
        exports['progressBars']:startUI(Config.DoorBrokenTrunkTime, "Démontage du coffre")
        Citizen.Wait(Config.DoorBrokenTrunkTime)
		DeleteEntity(trunk)
        SetVehicleDoorBroken(GetVehiclePedIsIn(ped, false),5, true)
    end
    Citizen.Wait(1000)
    exports['progressBars']:startUI(Config.DeletingVehicleTime, "Fin de la mise au rebut")
    Citizen.Wait(Config.DeletingVehicleTime)
    if ChoppingInProgress == true then
        DeleteVehicle()
		TriggerServerEvent("esx_chatarrero:piezas")
		TriggerServerEvent("esx_chatarrero:llanta")
        exports.pNotify:SendNotification({text = "Véhicule mis au rebut, prenez maintenant ce camion et allez vendre les pièces. Si vous ne voulez pas vendre les pièces, retournez le camion", type = "success", timeout = 5000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
		Spawn()
	SetNewWaypoint(venta.x,venta.y)
	final = CreatePed(1, Config.NPCHash1, -75.211, -1812.34, 25.81, 277.09, false, true)
	SetCurrentPedWeapon(capo, -2067956739, true)
	LoadAnimDict("gestures@m@standing@casual")
	TaskPlayAnim(final, "gestures@m@standing@casual", "gesture_hello", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	    Citizen.Wait(1000)
		DeleteEntity(final)
    end
end



function MotoPartsRemoval()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn( ped, false )
	
    SetVehicleNumberPlateText(vehicle, "Robado")
    SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleUndriveable(vehicle, false)
    exports['progressBars']:startUI(Config.DeletingVehicleTime, "La démolition de la moto")
    Citizen.Wait(Config.DeletingVehicleTime)
    if ChoppingInProgress == true then
        DeleteVehicle()
		TriggerServerEvent("esx_chatarrero:moto")
        exports.pNotify:SendNotification({text = "Véhicule mis au rebut, vous avez plus qu'à donner vos pièces à un mécano pour qu'il aille les vendres vendre les pièces.", type = "success", timeout = 5000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
		Spawn()
	SetNewWaypoint(venta.x,venta.y)
	final = CreatePed(1, Config.NPCHash1, -75.211, -1812.34, 25.81, 277.09, false, true)
	SetCurrentPedWeapon(capo, -2067956739, true)
	LoadAnimDict("gestures@m@standing@casual")
	TaskPlayAnim(final, "gestures@m@standing@casual", "gesture_hello", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	    Citizen.Wait(1000)
		DeleteEntity(final)
    end
end






function DeleteVehicle()
    if IsDriver() then
        local playerPed = PlayerPedId()
        local coords    = GetEntityCoords(playerPed)
        if IsPedInAnyVehicle(playerPed,  false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            ESX.Game.DeleteVehicle(vehicle)
        end
        --TriggerServerEvent("esx_chatarrero:rewards", rewards)
    end
end

function Spawn()
	Citizen.Wait(0)

	local myPed = GetPlayerPed(-1)
	local player = PlayerId()
	local vehicle = GetHashKey('mule3')

	RequestModel(vehicle)

	while not HasModelLoaded(vehicle) do
		Wait(1)
	end

	local spawned_car = CreateVehicle(vehicle, spawncamion.x,spawncamion.y,spawncamion.z, spawncamion.h, -534.53, -1717.0, 19.12, 292.16, true, false)

	local plate = ""
    SetVehicleNumberPlateText(spawned_car, plate)
	SetVehicleOnGroundProperly(spawned_car)
	SetVehicleLivery(spawned_car, 2)
	--SetPedIntoVehicle(myPed, spawned_car, - 1)
	--SetModelAsNoLongerNeeded(vehicle)
	Citizen.InvokeNative(0xB736A491E64A32CF, Citizen.PointerValueIntInitialized(spawned_car))
end




AddEventHandler('esx_chatarrero:hasEnteredMarker', function(zone)
    if zone == 'Chopshop' and IsDriver() then
        CurrentAction     = 'Chopshop'
        CurrentActionMsg  = _U('press_to_chop')
        CurrentActionData = {}
    end
end)

AddEventHandler('esx_chatarrero:hasExitedMarker', function(zone)
    if menuOpen then
        ESX.UI.Menu.CloseAll()
    end

    if zone == 'Chopshop' then

        if ChoppingInProgress == true then
            exports.pNotify:SendNotification({text = "Tu t'es détourné des junkyards.", type = "error", timeout = 1000, layout = "centerRight", queue = "right", killer = true, animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
        end
    end
    ChoppingInProgress        = false


    CurrentAction = nil
end)

function CreateBlipCircle(coords, text, radius, color, sprite)

    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
end

Citizen.CreateThread(function()
    if Config.EnableBlips == true then
        for k,zone in pairs(Config.Zones) do
            CreateBlipCircle(zone.coords, zone.name, zone.radius, zone.color, zone.sprite)
        end
    end
end)

Citizen.CreateThread(function()
    if Config.NPCEnable == true then
        RequestModel(Config.NPCHash)
        RequestModel(Config.NPCHash1)
        while not HasModelLoaded(Config.NPCHash) do
            Wait(1)
        end
        --PROVIDER
        vendedor = CreatePed(1, Config.NPCHash, Config.NPCShop.x, Config.NPCShop.y, Config.NPCShop.z, Config.NPCShop.h, false, true)
        SetBlockingOfNonTemporaryEvents(vendedor, true)
        SetPedDiesWhenInjured(vendedor, false)
        SetPedCanPlayAmbientAnims(vendedor, true)
        SetPedCanRagdollFromPlayerImpact(vendedor, false)
        SetEntityInvincible(vendedor, true)
        FreezeEntityPosition(vendedor, true)
        TaskStartScenarioInPlace(vendedor, "WORLD_HUMAN_SMOKING", 0, true);
    else
    end
end)

-- Display markers
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local coords, letSleep = GetEntityCoords(PlayerPedId()), true
        for k,v in pairs(Config.Zones) do
            if Config.MarkerType ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance then
                DrawMarker(Config.MarkerType, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
                letSleep = false
            end
        end
        if letSleep then
            Citizen.Wait(500)
        end
    end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local coords      = GetEntityCoords(PlayerPedId())
        local isInMarker  = false
        local currentZone = nil
        local letSleep = true
        for k,v in pairs(Config.Zones) do
            if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
                isInMarker  = true
                currentZone = k
            end
        end
        if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
            HasAlreadyEnteredMarker = true
            LastZone                = currentZone
            TriggerEvent('esx_chatarrero:hasEnteredMarker', currentZone)
        end

        if not isInMarker and HasAlreadyEnteredMarker then
            HasAlreadyEnteredMarker = false
            TriggerEvent('esx_chatarrero:hasExitedMarker', LastZone)
        end
    end
end)

-- Key controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if CurrentAction ~= nil then
            ESX.ShowHelpNotification(CurrentActionMsg)
            if IsControlJustReleased(0, 38) then
                if IsDriver() then
                    if CurrentAction == 'Chopshop' then
                        ChopVehicle()
                    end
                end
                CurrentAction = nil
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)

		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped)
	end
	end
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if menuOpen then
            ESX.UI.Menu.CloseAll()
        end
    end
end)

--Only if Config.CallCops = true
--[[GetPlayerName()


RegisterNetEvent('outlawChopNotify')
AddEventHandler('outlawChopNotify', function(alert)
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        ESX.ShowAdvancedNotification(_U('911'), _U('chop'), _U('call'), 'CHAR_CALL911', 7)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0)
    end
end)

function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

local timer = 1 --in minutes - Set the time during the player is outlaw
local blipTime = 35 --in second
local showcopsmisbehave = true --show notification when cops steal too
local timing = timer * 60000 --Don't touche it

Citizen.CreateThread(function()
    while true do
        Wait(100)
        if NetworkIsSessionStarted() then
            DecorRegister("IsOutlaw",  3)
            DecorSetInt(PlayerPedId(), "IsOutlaw", 1)
            return
        end
    end
end)

Citizen.CreateThread( function()
    while true do
        Wait(100)
        local plyPos = GetEntityCoords(PlayerPedId(),  true)
        if pedIsTryingToChopVehicle then
            DecorSetInt(PlayerPedId(), "IsOutlaw", 2)
            if PlayerData.job ~= nil and PlayerData.job.name == 'police' and showcopsmisbehave == false then
            elseif PlayerData.job ~= nil and PlayerData.job.name == 'police' and showcopsmisbehave then
                TriggerServerEvent('ChoppingInProgressPos', plyPos.x, plyPos.y, plyPos.z)
                TriggerServerEvent('ChopInProgress')
                Wait(3000)
                pedIsTryingToChopVehicle = false
            end
        end
    end
end)]]

function LoadAnimDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)

		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(1)
		end
	end
end

--[[RegisterNetEvent('Choplocation')
AddEventHandler('Choplocation', function(tx, ty, tz)
    if PlayerData.job.name == 'police' then
        local transT = 250
        local Blip = AddBlipForCoord(tx, ty, tz)
        SetBlipSprite(Blip,  10)
        SetBlipColour(Blip,  1)
        SetBlipAlpha(Blip,  transT)
        SetBlipAsShortRange(Blip,  false)
        while transT ~= 0 do
            Wait(blipTime * 4)
            transT = transT - 1
            SetBlipAlpha(Blip,  transT)
            if transT == 0 then
                SetBlipSprite(Blip,  2)
                return
            end
        end
    end
end)]]

RegisterNetEvent('chopEnable')
AddEventHandler('chopEnable', function()
    pedIsTryingToChopVehicle = true
end)

Citizen.CreateThread(function()
  while true do
  Citizen.Wait(0)


  local coords = GetEntityCoords(PlayerPedId())
  	local _source = source
  local distance = Vdist(coords.x, coords.y, coords.z, Config.Spawn.unspawn.coords.x, Config.Spawn.unspawn.coords.y, Config.Spawn.unspawn.coords.z)

  if(Config.Type ~= -1 and GetDistanceBetweenCoords(coords, Config.Spawn.unspawn.coords.x, Config.Spawn.unspawn.coords.y, Config.Spawn.unspawn.coords.z, true) < 10) then
		local playerPed = PlayerPedId()
         DrawMarker(1, Config.Spawn.unspawn.coords.x, Config.Spawn.unspawn.coords.y, Config.Spawn.unspawn.coords.z, 0, 0, 0, 0, 0, 0, 1.5001, 1.5001, 0.6001,255,255,51, 200, 0, 0, 0, 0)


          if GetDistanceBetweenCoords(coords, Config.Spawn.unspawn.coords, true) < 1.5 then
          	StatusReady = true

          	if StatusReady == true  then
            ESX.ShowHelpNotification(('Appuyez sur E pour enregistrer le camion.'))

            end
            
            if IsControlJustReleased(1,  38) and StatusReady == true  then
	        if IsVehicleModel(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0x85A5B471)  then
             ExecuteCommand('dv')
			 Citizen.Wait(5000)
			 else
			  exports.pNotify:SendNotification({text = "Ce véhicule n'est pas le camion de travail", type = "error", timeout = 2000, layout = "centerRight", queue = "right", killer = true, animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
			end
        end
    end
    end
end
end)