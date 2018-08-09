buzzlike.directive 'resize', (desktopService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element
        parent = elem.parent()

        body = $('body')

        flushResize = (e) ->
            e.stopPropagation()
            e.preventDefault()

            scope.resized scope.session.size.width, scope.session.size.height

            body.off 'mousemove.resizeWindow'
            body.off 'mouseup.resizeWindow'

            # desktopService.saveState()
            scope.stateSaver.save()
            
            scope.$apply()

        elem.on 'mousedown.resizeWindow', (e) ->
            # e.stopPropagation()
            e.preventDefault()

            rightGuide = scope.session.coords.x + scope.session.size.width
            bottomGuide = scope.session.coords.y + scope.session.size.height

            body.on 'mousemove.resizeWindow', (e) ->
                if e.which == 0
                    flushResize(e)
                    return

                if element.hasClass 'bottom'
                    scope.setHeight e.clientY - (scope.session.coords?.y or 0)

                else if element.hasClass 'right'
                    scope.setWidth e.clientX - (scope.session.coords?.x or 0)

                else if element.hasClass 'right'
                    scope.setWidth e.clientX - (scope.session.coords?.x or 0)

                else if element.hasClass 'left'
                    scope.setPosition e.clientX, scope.session.coords.y
                    scope.setWidth rightGuide - e.clientX

                else if element.hasClass 'top'
                    scope.setPosition scope.session.coords.x, e.clientY
                    scope.setHeight bottomGuide - e.clientY

                else if element.hasClass 'topleft'
                    scope.setPosition scope.session.coords.x, e.clientY
                    scope.setHeight bottomGuide - e.clientY
                    scope.setPosition e.clientX, scope.session.coords.y
                    scope.setWidth rightGuide - e.clientX

                else if element.hasClass 'topright'
                    scope.setPosition scope.session.coords.x, e.clientY
                    scope.setHeight bottomGuide - e.clientY
                    scope.setWidth e.clientX - (scope.session.coords?.x or 0)

                else if element.hasClass 'bottomleft'
                    scope.setHeight e.clientY - (scope.session.coords?.y or 0)
                    scope.setPosition e.clientX, scope.session.coords.y
                    scope.setWidth rightGuide - e.clientX

                else if element.hasClass 'bottomright'
                    scope.setHeight e.clientY - (scope.session.coords?.y or 0)
                    scope.setWidth e.clientX - (scope.session.coords?.x or 0)

                scope.resizeInProgress? scope.session.size.width, scope.session.size.height

            body.on 'mouseup.resizeWindow', flushResize