local mockagne = require 'mockagne'
local when = mockagne.when
local verify = mockagne.verify
local verifyNoCall = mockagne.verify_no_call

describe('client - blips', function()

    before_each(function()
        _G.unpack = table.unpack
        _G.Wrapper = mockagne.getMock()

        when(_G.Wrapper._('blip_groove')).thenAnswer('groove translated')
        when(_G.Wrapper._('blip_patient')).thenAnswer('patient translated')

        require('../../src/lib/stream')
        require('../../src/client/blips')
    end)

    it('StartBlips -- creates blip for groove', function()
        local blip = {}
        when(_G.Wrapper.AddBlipForCoord(1, 2, 3)).thenAnswer(blip)
        
        Blips.StartBlips(createCoords(1, 2, 3))

        verify(_G.Wrapper.SetBlipSprite(blip, 61))
        verify(_G.Wrapper.SetBlipAsShortRange(blip, true))
        verify(_G.Wrapper.SetBlipFlashes(blip, false))
        verify(_G.Wrapper.BeginTextCommandSetBlipName('STRING'))
        verify(_G.Wrapper.AddTextComponentString('groove translated'))
        verify(_G.Wrapper.EndTextCommandSetBlipName(blip))
    end)

    it('UpdateBlips -- does not call RemoveBlips when no existing patients', function()
        Blips.UpdateBlips({})

        verifyNoCall(_G.Wrapper.RemoveBlip)
    end)

    it('UpdateBlips -- calls RemoveBlips when existing patients', function()
        Blips.patientBlips = {'Blip 1', 'Blip 2', 'Blip 3'}
        
        Blips.UpdateBlips({})

        verify(_G.Wrapper.RemoveBlip('Blip 1', 1))
        verify(_G.Wrapper.RemoveBlip('Blip 2', 2))
        verify(_G.Wrapper.RemoveBlip('Blip 3', 3))
    end)

    it('UpdateBlips -- creates blip for each coordinate passed in', function()
        local blips = {{}, {}, {}}
        when(_G.Wrapper.AddBlipForCoord(1, 2, 3)).thenAnswer(blips[1])
        when(_G.Wrapper.AddBlipForCoord(2, 3, 4)).thenAnswer(blips[2])
        when(_G.Wrapper.AddBlipForCoord(3, 4, 5)).thenAnswer(blips[3])
        
        Blips.UpdateBlips({createCoords(1, 2, 3), createCoords(2, 3, 4), createCoords(3, 4, 5)})

        for _, blip in pairs(blips) do
            verify(_G.Wrapper.SetBlipSprite(blip, 3))
            verify(_G.Wrapper.SetBlipAsShortRange(blip, true))
            verify(_G.Wrapper.SetBlipFlashes(blip, true))
            verify(_G.Wrapper.BeginTextCommandSetBlipName('STRING'))
            verify(_G.Wrapper.AddTextComponentString('patient translated'))
            verify(_G.Wrapper.EndTextCommandSetBlipName(blip))
        end
    end)
    
    it('StopBlips -- removes all patient blips and removes groove blip', function()
        Blips.patientBlips = {'Blip 1', 'Blip 2', 'Blip 3'}
        Blips.grooveBlip = 'groove blip'
        
        Blips.StopBlips()

        verify(_G.Wrapper.RemoveBlip('Blip 1', 1))
        verify(_G.Wrapper.RemoveBlip('Blip 2', 2))
        verify(_G.Wrapper.RemoveBlip('Blip 3', 3))
        verify(_G.Wrapper.RemoveBlip('groove blip'))
    end)

    it('SetFlashGroove -- calls native on groove blip when set to true', function()
        Blips.grooveBlip = 'groove blip'

        Blips.SetFlashGroove(true)

        verify(_G.Wrapper.SetBlipFlashes('groove blip', true))
    end)

    it('SetFlashGroove -- calls native on groove blip when set to false', function()
        Blips.groove = 'groove blip'

        Blips.SetFlashGroove(false)

        verify(_G.Wrapper.SetBlipFlashes('groove blip', false))
    end)

    function createCoords(x, y, z)
        return {x = x, y = y, z = z}
    end
end)