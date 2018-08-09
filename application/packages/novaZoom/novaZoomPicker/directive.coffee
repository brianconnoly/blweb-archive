*deps: novaZoom
*replace: true

elem = $ element
pickerWindow = elem.find '.pickerWindow'
pickerHandler = elem.find '.pickerHandler'

startY = 0

scope.$watch ->
    novaZoom.currentValue
, (nVal) ->
    if nVal?
        perc = nVal / 10
        pickerHandler.css 'top', 5 + (70 * perc | 0)
, true

setValueFromTop = (top) ->
    top -= 5
    perc = top / 70
    perc *= 90
    perc = perc | 0
    perc /= 10
    novaZoom.setValue perc + 1

pickerHandler.on 'mousedown.novaZoom', (e) ->
    pickerTop = pickerWindow.position().top
    handlerTop = pickerHandler.position().top

    startY = e.clientY

    elem.on 'mousemove.novaZoom', (e) ->
        nVal = handlerTop + e.clientY - startY
        if nVal > 75
            nVal = 75
        if nVal < 5
            nVal = 5
        pickerHandler.css 'top', nVal
        setValueFromTop nVal

    elem.on 'mouseup.novaZoom', ->
        elem.off 'mousemove.novaZoom'
        elem.off 'mouseup.novaZoom'

scope.hidePicker = ->
    novaZoom.hide()