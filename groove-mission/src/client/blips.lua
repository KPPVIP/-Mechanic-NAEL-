Blips = {}
Blips.patientBlips = {}
Blips.grooveBlip = nil

function Blips.StartBlips(grooveLocation)
    Blips.grooveBlip = Blips.createAndInitBlip(grooveLocation, Wrapper._('blip_groove'), false, 446)
end

function Blips.UpdateBlips(coordsList)
    Blips.removeAllPatients()
    Blips.patientBlips = Stream.of(coordsList)
        .map(Blips.createPatientBlip)
        .collect()
end

function Blips.StopBlips()
    Blips.removeAllPatients()
    Wrapper.RemoveBlip(Blips.grooveBlip)
end

function Blips.SetFlashGroove(flashGroove)
    Wrapper.SetBlipFlashes(Blips.grooveBlip, flashGroove)
end

function Blips.removeAllPatients()
    Stream.of(Blips.patientBlips).forEach(Wrapper.RemoveBlip)
end

function Blips.createPatientBlip(coords)
    return Blips.createAndInitBlip(coords, Wrapper._('blip_patient'), true, 7)
end

function Blips.createAndInitBlip(coords, blipLabel, isFlashing, sprite)
    local blip = Wrapper.AddBlipForCoord(coords.x, coords.y, coords.z)
    Wrapper.SetBlipSprite(blip, sprite)
    Wrapper.SetBlipAsShortRange(blip, true)
    Wrapper.SetBlipFlashes(blip, isFlashing)
    Wrapper.BeginTextCommandSetBlipName('STRING')
    Wrapper.AddTextComponentString(blipLabel)
    Wrapper.EndTextCommandSetBlipName(blip)
    return blip
end