*deps: novaBuffer

elem = $ element
body = $ 'body'

elem.on 'mousedown.novaBuffer', (e) ->
    bodyWid = body.width()
    start = e.clientX
    startWid = novaBuffer.element.width()
    fixSize = bodyWid - startWid - start

    maxWid = bodyWid / 2 | 0
    nuWid = 0

    if !novaBuffer.showed
        fixSize = 0
        novaBuffer.trigger()
        scope.$apply()
        # Animation fix
        setTimeout ->
            novaBuffer.element?.addClass 'noAnim'
        , 200
    else
        novaBuffer.element?.addClass 'noAnim'

    body.on 'mousemove.novaBuffer', (e) ->
        # Do resize
        nuWid = bodyWid - e.clientX - fixSize
        if nuWid > maxWid
            nuWid = maxWid
        if nuWid < 100
            nuWid = 100
        novaBuffer.setWidth nuWid
        scope.$apply()

    body.on 'mouseup.novaBuffer', (e) ->
        body.off 'mousemove.novaBuffer'
        body.off 'mouseup.novaBuffer'

        novaBuffer.element?.removeClass 'noAnim'

        # Resize completed
