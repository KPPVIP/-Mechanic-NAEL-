local mockagne = require 'mockagne'
local when = mockagne.when
local any = mockagne.any
local verify = mockagne.verify
local verifyNoCall = mockagne.verify_no_call

describe('client - main', function()
    
    local esx

    before_each(function()
        _G.unpack = table.unpack
        _G.Config = {
            LimitToGrooveJob = false,
            ActivationKey = 1,
            MaxPatientsPerTrip = 3,
            PedEndInvincibilityDistance = 30,
            PedPickupDistance = 10,
            Formulas = {},
            Sounds = {
                timeRemoved = {audioName = 'AudioName', audioRef = 'AudioRef'},
                timeAdded = {audioName = 'AudioName added', audioRef = 'AudioRef added'},
                failedMission = {audioName = 'AudioName failed', audioRef = 'AudioRef failed'},
                passedMission = {audioName = 'AudioName passed', audioRef = 'AudioRef passed'},
            }
        }
        _G.Citizen = {
            CreateThread = function() end,
            Wait = function() end,
        }
        _G.Wrapper = mockagne.getMock()
        _G.Blips = mockagne.getMock()
        _G.Markers = mockagne.getMock()
        _G.Peds = mockagne.getMock()
        _G.Scaleform = mockagne.getMock()
        _G.Overlay = mockagne.getMock()
        _G.Log = mockagne.getMock()

        require('../../src/lib/stream')
        require('../../src/client/main')

        esx = mockagne.getMock()
        setEsx(esx)
        gameData.grooveLocation = {
            name = 'groove name',
            x = 1, y = 2, z = 3,
            spawnPoints = {
                createCoords(1, 2, 3),
                createCoords(2, 3, 4),
                createCoords(3, 4, 5),
                createCoords(4, 5, 6),
                createCoords(5, 6, 7)
            }
        }
    end)

    it('checkForTypoedSpawnPointCoordinates - no logging when coordinates within allowed distance', function()
        _G.Config.MaxSpawnPointDistanceAllowedFromGroove = 20
        _G.Config.Groove = {gameData.grooveLocation}
        when(_G.Wrapper.GetDistanceBetweenCoords(any(), any(), any(), any(), false)).thenAnswer(15)

        checkForTypoedSpawnPointCoordinates()

        verifyNoCall(_G.Log.debug(any()))
    end)

    it('checkForTypoedSpawnPointCoordinates - logs when coordinates are outside allowed distance', function()
        _G.Config.MaxSpawnPointDistanceAllowedFromGroove = 20
        _G.Config.Groove = {gameData.grooveLocation}
        when(_G.Wrapper.GetDistanceBetweenCoords(any(), any(), any(), any(), false)).thenAnswer(25)
        when(_G.Wrapper._('coordinates_too_far', 'groove name', 1, 2, 3, 20, 25)).thenAnswer('coordinates too far spawn point 1 translated')
        when(_G.Wrapper._('coordinates_too_far', 'groove name', 2, 3, 4, 20, 25)).thenAnswer('coordinates too far spawn point 2 translated')
        when(_G.Wrapper._('coordinates_too_far', 'groove name', 3, 4, 5, 20, 25)).thenAnswer('coordinates too far spawn point 3 translated')
        when(_G.Wrapper._('coordinates_too_far', 'groove name', 4, 5, 6, 20, 25)).thenAnswer('coordinates too far spawn point 4 translated')
        when(_G.Wrapper._('coordinates_too_far', 'groove name', 5, 6, 7, 20, 25)).thenAnswer('coordinates too far spawn point 5 translated')

        checkForTypoedSpawnPointCoordinates()

        verify(_G.Log.debug('coordinates too far spawn point 1 translated'))
        verify(_G.Log.debug('coordinates too far spawn point 2 translated'))
        verify(_G.Log.debug('coordinates too far spawn point 3 translated'))
        verify(_G.Log.debug('coordinates too far spawn point 4 translated'))
        verify(_G.Log.debug('coordinates too far spawn point 5 translated'))
    end)

    it('waitForEsxInitialization', function()
        setEsx(nil)
        _G.Citizen.Wait = coroutine.yield

        local loop = coroutine.create(waitForEsxInitialization)
        iterateLoop(loop)

        assert.equals('suspended', coroutine.status(loop))
        verify(_G.Wrapper.TriggerEvent('esx:getSharedObject', any()))

        setEsx(esx)
        iterateLoop(loop)
        assert.equals('dead', coroutine.status(loop))
    end)

    it('waitForPlayerJobInitialization', function()
        _G.Citizen.Wait = coroutine.yield

        playerData.job = 'not set'

        local loop = coroutine.create(waitForPlayerJobInitialization)
        iterateLoop(loop)

        assert.equals('not set', playerData.job)
        
        when(esx.GetPlayerData()).thenAnswer({job = {name = 'job'}})
        iterateLoop(loop)
        iterateLoop(loop)

        assert.equals('job', playerData.job)
    end)

    it('controlLoop - control not pressed, just loops', function()
        _G.Citizen.Wait = coroutine.yield
        when(_G.Wrapper.IsControlJustPressed(1, 1)).thenAnswer(false)

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verifyNoCall(_G.Wrapper.TriggerEvent(any()))
        verifyNoCall(_G.Wrapper.TriggerEvent(any(), any()))
    end)

    it('controlLoop - control pressed, ignored when not playing and not in groove', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = false
        playerData.isInGroove = false
        when(_G.Wrapper.IsControlJustPressed(1, 1)).thenAnswer(true)

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verifyNoCall(_G.Wrapper.TriggerEvent(any()))
        verifyNoCall(_G.Wrapper.TriggerEvent(any(), any()))
    end)

    it('controlLoop - control pressed, terminates game when playing', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        when(_G.Wrapper.IsControlJustPressed(1, 1)).thenAnswer(true)
        when(_G.Wrapper._('terminate_requested')).thenAnswer('terminate_requested translated')

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_requested translated', true))
    end)

    it('controlLoop - control pressed, starts game when in groove', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = false
        playerData.isInGroove = true
        when(_G.Wrapper.IsControlJustPressed(1, 1)).thenAnswer(true)
        when(_G.Wrapper._('stop_game_help')).thenAnswer('stop_game_help translated')

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:startGame'))
        verify(esx.ShowHelpNotification('stop_game_help translated'))
    end)

    it('controlLoop - LimitToGrooveJob set to true, just loops when player is not groove user', function()
        _G.Citizen.Wait = coroutine.yield
        _G.Config.LimitToGrooveJob = true
        gameData.isPlaying = false
        playerData.job = 'not groove'

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verifyNoCall(_G.Wrapper.IsControlJustPressed(1, 1))
    end)

    it('controlLoop - LimitToGrooveJob set to true, switches to checking for input when job changes', function()
        registerJobChangeListener()

        _G.Citizen.Wait = coroutine.yield
        _G.Config.LimitToGrooveJob = true
        gameData.isPlaying = false
        playerData.job = {name = 'not groove'}

        local loop = coroutine.create(controlLoop)
        iterateLoop(loop)

        verifyNoCall(_G.Wrapper.IsControlJustPressed(1, 1))

        setPlayerJob({name = 'groove'})
        iterateLoop(loop)
        iterateLoop(loop)

        verify(_G.Wrapper.IsControlJustPressed(1, 1))
    end)

    it('mainLoop - triggers terminate event when playing and player not in groove', function()
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        mockCommonGatherDataCalls()
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer(nil)
        when(_G.Wrapper._('terminate_left_groove')).thenAnswer('terminate_left_groove translated')

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_left_groove translated', true))
    end)
    
    it('mainLoop - triggers terminate event when playing and groove is broken', function()
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        mockCommonGatherDataCalls()
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer('vehicleObject')
        when(_G.Wrapper.IsVehicleModel('vehicleObject', 'GROOVE')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleDriveable('vehicleObject', true)).thenAnswer(false)
        when(_G.Wrapper._('terminate_destroyed_groove')).thenAnswer('terminate_destroyed_groove translated')

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_destroyed_groove translated', true))
    end)
    
    it('mainLoop - triggers terminate event when playing and player is dead', function()
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        when(_G.Wrapper.PlayerPedId()).thenAnswer('ped id')
        when(_G.Wrapper.GetEntityCoords('ped id')).thenAnswer('positionObject')
        when(_G.Wrapper.IsPedDeadOrDying('ped id', true)).thenAnswer(true)
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer('vehicleObject')
        when(_G.Wrapper.IsVehicleModel('vehicleObject', 'GROOVE')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleDriveable('vehicleObject', true)).thenAnswer(true)
        when(_G.Wrapper._('terminate_you_died')).thenAnswer('terminate_you_died translated')

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_you_died translated', true))
    end)
    
    it('mainLoop - triggers terminate event when patient dies', function()
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        gameData.peds = {{model = 'pedObject'}}
        mockCommonGatherDataCalls()
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer('vehicleObject')
        when(_G.Wrapper.IsVehicleModel('vehicleObject', 'GROOVE')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleDriveable('vehicleObject', true)).thenAnswer(true)
        when(_G.Wrapper._('terminate_patient_died')).thenAnswer('terminate_patient_died translated')
        when(_G.Wrapper.IsPedDeadOrDying('pedObject', 1)).thenAnswer(true)

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_patient_died translated', true))
    end)
    
    it('mainLoop - shows start game notification when player enters groove -- using default GROOVE model when no config value provided', function()
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = false
        playerData.isInGroove = false
        mockCommonGatherDataCalls()
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer('vehicleObject')
        when(_G.Wrapper.IsVehicleModel('vehicleObject', 'GROOVE')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleDriveable('vehicleObject', true)).thenAnswer(true)
        when(_G.Wrapper._('start_game_help')).thenAnswer('start_game_help translated')

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(esx.ShowHelpNotification('start_game_help translated'))
    end)
    
    it('mainLoop - shows start game notification when player enters groove -- using model from config', function()
        _G.Config.GrooveModel = 'CUSTOM'
        Citizen.Wait = coroutine.yield
        gameData.isPlaying = false
        playerData.isInGroove = false
        mockCommonGatherDataCalls()
        when(_G.Wrapper.GetVehiclePedIsIn('ped id', false)).thenAnswer('vehicleObject')
        when(_G.Wrapper.IsVehicleModel('vehicleObject', 'CUSTOM')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleDriveable('vehicleObject', true)).thenAnswer(true)
        when(_G.Wrapper._('start_game_help')).thenAnswer('start_game_help translated')

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verify(esx.ShowHelpNotification('start_game_help translated'))
    end)

    it('mainLoop - does not gather data when LimitToGrooveJob and not groove job', function()
        _G.Config.LimitToGrooveJob = true
        playerData.job = 'not groove'
        Citizen.Wait = coroutine.yield

        local loop = coroutine.create(mainLoop)
        iterateLoop(loop)

        verifyNoCall(_G.Wrapper.PlayerPedId())
    end)

    function mockCommonGatherDataCalls()
        when(_G.Wrapper.PlayerPedId()).thenAnswer('ped id')
        when(_G.Wrapper.GetEntityCoords('ped id')).thenAnswer('positionObject')
        when(_G.Wrapper.IsPedDeadOrDying('ped id', true)).thenAnswer(false)
    end

    it('areAnyPatientsDead - no peds', function()
        gameData.peds = {}

        assert.is_false(areAnyPatientsDead())

        verifyNoCall(_G.Wrapper.IsPedDeadOrDying(any(), 1))
    end)
    
    it('areAnyPatientsDead - no peds dead', function()
        when(_G.Wrapper.IsPedDeadOrDying('pedObject 1', 1)).thenAnswer(false)
        when(_G.Wrapper.IsPedDeadOrDying('pedObject 2', 1)).thenAnswer(false)
        when(_G.Wrapper.IsPedDeadOrDying('pedObject 3', 1)).thenAnswer(false)
        gameData.peds = {{model = 'pedObject 1'}, {model = 'pedObject 2'}, {model = 'pedObject 3'}}

        assert.is_false(areAnyPatientsDead())
    end)
    
    it('areAnyPatientsDead - one ped dead', function()
        when(_G.Wrapper.IsPedDeadOrDying('pedObject 1', 1)).thenAnswer(false)
        when(_G.Wrapper.IsPedDeadOrDying('pedObject 2', 1)).thenAnswer(true)
        gameData.peds = {{model = 'pedObject 1'}, {model = 'pedObject 2'}, {model = 'pedObject 3'}}

        assert.is_true(areAnyPatientsDead())

        verifyNoCall(_G.Wrapper.IsPedDeadOrDying('pedObject 3', 1))
    end)

    it('handleGrooveDamageDetection - no peds in groove, no damage taken', function()
        playerData.vehicle = 'vehicleObject'
        gameData.pedsInGroove = {}
        gameData.lastVehicleHealth = 1000
        gameData.secondsLeft = 100

        when(_G.Wrapper.GetVehicleBodyHealth('vehicleObject')).thenAnswer(1000)

        handleGrooveDamageDetection()

        assert.equals(1000, gameData.lastVehicleHealth)
        assert.equals(100, gameData.secondsLeft)
        verifyNoCall(Scaleform.ShowRemoveTime(any()))
        verifyNoCall(_G.Wrapper.PlaySoundFrontend(any(), any(), any(), any()))
    end)
    
    it('handleGrooveDamageDetection - no peds in groove, damage taken - no time lost', function()
        playerData.vehicle = 'vehicleObject'
        gameData.pedsInGroove = {}
        gameData.lastVehicleHealth = 1000
        gameData.secondsLeft = 100

        when(_G.Wrapper.GetVehicleBodyHealth('vehicleObject')).thenAnswer(500)

        handleGrooveDamageDetection()

        assert.equals(500, gameData.lastVehicleHealth)
        assert.equals(100, gameData.secondsLeft)
        verifyNoCall(Scaleform.ShowRemoveTime(any()))
        verifyNoCall(_G.Wrapper.PlaySoundFrontend(any(), any(), any(), any()))
    end)
    
    it('handleGrooveDamageDetection - peds in groove, no damage taken - no time lost', function()
        playerData.vehicle = 'vehicleObject'
        gameData.pedsInGroove = {'pedObject'}
        gameData.lastVehicleHealth = 1000
        gameData.secondsLeft = 100

        when(_G.Wrapper.GetVehicleBodyHealth('vehicleObject')).thenAnswer(1000)

        handleGrooveDamageDetection()

        assert.equals(1000, gameData.lastVehicleHealth)
        assert.equals(100, gameData.secondsLeft)
        verifyNoCall(Scaleform.ShowRemoveTime(any()))
        verifyNoCall(_G.Wrapper.PlaySoundFrontend(any(), any(), any(), any()))
    end)
    
    it('handleGrooveDamageDetection - peds in groove, damage taken - time lost', function()
        playerData.vehicle = 'vehicleObject'
        gameData.pedsInGroove = {'pedObject'}
        gameData.lastVehicleHealth = 1000
        gameData.secondsLeft = 100
        when(_G.Wrapper._('time_added', -50)).thenAnswer('time added translated')
        when(_G.Wrapper.GetVehicleBodyHealth('vehicleObject')).thenAnswer(950)
        _G.Config.Formulas.timeLostForDamage = function(damage) return damage end

        handleGrooveDamageDetection()

        assert.equals(950, gameData.lastVehicleHealth)
        assert.equals(50, gameData.secondsLeft)
        verify(Scaleform.ShowRemoveTime('time added translated'))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName', 'AudioRef', 1))
    end)

    it('findNearestGroove - first is nearest', function()
        local playerCoords = createCoords(0, 0, 0)
        _G.Config.Groove = {createCoords(1, 2, 3), createCoords(2, 3, 4), createCoords(3, 4, 5)}
        when(_G.Wrapper.vector3(0, 0, 0)).thenAnswer(playerCoords)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 1, 2, 3, false)).thenAnswer(5.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 2, 3, 4, false)).thenAnswer(6.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 3, 4, 5, false)).thenAnswer(7.0)

        local result = findNearestGroove(playerCoords)

        assert.equals(_G.Config.Groove[1], result)
    end)
    
    it('findNearestGroove - second is nearest', function()
        local playerCoords = createCoords(0, 0, 0)
        _G.Config.Groove = {createCoords(1, 2, 3), createCoords(2, 3, 4), createCoords(3, 4, 5)}
        when(_G.Wrapper.vector3(0, 0, 0)).thenAnswer(playerCoords)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 1, 2, 3, false)).thenAnswer(6.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 2, 3, 4, false)).thenAnswer(5.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 3, 4, 5, false)).thenAnswer(7.0)

        local result = findNearestGroove(playerCoords)

        assert.equals(_G.Config.Groove[2], result)
    end)

    it('terminateGame - failed', function()
        gameData.isPlaying = true
        gameData.peds = {{model = 'model 1'}, {model = 'model 2'}}
        gameData.pedsInGroove = {{model = 'model 3'}}
        when(_G.Wrapper._('terminate_failed')).thenAnswer('terminate_failed translated')

        terminateGame('reason for terminating', true)

        verify(_G.Scaleform.ShowWasted('terminate_failed translated', 'reason for terminating', 5))
        assertCommonExpectationsForTerminateGame('failed')
    end)

    it('terminateGame - won', function()
        gameData.isPlaying = true
        gameData.peds = {{model = 'model 1'}, {model = 'model 2'}}
        gameData.pedsInGroove = {{model = 'model 3'}}

        terminateGame('reason for terminating', false)

        verifyNoCall(_G.Wrapper._(any()))
        verify(_G.Scaleform.ShowPassed())
        assertCommonExpectationsForTerminateGame('passed')
    end)

    function assertCommonExpectationsForTerminateGame(sound)
        assert.is_false(gameData.isPlaying)
        verify(_G.Markers.StopMarkers())
        verify(_G.Overlay.Stop())
        verify(_G.Blips.StopBlips())
        verify(_G.Peds.DeletePeds({'model 1', 'model 2'}))
        verify(_G.Peds.DeletePeds({'model 3'}))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName ' .. sound, 'AudioRef ' .. sound, 1))
    end

    it('startGame', function()
        local playerCoords = createCoords(0, 0, 0)
        _G.Config.Groove = {
            {x = 1, y = 2, z = 3, spawnPoints = {createCoords(1, 2, 3)}}
        }
        _G.Config.InitialSeconds = 120
        playerData.vehicle = 'vehicleObject'
        when(_G.Wrapper.vector3(0, 0, 0)).thenAnswer(playerCoords)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 1, 2, 3, false)).thenAnswer(5.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 2, 3, 4, false)).thenAnswer(6.0)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerCoords, 3, 4, 5, false)).thenAnswer(7.0)
        when(_G.Wrapper.GetVehicleBodyHealth('vehicleObject')).thenAnswer(1000)

        startGame()

        assert.equals(_G.Config.Groove[1], gameData.grooveLocation)
        assert.equals(120, gameData.secondsLeft)
        assert.equals(1, gameData.level)
        assert.equals(0, #gameData.peds)
        assert.equals(0, #gameData.pedsInGroove)
        assert.equals(1000, gameData.lastVehicleHealth)
        assert.is_true(gameData.isPlaying)
        verify(_G.Overlay.Start(gameData))
        verify(_G.Markers.StartMarkers(_G.Config.Groove[1]))
        verify(_G.Blips.StartBlips(_G.Config.Groove[1]))
    end)

    it('timerLoop - terminates thread when not playing', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = false

        local loop = coroutine.create(timerLoop)
        iterateLoop(loop)

        assert.equals('dead', coroutine.status(loop))
    end)
    
    it('timerLoop - updates overlay and subtracts a second', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        gameData.secondsLeft = 10

        local loop = coroutine.create(timerLoop)
        iterateLoop(loop)
        iterateLoop(loop)

        assert.equals('suspended', coroutine.status(loop))
        assert.equals(9, gameData.secondsLeft)
        verify(_G.Overlay.Update(gameData))
    end)
    
    it('timerLoop - terminates game when 0 seconds left', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        gameData.secondsLeft = 1
        when(_G.Wrapper._('terminate_out_of_time')).thenAnswer('terminate_out_of_time translated')

        local loop = coroutine.create(timerLoop)
        iterateLoop(loop)
        iterateLoop(loop)

        assert.equals('suspended', coroutine.status(loop))
        assert.equals(0, gameData.secondsLeft)
        verify(_G.Overlay.Update(gameData))
        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_out_of_time translated', true))
    end)

    it('gameLoop - terminates thread when not playing', function()
        local dropOffSpy, pickUpSpy, originalDropOff, originalPickUp = setupSpiesForGameLoop()

        local loop = coroutine.create(gameLoop)
        iterateLoop(loop)
        restoreDropOffAndPickup(originalDropOff, originalPickUp)

        assert.equals('dead', coroutine.status(loop))
        assert.spy(dropOffSpy).was.called(0)
        assert.spy(pickUpSpy).was.called(0)
    end)

    it('gameLoop - in distance of groove - does drop off when there are peds in groove', function()
        _G.Citizen.Wait = coroutine.yield
        local dropOffSpy, pickUpSpy, originalDropOff, originalPickUp = setupSpiesForGameLoop()
        playerData.position = createCoords(1, 2, 3)
        gameData.isPlaying = true
        gameData.grooveLocation = createCoords(1, 2, 3)
        gameData.pedsInGroove = {'pedObject'}
        when(_G.Wrapper.vector3(1, 2, 3)).thenAnswer(playerData.position)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(0.0)

        local loop = coroutine.create(gameLoop)
        iterateLoop(loop)
        restoreDropOffAndPickup(originalDropOff, originalPickUp)

        assert.equals('suspended', coroutine.status(loop))
        assert.spy(dropOffSpy).was.called(1)
        assert.spy(pickUpSpy).was.called(0)
    end)

    it('gameLoop - in distance of groove - calls handle patient pickups when no ped in groove', function()
        _G.Citizen.Wait = coroutine.yield
        local dropOffSpy, pickUpSpy, originalDropOff, originalPickUp = setupSpiesForGameLoop()
        playerData.position = createCoords(1, 2, 3)
        gameData.isPlaying = true
        gameData.grooveLocation = createCoords(1, 2, 3)
        gameData.pedsInGroove = {}
        when(_G.Wrapper.vector3(1, 2, 3)).thenAnswer(playerData.position)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(0.0)

        local loop = coroutine.create(gameLoop)
        iterateLoop(loop)
        restoreDropOffAndPickup(originalDropOff, originalPickUp)

        assert.equals('suspended', coroutine.status(loop))
        assert.spy(dropOffSpy).was.called(0)
        assert.spy(pickUpSpy).was.called(1)
    end)

    it('gameLoop - not in distance of groove - calls handle patient pickups', function()
        _G.Citizen.Wait = coroutine.yield
        local dropOffSpy, pickUpSpy, originalDropOff, originalPickUp = setupSpiesForGameLoop()
        playerData.position = createCoords(1, 2, 3)
        gameData.isPlaying = true
        gameData.grooveLocation = createCoords(1, 2, 3)
        gameData.pedsInGroove = {}
        when(_G.Wrapper.vector3(1, 2, 3)).thenAnswer(playerData.position)
        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(15.0)

        local loop = coroutine.create(gameLoop)
        iterateLoop(loop)
        restoreDropOffAndPickup(originalDropOff, originalPickUp)

        assert.equals('suspended', coroutine.status(loop))
        assert.spy(dropOffSpy).was.called(0)
        assert.spy(pickUpSpy).was.called(1)
    end)

    function setupSpiesForGameLoop()
        local originalDropOff = _G.handlePatientDropOff
        local originalPickUp = _G.handlePatientPickUps
        _G.handlePatientDropOff = function() end
        _G.handlePatientPickUps = function() end
        return spy.on(_G, 'handlePatientDropOff'), spy.on(_G, 'handlePatientPickUps'), originalDropOff, originalPickUp
    end

    function restoreDropOffAndPickup(originalDropOff, originalPickUp)
        _G.handlePatientDropOff = originalDropOff
        _G.handlePatientPickUps = originalPickUp
    end

    it('handlePatientDropOff - awards more time when there are still more peds to pick up', function()
        playerData.vehicle = 'vehicleObject'
        gameData.isPlaying = true
        gameData.pedsInGroove = {{model = 'model 1'}}
        gameData.peds = {'pedObject 2', 'pedObject 3'}
        gameData.secondsLeft = 10
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper._('time_added', any())).thenAnswer('time_added translated')
        _G.Config.Formulas.additionalTimeForDropOff = function() return 30 end

        handlePatientDropOff()

        assert.equals(0, #gameData.pedsInGroove)
        assert.equals(40, gameData.secondsLeft)
        verify(_G.Peds.DeletePeds({'model 1'}))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName added', 'AudioRef added', 1))
    end)

    it('handlePatientDropOff - no more peds - ends game when finishing last level', function()
        playerData.vehicle = 'vehicleObject'
        gameData.isPlaying = true
        gameData.pedsInGroove = {{model = 'model 1'}, {model = 'model 2'}, {model = 'model 3'}}
        gameData.peds = {}
        gameData.secondsLeft = 10
        gameData.level = 3
        _G.Config.MaxLevels = 3
        _G.Config.Formulas.moneyPerLevel = function() return 5 end
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper._('terminate_finished')).thenAnswer('terminate_finished translated')
        when(_G.Wrapper._('add_money', 5)).thenAnswer('add_money translated')

        handlePatientDropOff()

        assert.equals(0, #gameData.pedsInGroove)
        verify(_G.Peds.DeletePeds({'model 1', 'model 2', 'model 3'}))
        verify(_G.Wrapper.TriggerServerEvent('blarglegroove:finishLevel', 3))
        verify(_G.Wrapper.TriggerEvent('blarglegroove:terminateGame', 'terminate_finished translated', false))
        verifyNoCall(_G.Wrapper.PlaySoundFrontend(any(), any(), any(), any()))
        verify(_G.Scaleform.ShowAddMoney('add_money translated'))
    end)

    it('handlePatientDropOff - no more peds - starts next level when not on last level', function()
        playerData.vehicle = 'vehicleObject'
        gameData.isPlaying = true
        gameData.pedsInGroove = {{model = 'model 1'}, {model = 'model 2'}, {model = 'model 3'}}
        gameData.peds = {}
        gameData.secondsLeft = 10
        gameData.level = 3
        _G.Config.MaxLevels = 5
        _G.Config.Formulas.moneyPerLevel = function() return 5 end
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper._('add_money', 5)).thenAnswer('add_money translated')

        handlePatientDropOff()

        assert.equals(0, #gameData.pedsInGroove)
        assert.equals(4, gameData.level)
        verify(_G.Peds.DeletePeds({'model 1', 'model 2', 'model 3'}))
        verify(_G.Wrapper.TriggerServerEvent('blarglegroove:finishLevel', 3))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName added', 'AudioRef added', 1))
        verify(_G.Scaleform.ShowAddMoney('add_money translated'))
    end)

    it('mapPedsToModel -- no peds', function()
        local result = mapPedsToModel({})

        assert.equals(0, #result)
    end)
    
    it('mapPedsToModel', function()
        local result = mapPedsToModel({{model = 'model 1'}, {model = 'model 2'}})

        assert.equals(2, #result)
        assert.equals('model 1', result[1])
        assert.equals('model 2', result[2])
    end)

    it('handlePatientPickUps - no peds to pick up', function()
        gameData.peds = {}

        handlePatientPickUps()
    end)

    it('handlePatientPickUps - no peds within distance', function()
        playerData.position = createCoords(1, 2, 3)
        gameData.peds = {{coords = createCoords(100, 100, 100)}}
        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 100, 100, 100, false)).thenAnswer(100.0)

        handlePatientPickUps()
    end)

    it('handlePatientPickUps - no peds within distance for pickup - removes invincibility of ped when in range', function()
        playerData.position = createCoords(1, 2, 3)
        gameData.peds = {{model = 'pedModel', coords = createCoords(100, 100, 100)}}
        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 100, 100, 100, false)).thenAnswer(25.0)

        handlePatientPickUps()

        verify(_G.Peds.SetInvincibility('pedModel', false))
        verifyNoCall(_G.Peds.EnterVehicle('ped model', 'vehicleObject', 1))
    end)

    it('handlePatientPickUps - ped in distance - displays return to groove message when groove full', function()
        playerData.position = createCoords(1, 2, 3)
        playerData.vehicle = 'vehicleObject'
        gameData.grooveLocation = createCoords(50, 50, 50)
        gameData.peds = {{model = 'ped model', coords = createCoords(1, 2, 3)}}
        gameData.isPlaying = true
        gameData.pedsInGroove = {'ped 2 object', 'ped 3 object'}
        gameData.secondsLeft = 30
        _G.Config.Formulas.additionalTimeForPickup = function(distance) return distance end

        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(10.0)
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 1)).thenAnswer(true)
        when(_G.Peds.IsPedInVehicleOrTooFarAway('ped model', gameData.peds[1].coords)).thenAnswer(true)
        when(_G.Wrapper.GetDistanceBetweenCoords(gameData.peds[1].coords, 50, 50, 50, false)).thenAnswer(10.0)
        when(_G.Wrapper._('time_added', any())).thenAnswer('time_added translated')
        when(_G.Wrapper._('return_to_groove_header')).thenAnswer('return_to_groove_header translated')
        when(_G.Wrapper._('return_to_groove_sub_full')).thenAnswer('return_to_groove_sub_full translated')

        handlePatientPickUps()

        assert.equals(3, #gameData.pedsInGroove)
        assert.equals(0, #gameData.peds)
        assert.equals(40.0, gameData.secondsLeft)
        verify(_G.Peds.EnterVehicle('ped model', 'vehicleObject', 1))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName added', 'AudioRef added', 1))
        verify(_G.Overlay.Update(any()))
        verify(_G.Scaleform.ShowMessage('return_to_groove_header translated', 'return_to_groove_sub_full translated', 5))
    end)
    
    it('handlePatientPickUps - ped in distance - displays return to groove message when no more peds', function()
        playerData.position = createCoords(1, 2, 3)
        playerData.vehicle = 'vehicleObject'
        gameData.grooveLocation = createCoords(50, 50, 50)
        gameData.peds = {{model = 'ped model', coords = createCoords(1, 2, 3)}}
        gameData.isPlaying = true
        gameData.pedsInGroove = {}
        gameData.secondsLeft = 30
        _G.Config.Formulas.additionalTimeForPickup = function(distance) return distance end

        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(10.0)
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 1)).thenAnswer(true)
        when(_G.Peds.IsPedInVehicleOrTooFarAway('ped model', gameData.peds[1].coords)).thenAnswer(true)
        when(_G.Wrapper.GetDistanceBetweenCoords(gameData.peds[1].coords, 50, 50, 50, false)).thenAnswer(10.0)
        when(_G.Wrapper._('time_added', any())).thenAnswer('time_added translated')
        when(_G.Wrapper._('return_to_groove_header')).thenAnswer('return_to_groove_header translated')
        when(_G.Wrapper._('return_to_groove_sub_end_level')).thenAnswer('return_to_groove_sub_end_level translated')

        handlePatientPickUps()

        assert.equals(1, #gameData.pedsInGroove)
        assert.equals(0, #gameData.peds)
        assert.equals(40.0, gameData.secondsLeft)
        verify(_G.Peds.EnterVehicle('ped model', 'vehicleObject', 1))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName added', 'AudioRef added', 1))
        verify(_G.Overlay.Update(any()))
        verify(_G.Scaleform.ShowMessage('return_to_groove_header translated', 'return_to_groove_sub_end_level translated', 5))
    end)
    
    it('handlePatientPickUps - ped in distance - does not display return to groove message when not full and there are more peds', function()
        playerData.position = createCoords(1, 2, 3)
        playerData.vehicle = 'vehicleObject'
        gameData.grooveLocation = createCoords(50, 50, 50)
        gameData.peds = {{model = 'ped model', coords = createCoords(1, 2, 3)}, {model = 'ped model 2', coords = createCoords(2, 3, 4)}}
        gameData.isPlaying = true
        gameData.pedsInGroove = {}
        gameData.secondsLeft = 30
        _G.Config.Formulas.additionalTimeForPickup = function(distance) return distance end

        when(_G.Wrapper.GetDistanceBetweenCoords(playerData.position, 1, 2, 3, false)).thenAnswer(10.0)
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 1)).thenAnswer(true)
        when(_G.Peds.IsPedInVehicleOrTooFarAway('ped model', gameData.peds[1].coords)).thenAnswer(true)
        when(_G.Wrapper.GetDistanceBetweenCoords(gameData.peds[1].coords, 50, 50, 50, false)).thenAnswer(10.0)
        when(_G.Wrapper._('time_added', any())).thenAnswer('time_added translated')
        when(_G.Wrapper._('return_to_groove_header')).thenAnswer('return_to_groove_header translated')
        when(_G.Wrapper._('return_to_groove_sub_end_level')).thenAnswer('return_to_groove_sub_end_level translated')

        handlePatientPickUps()

        assert.equals(1, #gameData.pedsInGroove)
        assert.equals(1, #gameData.peds)
        assert.equals(40.0, gameData.secondsLeft)
        verify(_G.Peds.EnterVehicle('ped model', 'vehicleObject', 1))
        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName added', 'AudioRef added', 1))
        verify(_G.Overlay.Update(any()))
        verifyNoCall(_G.Scaleform.ShowMessage('return_to_groove_header translated', 'return_to_groove_sub_end_level translated', 5))
    end)

    it('setupLevel creates level-appropriate number of peds - level 1', function()
        gameData.level = 1
        when(_G.Peds.CreateRandomPedInArea(any(), any())).thenAnswer('pedObject')
        when(_G.Wrapper._('start_level_header', 1)).thenAnswer('level header translated')
        when(_G.Wrapper._('start_level_sub_one')).thenAnswer('submessage translated')

        setupLevel()

        assert.equals(1, #gameData.peds)
        assert.equals('pedObject', gameData.peds[1])
        verify(_G.Scaleform.ShowMessage('level header translated', 'submessage translated', 5))
    end)

    it('setupLevel creates level-appropriate number of peds - level 3', function()
        gameData.level = 3
        when(_G.Peds.CreateRandomPedInArea(any(), any())).thenAnswer('pedObject')
        when(_G.Wrapper._('start_level_header', 3)).thenAnswer('level header translated')
        when(_G.Wrapper._('start_level_sub_multi', 3)).thenAnswer('submessage translated')

        setupLevel()

        assert.equals(3, #gameData.peds)
        assert.equals('pedObject', gameData.peds[1])
        assert.equals('pedObject', gameData.peds[2])
        assert.equals('pedObject', gameData.peds[3])
        verify(_G.Scaleform.ShowMessage('level header translated', 'submessage translated', 5))
    end)

    it('getDistance creates vector and calls native', function()
        coords1 = createCoords(1, 2, 3)
        coords2 = createCoords(4, 5, 6)
        when(_G.Wrapper.vector3(1, 2, 3)).thenAnswer(coords1)
        when(_G.Wrapper.GetDistanceBetweenCoords(coords1, 4, 5, 6, false)).thenAnswer(5)

        local result = getDistance(coords1, coords2)

        assert.equals(5, result)
    end)

    it('displayMessageAndWaitUntilStopped - ends when game ends', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        playerData.vehicle = 'vehicleObject'
        when(_G.Wrapper._('message')).thenAnswer('message translated')
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(false)

        local loop = coroutine.create(function() displayMessageAndWaitUntilStopped('message') end)
        iterateLoop(loop)

        verify(esx.ShowNotification('message translated'))
        assert.equals('suspended', coroutine.status(loop))

        iterateLoop(loop)
        assert.equals('suspended', coroutine.status(loop))

        gameData.isPlaying = false

        iterateLoop(loop)
        assert.equals('dead', coroutine.status(loop))
    end)

    it('displayMessageAndWaitUntilStopped - skips when vehicle is stopped', function()
        _G.Citizen.Wait = coroutine.yield
        gameData.isPlaying = true
        playerData.vehicle = 'vehicleObject'
        when(_G.Wrapper._('message')).thenAnswer('message translated')
        when(_G.Wrapper.IsVehicleStopped('vehicleObject')).thenAnswer(true)

        local loop = coroutine.create(function() displayMessageAndWaitUntilStopped('message') end)
        iterateLoop(loop)

        verifyNoCall(esx.ShowNotification('message translated'))
        assert.equals('dead', coroutine.status(loop))
    end)

    it('findFirstFreeSeat - has free seat', function()
        playerData.vehicle = 'vehicleObject'
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 1)).thenAnswer(false)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 2)).thenAnswer(true)

        assert.equals(2, findFirstFreeSeat())

        verifyNoCall(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 3))
    end)

    it('findFirstFreeSeat - no free seats', function()
        playerData.vehicle = 'vehicleObject'
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 1)).thenAnswer(false)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 2)).thenAnswer(false)
        when(_G.Wrapper.IsVehicleSeatFree('vehicleObject', 3)).thenAnswer(false)

        assert.equals(0, findFirstFreeSeat())
    end)

    it('updateMarkersAndBlips - no peds', function()
        gameData.peds = {}
        gameData.pedsInGroove = {}

        updateMarkersAndBlips()

        verify(_G.Blips.UpdateBlips({}))
        verify(_G.Markers.UpdateMarkers({}))
        verify(_G.Blips.SetFlashGroove(false))
        verify(_G.Markers.SetShowGroove(false))
    end)

    it('updateMarkersAndBlips - has peds', function()
        gameData.peds = {{coords = 1}, {coords = 2}}
        gameData.pedsInGroove = {{coords = 3}, {coords = 4}}

        updateMarkersAndBlips()

        verify(_G.Blips.UpdateBlips({1, 2}))
        verify(_G.Markers.UpdateMarkers({1, 2}))
        verify(_G.Blips.SetFlashGroove(true))
        verify(_G.Markers.SetShowGroove(true))
    end)

    it('playSound calls native', function()
        playSound(_G.Config.Sounds.timeRemoved)

        verify(_G.Wrapper.PlaySoundFrontend(-1, 'AudioName', 'AudioRef', 1))
    end)

    function iterateLoop(loop)
        coroutine.resume(loop)
    end

    function createCoords(x, y, z)
        return {x = x, y = y, z = z}
    end
end)