local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
  }

scanId = 0
cityRobbery = false
local myspawns = {}
CCTVCamLocations = {
	[1] =  { ['x'] = 956.35,['y'] = 39.80,['z'] = 82.92,['h'] = 315.45, ['info'] = ' Camera Outside 1', ["recent"] = false },
	[2] =  { ['x'] = 971.12,['y'] = 81.55,['z'] = 82.45,['h'] = 193.04, ['info'] = ' Camera Outside 2', ["recent"] = false },
	[3] =  { ['x'] = 931.44,['y'] = -1.05,['z'] = 81.50,['h'] = 201.36, ['info'] = ' Camera Outside 3', ["recent"] = false },
	[4] =  { ['x'] = 930.73,['y'] = 49.61,['z'] = 82.03,['h'] = 184.19, ['info'] = ' Camera Interior 1', ["recent"] = false },
	[5] =  { ['x'] = 2544.13,['y'] = -285.60,['z'] = -57.52,['h'] = 72.39, ['info'] = ' Camera Interior 2', ["recent"] = false },
	[6] =  { ['x'] = 2520.85,['y'] = -285.24,['z'] = -58.72,['h'] = 333.40, ['info'] = ' Camera Interior 3', ["recent"] = false },
	[7] =  { ['x'] = 2537.66,['y'] = -273.78,['z'] = -70.69,['h'] = 131.69, ['info'] = ' Camera Interior 4', ["recent"] = false },
	[8] =  { ['x'] = 2492.13,['y'] = -285.22,['z'] = -70.69,['h'] = 37.71, ['info'] = ' Camera Interior 5', ["recent"] = false },
	[9] =  { ['x'] = 2509.98,['y'] = -242.74,['z'] = -70.73,['h'] = 302.31, ['info'] = ' Camera Interior 6', ["recent"] = false },
	[10] =  { ['x'] = -83.44,['y'] = -1832.32,['z'] = 31.05,['h'] = 16.16, ['info'] = ' Camera Interior 5', ["recent"] = false },
	[11] =  { ['x'] = -68.44,['y'] = -1812.16,['z'] = 33.09,['h'] = 87.40, ['info'] = ' Camera Interior 1', ["recent"] = false },
	[12] =  { ['x'] = -99.48,['y'] = -1785.74,['z'] = 33.06,['h'] = 209.11, ['info'] = ' Camera Interior 2', ["recent"] = false },
	[13] =  { ['x'] = -111.86,['y'] = -1774.75,['z'] = 31.83,['h'] = 179.33, ['info'] = ' Camera Interior 3', ["recent"] = false },
	[14] =  { ['x'] = -110.75,['y'] = -1787.94,['z'] = 26.13,['h'] = 102.94, ['info'] = ' Camera Interior 4', ["recent"] = false },
	[15] =  { ['x'] = -83.98,['y'] = -1834.81,['z'] = 30.70,['h'] = 282.03, ['info'] = ' Camera Outside 1', ["recent"] = false },
	--[16] =  { ['x'] = 1392.88,['y'] = 3606.7,['z'] = 34.99,['h'] = 201.69, ['info'] = ' Store Camera 16', ["recent"] = false },
	--[17] =  { ['x'] = 1697.8,['y'] = 4922.69,['z'] = 42.07,['h'] = 322.95, ['info'] = ' Store Camera 17', ["recent"] = false },
	--[18] =  { ['x'] = 1728.82,['y'] = 6417.38,['z'] = 35.04,['h'] = 233.94, ['info'] = ' Store Camera 18', ["recent"] = false },
	--[19] =  { ['x'] = 733.45,['y'] = 127.58,['z'] = 80.69,['h'] = 285.51, ['info'] = ' Cam Power' },
	--[20] =  { ['x'] = 1887.25,['y'] = 2605.35,['z'] = 50.40,['h'] = 111.88, ['info'] = ' Cam Jail Front' },
	--[21] =  { ['x'] = 1709.37,['y'] = 2569.90,['z'] = 56.18,['h'] = 50.18, ['info'] = ' Cam Jail Prisoner Drop Off' },
	--[22] =  { ['x'] = -644.24,['y'] = -241.11,['z'] = 37.97,['h'] = 282.81, ['info'] = ' Cam Jewelry Store' },
	--[23] =  { ['x'] = -115.3,['y'] = 6441.41,['z'] = 31.53,['h'] = 341.95, ['info'] = ' Cam Paleto Bank Outside' },
	--[24] =  { ['x'] = 240.07,['y'] = 218.97,['z'] = 106.29,['h'] = 276.14, ['info'] = ' Cam Main Bank 1' },
	--[25] =  { ['x'] = 92.17,['y'] = -1923.14,['z'] = 29.5,['h'] = 205.95, ['info'] = ' Ballas', ["recent"] = false },
	--[26] =  { ['x'] = -176.26,['y'] = -1681.15,['z'] = 47.43,['h'] = 313.29, ['info'] = ' Famillies', ["recent"] = false },
	--[27] =  { ['x'] = 285.95,['y'] = -2003.95,['z'] = 35.0,['h'] = 226.0, ['info'] = ' Vagos', ["recent"] = false },	
}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
	  TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	  Citizen.Wait(0)
	  PlayerData = ESX.GetPlayerData()
	end
  end)

