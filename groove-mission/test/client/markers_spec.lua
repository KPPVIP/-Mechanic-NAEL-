local mockagne = require 'mockagne'

describe('client - markers', function()

    local coroutineSpy, drawPedMarkerSpy, drawGrooveMarkerSpy
    local coords

    before_each(function()
        _G.unpack = table.unpack
        _G.Config = {Markers = {Size = 10.0}}
        _G.Wrapper = mockagne.getMock()
        _G.Citizen = {
            Wait = coroutine.yield,
            CreateThread = coroutine.create
        }

        require('../../src/lib/stream')
        require('../../src/client/markers')

        coroutineSpy = spy.on(_G.Citizen, 'CreateThread')
        coords = createCoords(1, 2, 3)
        drawPedMarkerSpy = spy.on(Markers, 'drawPedMarker')
        drawGrooveMarkerSpy = spy.on(Markers, 'drawGrooveMarker')
    end)

    it('StartMarkers, UpdateMarkers, SetShowHGroove, StopMarkers', function()
        assertStateIsCorrect(false, false, nil, 0)

        Markers.StartMarkers(coords)
        loop = coroutineSpy['returnvals'][1].vals[1]
        iterateLoop(loop)
        assertStateIsCorrect(true, false, coords, 0)
        assertSpyCallCounts(0, 0)

        Markers.SetShowGroove(true)
        iterateLoop(loop)
        assertStateIsCorrect(true, true, coords, 0)
        assertSpyCallCounts(1, 0)

        Markers.UpdateMarkers({coords, coords, coords})
        iterateLoop(loop)
        assertStateIsCorrect(true, true, coords, 3)
        assertSpyCallCounts(2, 3)

        Markers.SetShowGroove(false)
        Markers.UpdateMarkers({coords})
        iterateLoop(loop)
        assertStateIsCorrect(true, false, coords, 1)
        assertSpyCallCounts(2, 4)

        Markers.StopMarkers()
        iterateLoop(loop)
        assertStateIsCorrect(false, false, coords, 0)
        assertSpyCallCounts(2, 4)
        assert.equals(coroutine.status(loop), 'dead')
    end)

    function createCoords(x, y, z)
        return {x = x, y = y, z = z}
    end

    function iterateLoop(loop)
        coroutine.resume(loop)
    end

    function assertStateIsCorrect(showMarkers, showGroove, grooveMarkerPosition, markerPositionsCount)
        assert.equals(Markers.showMarkers, showMarkers)
        assert.equals(Markers.showGroove, showGroove)
        assert.equals(Markers.grooveMarkerPosition, grooveMarkerPosition)
        assert.equals(#Markers.markerPositions, markerPositionsCount)
    end

    function assertSpyCallCounts(drawGrooveMarkerCount, drawPedMarkerCount)
        assert.spy(drawGrooveMarkerSpy).was.called(drawGrooveMarkerCount)
        assert.spy(drawPedMarkerSpy).was.called(drawPedMarkerCount)
    end
end)