local ESX = nil

local TERMINATE_GAME_EVENT = 'blarglegroove:terminateGame'
local START_GAME_EVENT = 'blarglegroove:startGame'
local SERVER_EVENT = 'blarglegroove:finishLevel'

playerData = {
    ped = nil,
    position = nil,
    vehicle = nil,
    isInGroove = false,
    isGrooveDriveable = false,
    isPlayerDead = false,
    job = ''
}

gameData = {
    isSettingUpLevel = false,
    isCurrentlyUnloadingPeds = false,
    isPlaying = false,
    level = 1,
    peds = {}, -- {{model: model, coords: coords}}
    pedsInGroove = {}, -- {{model: model, coords: coords}}
    secondsLeft = 0,
    grooveLocation = {x = 0, y = 0, z = 0, spawnPoints = {}},
    lastVehicleHealth = 1000,
}

Citizen.CreateThread(function()
    checkForTypoedSpawnPointCoordinates()
    waitForEsxInitialization()
    waitForPlayerJobInitialization()
    registerJobChangeListener()

    Overlay.Init()
    startControlLoop()
    mainLoop()
end)

function checkForTypoedSpawnPointCoordinates()
    for _, groove in pairs(Config.Groove) do
        for _, location in pairs(groove.spawnPoints) do
            local distance = getDistance(groove, location)
            if distance > Config.MaxSpawnPointDistanceAllowedFromGroove then
                Log.debug(Wrapper._('coordinates_too_far', groove.name, location.x, location.y, location.z,
                    Config.MaxSpawnPointDistanceAllowedFromGroove, distance))
            end
        end
    end
end

function waitForEsxInitialization()
    while ESX == nil do
        Wrapper.TriggerEvent('esx:getSharedObject', setEsx)
        Citizen.Wait(0)
    end
end

function waitForPlayerJobInitialization()
    while true do
        local esxPlayerData = ESX.GetPlayerData()
        if esxPlayerData ~= nil and esxPlayerData.job ~= nil then
            setPlayerJob(esxPlayerData.job)
            break
        end
        Citizen.Wait(10)
    end
end

function registerJobChangeListener()
    Wrapper.RegisterNetEvent('esx:setJob')
    Wrapper.AddEventHandler('esx:setJob', setPlayerJob)
end

function setPlayerJob(job)
    playerData.job = job.name
end

function startControlLoop()
    Citizen.CreateThread(controlLoop)
end

function controlLoop()
    while true do
        if not canUserPlay() then
            Citizen.Wait(1000)
        elseif Wrapper.IsControlJustPressed(1, Config.ActivationKey) then
            handleControlJustPressed()
        end

        Citizen.Wait(5)
    end
end

function handleControlJustPressed()
    if gameData.isPlaying then
        Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_requested'), true)
        Citizen.Wait(5000)
    elseif playerData.isInGroove then
        Wrapper.TriggerEvent(START_GAME_EVENT)
        ESX.ShowHelpNotification(Wrapper._('stop_game_help'))
        Citizen.Wait(5000)
    end
end

function mainLoop()
    while true do
        if not canUserPlay() then
            mainLoopNotAllowedToPlay()
        else
            mainLoopAllowedToPlay()
        end
    end
end

function canUserPlay()
    return not Config.LimitToGrooveJob or playerData.job == 'groove'
end

function mainLoopNotAllowedToPlay()
    Citizen.Wait(1000)
end

function mainLoopAllowedToPlay()
    local newPlayerData = gatherData()

    if gameData.isPlaying then
        handleGameEndingConditionsIfNeeded(newPlayerData)
        handleGrooveDamageDetection()
    elseif not playerData.isInGroove and newPlayerData.isInGroove then
        ESX.ShowHelpNotification(Wrapper._('start_game_help'))
    end

    playerData = newPlayerData

    Citizen.Wait(500)
end

function gatherData()
    local newPlayerData = {}
    newPlayerData.ped = Wrapper.PlayerPedId()
    newPlayerData.position = Wrapper.GetEntityCoords(newPlayerData.ped)
    newPlayerData.vehicle = Wrapper.GetVehiclePedIsIn(newPlayerData.ped, false)
    newPlayerData.isPlayerDead = Wrapper.IsPedDeadOrDying(newPlayerData.ped, true)
    newPlayerData.job = playerData.job

    newPlayerData.isInGroove = false
    newPlayerData.isGrooveDriveable = false

    if newPlayerData.vehicle ~= nil then
        local grooveModel = Config.GrooveModel or 'GROOVE'
        newPlayerData.isInGroove = Wrapper.IsVehicleModel(newPlayerData.vehicle, grooveModel)

        if newPlayerData.isInGroove then
            newPlayerData.isGrooveDriveable = Wrapper.IsVehicleDriveable(newPlayerData.vehicle, true)
        end
    end

    return newPlayerData
