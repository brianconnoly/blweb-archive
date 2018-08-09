scope.$on '$destroy', ->
    clearInterval intervalHandler

elem = $ element

prev = null
currentColor = getRandomInt 0, 3

nextColor = ->
    if prev?
        elem.removeClass prev

    currentColor++
    if currentColor > 3
        currentColor = 1

    prev = 'color' + currentColor
    elem.addClass prev

intervalHandler = setInterval nextColor, 15000
nextColor()