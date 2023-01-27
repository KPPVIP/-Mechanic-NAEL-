Config = {}
Config.Locale = 'fr'
Config.DoorList = {

	{
		objName = 'v_ilev_ss_door04',
		objYaw = 53.10,
		objCoords  = vector3(-115.60, -1778.36, 29.83),
		textCoords = vector3(-115.60, -1778.36, 29.83),
		needJob = true, -- Job is needed with the key ? 
		authorizedJobs = { 'groove' },
		keyNeeded = 'green-keycard', --The Item needed to open
		removekey = false, -- Remove key from inventory once used
		locked = true -- Default state is locked or not
	},

		{
		objName = 'v_ilev_phroofdoor',
		objYaw = 48.91,
		objCoords  = vector3(-112.36, -1790.32, 24.13),
		textCoords = vector3(-112.36, -1790.32, 24.13),
		needJob = true, -- Job is needed with the key ? 
		authorizedJobs = { 'groove' },
		keyNeeded = 'green-keycard', --The Item needed to open
		removekey = false, -- Remove key from inventory once used
		locked = true -- Default state is locked or not
	},

	{
		objName = 'v_ilev_ra_door2',
		objYaw = 139.19,
		objCoords  = vector3(-103.10, -1791.70, 32.19),
		textCoords = vector3(-103.10, -1791.70, 32.19),
		needJob = true, -- Job is needed with the key ? 
		authorizedJobs = { 'groove' },
		keyNeeded = 'green-keycard', --The Item needed to open
		removekey = false,
		locked = true -- Default state is locked or not
	}

}