end

function handleGameEndingConditionsIfNeeded(newPlayerData)
    if not newPlayerData.isInGroove then
        Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_left_groove'), true)
    elseif not newPlayerData.isGrooveDriveable then
        Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_destroyed_groove'), true)
    elseif newPlayerData.isPlayerDead then
        Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_you_died'), true)
    elseif areAnyPatientsDead() then
        Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_patient_died'), true)
    end
end

function areAnyPatientsDead()
    return (not (gameData.isSettingUpLevel or gameData.isCurrentlyUnloadingPeds)) and Stream.of(gameData.peds)
        .anyMatch(function(patient) return Wrapper.IsPedDeadOrDying(patient.model, 1) end)
end

function handleGrooveDamageDetection()
    local vehicleHealth = Wrapper.GetVehicleBodyHealth(playerData.vehicle)

    if #gameData.pedsInGroove > 0 and vehicleHealth < gameData.lastVehicleHealth then
        addTime(Config.Formulas.timeLostForDamage(vehicleHealth - gameData.lastVehicleHealth))
    end

    gameData.lastVehicleHealth = vehicleHealth
end

function terminateGame(reasonForTerminating, failed)
    if failed then
        Scaleform.ShowWasted(Wrapper._('terminate_failed'), reasonForTerminating, 5)
        playSound(Config.Sounds.failedMission)
    else
        Scaleform.ShowPassed()
        playSound(Config.Sounds.passedMission)
    end

    gameData.isPlaying = false
    Markers.StopMarkers()
    Overlay.Stop()
    Blips.StopBlips()

    Peds.DeletePeds(mapPedsToModel(gameData.peds))
    Peds.DeletePeds(mapPedsToModel(gameData.pedsInGroove))
end
Wrapper.AddEventHandler(TERMINATE_GAME_EVENT, terminateGame)

function startGame()
    gameData.grooveLocation = findNearestGroove(playerData.position)
    gameData.secondsLeft = Config.InitialSeconds
    gameData.level = 1
    gameData.peds = {}
    gameData.pedsInGroove = {}
    gameData.lastVehicleHealth = Wrapper.GetVehicleBodyHealth(playerData.vehicle)
    gameData.isPlaying = true
    gameData.isSettingUpLevel = false
    gameData.isCurrentlyUnloadingPeds = false

    Overlay.Start(gameData)
    Markers.StartMarkers(gameData.grooveLocation)
    Blips.StartBlips(gameData.grooveLocation)
    setupLevel()
    startGameLoop()
    startTimerThread()
end
Wrapper.AddEventHandler(START_GAME_EVENT, startGame)

function findNearestGroove(playerPosition)
    local coordsOfNearest = Config.Groove[1]
    local distanceToNearest = getDistance(playerPosition, Config.Groove[1])

    for i = 2, #Config.Groove do
        local coords = Config.Groove[i]
        local distance = getDistance(playerPosition, coords)

        if distance < distanceToNearest then
            coordsOfNearest = coords
            distanceToNearest = distance
        end
    end

    return coordsOfNearest
end

function startTimerThread()
    Citizen.CreateThread(timerLoop)
end

function timerLoop()
    while gameData.isPlaying do
        if gameData.secondsLeft <= 0 then
            Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_out_of_time'), true)
        end

        Overlay.Update(gameData)

        Citizen.Wait(1000)

        gameData.secondsLeft = gameData.secondsLeft - 1
    end
end

function startGameLoop()
    Citizen.CreateThread(gameLoop)
end

function gameLoop()
    while gameData.isPlaying do
        if getDistance(playerData.position, gameData.grooveLocation) <= 10.0 and #gameData.pedsInGroove > 0 then
            handlePatientDropOff()
        else
            handlePatientPickUps()
        end

        Citizen.Wait(500)
    end
end

function handlePatientDropOff()
    displayMessageAndWaitUntilStopped('stop_groove_dropoff')

    gameData.isCurrentlyUnloadingPeds = true
    local numberDroppedOff = #gameData.pedsInGroove
    Peds.DeletePeds(mapPedsToModel(gameData.pedsInGroove))
    gameData.pedsInGroove = {}
    updateMarkersAndBlips()
    gameData.isCurrentlyUnloadingPeds = false

    if #gameData.peds == 0 then
        gameData.secondsLeft = Config.InitialSeconds
        Wrapper.TriggerServerEvent(SERVER_EVENT, gameData.level)
        Scaleform.ShowAddMoney(Wrapper._('add_money', Config.Formulas.moneyPerLevel(gameData.level)))

        if gameData.level == Config.MaxLevels then
            Wrapper.TriggerEvent(TERMINATE_GAME_EVENT, Wrapper._('terminate_finished'), false)
        else
            playSound(Config.Sounds.timeAdded)
            gameData.level = gameData.level + 1
            setupLevel()
        end
    else
        addTime(Config.Formulas.additionalTimeForDropOff(numberDroppedOff))
    end
