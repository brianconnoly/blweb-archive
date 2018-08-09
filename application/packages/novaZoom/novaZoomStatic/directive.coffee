*replace: true
*require: '?ngModel'

elem = $ element
pickerWindow = elem
pickerHandler = elem.find '.pickerHandler'
body = $ 'body'

startX = 0

ngModel.$render = () ->
    if ngModel.$viewValue?
        scope.value = ngModel.$viewValue
        perc = scope.value / 10
        pickerHandler.css 'left', 5 + (70 * perc | 0)

setValueFromLeft = (left) ->
    left -= 5
    perc = left / 70
    perc *= 90
    perc = perc | 0
    perc /= 10
    ngModel.$setViewValue perc + 1

pickerHandler.on 'mousedown.novaZoom', (e) ->
    pickerTop = pickerWindow.position().left
    handlerTop = pickerHandler.position().left

    startX = e.clientX

    body.on 'mousemove.novaZoom', (e) ->
        nVal = handlerTop + e.clientX - startX
        if nVal > 75
            nVal = 75
        if nVal < 5
            nVal = 5
        pickerHandler.css 'left', nVal
        setValueFromLeft nVal

    body.on 'mouseup.novaZoom', ->
        body.off 'mousemove.novaZoom'
        body.off 'mouseup.novaZoom'