RegisterCommand("mechanictv", function (source, args, rawCommand)

	local cam = args[1]

	local xPlayer = ESX.GetPlayerData()
	local job = xPlayer.job
	local jobname = xPlayer.job.name
	if job and jobname == 'groove' then
		TriggerEvent('cctv:camera', cam)
	end

end)

inCam = false
cctvCam = 0
RegisterNetEvent("cctv:camera")
AddEventHandler("cctv:camera", function(camNumber)
	camNumber = tonumber(camNumber)
	if inCam then
		inCam = false
		PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
		-- TriggerEvent('animation:tablet',false)
		Wait(250)
		ClearPedTasks(GetPlayerPed(-1))
	else
		if camNumber > 0 and camNumber < #CCTVCamLocations+1 then
			PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
			TriggerEvent("cctv:startcamera",camNumber)
		else
			--exports['mythic_notify']:SendAlert('error', "This camera appears to be faulty")
			TriggerEvent('esx:showNotification', '~r~ Valeur Invalide.')
		end
	end
end)

RegisterNetEvent("cctv:startcamera")
AddEventHandler("cctv:startcamera", function(camNumber)

	-- TriggerEvent('animation:tablet',true)
	local camNumber = tonumber(camNumber)
	local x = CCTVCamLocations[camNumber]["x"]
	local y = CCTVCamLocations[camNumber]["y"]
	local z = CCTVCamLocations[camNumber]["z"]
	local h = CCTVCamLocations[camNumber]["h"]

	print("starting cam")
	inCam = true

	SetTimecycleModifier("heliGunCam")
	SetTimecycleModifierStrength(1.0)
	local scaleform = RequestScaleformMovie("TRAFFIC_CAM")
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end

	local lPed = GetPlayerPed(-1)
	cctvCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamCoord(cctvCam,x,y,z+1.2)						
	SetCamRot(cctvCam, -15.0,0.0,h)
	SetCamFov(cctvCam, 110.0)
	RenderScriptCams(true, false, 0, 1, 0)
	PushScaleformMovieFunction(scaleform, "PLAY_CAM_MOVIE")
	SetFocusArea(x, y, z, 0.0, 0.0, 0.0)
	PopScaleformMovieFunctionVoid()

	while inCam do
		SetCamCoord(cctvCam,x,y,z+1.2)						
		-- SetCamRot(cctvCam, -15.0,0.0,h)
		PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
		PushScaleformMovieFunctionParameterFloat(GetEntityCoords(h).z)
		PushScaleformMovieFunctionParameterFloat(1.0)
		PushScaleformMovieFunctionParameterFloat(GetCamRot(cctvCam, 2).z)
		PopScaleformMovieFunctionVoid()
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
		Citizen.Wait(1)
	end
	ClearFocus()
	ClearTimecycleModifier()
	RenderScriptCams(false, false, 0, 1, 0)
	SetScaleformMovieAsNoLongerNeeded(scaleform)
	DestroyCam(cctvCam, false)
	SetNightvision(false)
	SetSeethrough(false)	

end)

Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(0)
		if inCam then

			local rota = GetCamRot(cctvCam, 2)

			if IsControlPressed(1, Keys['N4']) then
				SetCamRot(cctvCam, rota.x, 0.0, rota.z + 0.7, 2)
			end

			if IsControlPressed(1, Keys['N6']) then
				SetCamRot(cctvCam, rota.x, 0.0, rota.z - 0.7, 2)
			end

			if IsControlPressed(1, Keys['N8']) then
				SetCamRot(cctvCam, rota.x + 0.7, 0.0, rota.z, 2)
			end

			if IsControlPressed(1, Keys['N5']) then
				SetCamRot(cctvCam, rota.x - 0.7, 0.0, rota.z, 2)
			end
		end
	end
end)