end

function mapPedsToModel(peds)
    return Stream.of(peds)
        .map(function(ped) return ped.model end)
        .collect()
end

function handlePatientPickUps()
    for index, ped in pairs(gameData.peds) do
        local distanceFromPed = getDistance(playerData.position, ped.coords)

        removePatientInvincibilityIfInRange(ped, distanceFromPed)

        if distanceFromPed <= Config.PedPickupDistance then
            displayMessageAndWaitUntilStopped('stop_groove_pickup')

            handleLoading(ped, index)
            addTime(Config.Formulas.additionalTimeForPickup(getDistance(ped.coords, gameData.grooveLocation)))
            updateMarkersAndBlips()
            Overlay.Update(gameData)

            if #gameData.pedsInGroove >= Config.MaxPatientsPerTrip then
                Scaleform.ShowMessage(Wrapper._('return_to_groove_header'),
                    Wrapper._('return_to_groove_sub_full'), 5)
            elseif #gameData.peds == 0 then
                Scaleform.ShowMessage(Wrapper._('return_to_groove_header'),
                    Wrapper._('return_to_groove_sub_end_level'), 5)
            end

            return
        end
    end
end

function removePatientInvincibilityIfInRange(ped, distanceFromPed)
    if distanceFromPed <= Config.PedEndInvincibilityDistance then
        Peds.SetInvincibility(ped.model, false)
    end
end

function addTime(timeToAdd)
    gameData.secondsLeft = gameData.secondsLeft + timeToAdd

    if timeToAdd > 0 then
        Scaleform.ShowAddTime(Wrapper._('time_added', timeToAdd))
        playSound(Config.Sounds.timeAdded)
    elseif timeToAdd < 0 then
        Scaleform.ShowRemoveTime(Wrapper._('time_added', timeToAdd))
        playSound(Config.Sounds.timeRemoved)
    end
end

function handleLoading(ped, index)
    local freeSeat = findFirstFreeSeat()
    Peds.EnterVehicle(ped.model, playerData.vehicle, freeSeat)
    table.insert(gameData.pedsInGroove, ped)
    waitUntilPatientInGroove(ped)
    table.remove(gameData.peds, index)
end

function waitUntilPatientInGroove(ped)
    while gameData.isPlaying do
        if Peds.IsPedInVehicleOrTooFarAway(ped.model, ped.coords) then
            return
        end
        Citizen.Wait(50)
    end
end

function setupLevel()
    gameData.isSettingUpLevel = true
    gameData.peds = Stream.of(gameData.grooveLocation.spawnPoints)
        .shuffle()
        .filter(function(_, index) return index <= gameData.level end)
        .map(Peds.CreateRandomPedInArea)
        .collect()

    updateMarkersAndBlips()

    local subMessage
    if gameData.level == 1 then
        subMessage = Wrapper._('start_level_sub_one')
    else
        subMessage = Wrapper._('start_level_sub_multi', gameData.level)
    end

    Scaleform.ShowMessage(Wrapper._('start_level_header', gameData.level), subMessage, 5)
    gameData.isSettingUpLevel = false
end

function getDistance(coords1, coords2)
    return Wrapper.GetDistanceBetweenCoords(Wrapper.vector3(coords1.x, coords1.y, coords1.z),
        coords2.x, coords2.y, coords2.z, false)
end

function displayMessageAndWaitUntilStopped(notificationMessage)
    while gameData.isPlaying and not Wrapper.IsVehicleStopped(playerData.vehicle) do
        ESX.ShowNotification(Wrapper._(notificationMessage))
        Citizen.Wait(50)
    end
end

function findFirstFreeSeat()
    for i = 1, Config.MaxPatientsPerTrip do
        if Wrapper.IsVehicleSeatFree(playerData.vehicle, i) then
            return i
        end
    end

    return 0
end

function updateMarkersAndBlips()
    local coordsList = Stream.of(gameData.peds)
        .map(function(ped) return ped.coords end)
        .collect()

    Blips.UpdateBlips(coordsList)
    Markers.UpdateMarkers(coordsList)

    local isAnyoneInGroove = #gameData.pedsInGroove > 0
    Blips.SetFlashGroove(isAnyoneInGroove)
    Markers.SetShowGroove(isAnyoneInGroove)
end

function playSound(sound)
    Wrapper.PlaySoundFrontend(-1, sound.audioName, sound.audioRef, 1)
end

function setEsx(obj)
    ESX = obj
end
