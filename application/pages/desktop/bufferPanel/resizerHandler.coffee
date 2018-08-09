buzzlike.directive 'resizerHandler', (buffer, appsService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        scope.resizeHandler = elem = $ element

        body = $('body')
        bodyWid = body.width()

        scope.$watch ->
            buffer.width
        , (nVal) ->
            if buffer.showed
                scope.workarea.css 'right', nVal
                scope.buffer.css 'width', nVal

                if !dragInProgress
                    scope.resizeHandler.css 'right', nVal
                    scope.resizeHelper.css 'width', nVal

        scope.$watch ->
            buffer.showed
        , (nVal) ->
            if nVal
                scope.workarea.css 'right', buffer.width
                scope.buffer.css 'width', buffer.width

                scope.resizeHandler.css 'right', buffer.width
                scope.resizeHelper.css 'width', buffer.width
            else
                scope.workarea.css 'right', 0
                scope.buffer.css 'width', 0

                scope.resizeHandler.css 'right', 0
                scope.resizeHelper.css 'width', 0

        setWidth = (width) ->
            if buffer.showed == false
                buffer.showed = true
            buffer.setWidth width
            scope.$apply()

        dragInProgress = false
        elem.on 'mousedown.bufferResize', (e) ->
            dragInProgress = true
            scope.resizeHelper.addClass 'visible'

            body.on 'mousemove.bufferResize', (e) ->
                currentWidth = bodyWid - e.clientX
                rawWidth = currentWidth
                if currentWidth >= 430
                    currentWidth = 430

                if currentWidth <= 112
                    currentWidth = 112

                # scope.workarea.css 'right', scope.bufferWidth
                scope.resizeHelper.css 'width', currentWidth
                elem.css 'right', currentWidth

                # if rawWidth < 50
                #     if buffer.showed == true
                #         buffer.showed = false
                #     return

                if currentWidth < 155 
                    if scope.bufferWidth != 112
                        scope.bufferWidth = 112
                        setWidth scope.bufferWidth
                    return

                if currentWidth < 270 
                    if scope.bufferWidth != 220
                        scope.bufferWidth = 220
                        setWidth scope.bufferWidth
                    return

                if currentWidth < 375 
                    if scope.bufferWidth != 324
                        scope.bufferWidth = 324
                        setWidth scope.bufferWidth
                    return

                if scope.bufferWidth != 430
                    scope.bufferWidth = 430
                    setWidth scope.bufferWidth
                    return

                # scope.bufferWidth = currentWidth

            body.on 'mouseup.bufferResize', (e) ->
                dragInProgress = false

                body.off 'mousemove.bufferResize'
                body.off 'mouseup.bufferResize'

                scope.resizeHelper.removeClass 'visible'
                scope.resizeHelper.css 'width', scope.bufferWidth
                scope.resizeHandler.css 'right', scope.bufferWidth

                appsService.desktopResized()
        true