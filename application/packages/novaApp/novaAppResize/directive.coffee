elem = $ element
parent = elem.parent()

body = $('body')

flushResize = (e) ->
    e.stopPropagation()
    e.preventDefault()

    scope.resized scope.session.size.width, scope.session.size.height

    #body.off 'mousemove.resizeWindow'
    body[0].onmousemove = null
    body.off 'mouseup.resizeWindow'

    scope.stateSaver.save 'size'

    scope.$apply()

elem.on 'mousedown.resizeWindow', (e) ->
    # e.stopPropagation()
    e.preventDefault()

    rightGuide = scope.session.position.x + scope.session.size.width
    bottomGuide = scope.session.position.y + scope.session.size.height

    type = "bottom"
    if element.hasClass 'bottom'
        type = 'bottom'
    else if element.hasClass 'right'
        type = 'right'
    else if element.hasClass 'left'
        type = 'left'
    else if element.hasClass 'top'
        type = 'top'
    else if element.hasClass 'topleft'
        type = 'topleft'
    else if element.hasClass 'topright'
        type = 'topright'
    else if element.hasClass 'bottomleft'
        type = 'bottomleft'
    else if element.hasClass 'bottomright'
        type = 'bottomright'

    body[0].onmousemove = (e) -> #on 'mousemove.resizeWindow', (e) ->
        if e.which == 0
            flushResize(e)
            return

        switch type
            when 'bottom'
                scope.setHeight e.clientY - (scope.session.position?.y or 0), true

            when 'right'
                scope.setWidth e.clientX - (scope.session.position?.x or 0), true

            when 'left'
                scope.setPosition e.clientX, scope.session.position.y, true
                scope.setWidth rightGuide - e.clientX, true

            when 'top'
                scope.setPosition scope.session.position.x, e.clientY, true
                scope.setHeight bottomGuide - e.clientY, true

            when 'topleft'
                scope.setPosition scope.session.position.x, e.clientY, true
                scope.setHeight bottomGuide - e.clientY, true
                scope.setPosition e.clientX, scope.session.position.y, true
                scope.setWidth rightGuide - e.clientX, true

            when 'topright'
                scope.setPosition scope.session.position.x, e.clientY, true
                scope.setHeight bottomGuide - e.clientY, true
                scope.setWidth e.clientX - (scope.session.position?.x or 0), true

            when 'bottomleft'
                scope.setHeight e.clientY - (scope.session.position?.y or 0), true
                scope.setPosition e.clientX, scope.session.position.y, true
                scope.setWidth rightGuide - e.clientX, true

            when 'bottomright'
                scope.setHeight e.clientY - (scope.session.position?.y or 0), true
                scope.setWidth e.clientX - (scope.session.position?.x or 0), true

        scope.resizeInProgress? scope.session.size.width, scope.session.size.height

    body.on 'mouseup.resizeWindow', flushResize
