buzzlike
    .service 'dragWinow', (desktopService) ->

        class dragWindow

            flushDrag: (scope, elem) ->
                (e) =>
                    elem.removeClass 'drag'

                    @body.off 'mousemove.dragWindow'
                    @body.off 'mouseup.dragWindow'

                    if scope.session.noSnap != true
                        if @dragHelper.hasClass('rightHalf') and @dragHelper.hasClass('topHalf')
                            scope.setPosition @bodyWid / 2, 0
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei / 2

                            scope.resized @bodyWid / 2, @bodyHei / 2

                        else if @dragHelper.hasClass('leftHalf') and @dragHelper.hasClass('topHalf')
                            scope.setPosition 0, 0
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei / 2

                            scope.resized @bodyWid / 2, @bodyHei / 2

                        else if @dragHelper.hasClass('leftHalf') and @dragHelper.hasClass('bottomHalf')
                            scope.setPosition 0, @bodyHei / 2
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei / 2

                            scope.resized @bodyWid / 2, @bodyHei / 2

                        else if @dragHelper.hasClass('rightHalf') and @dragHelper.hasClass('bottomHalf')
                            scope.setPosition @bodyWid / 2, @bodyHei / 2
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei / 2

                            scope.resized @bodyWid / 2, @bodyHei / 2

                        else if @dragHelper.hasClass 'rightHalf'
                            scope.setPosition @bodyWid / 2, 0
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei

                            scope.resized @bodyWid / 2, @bodyHei

                        else if @dragHelper.hasClass 'leftHalf'
                            scope.setPosition 0, 0
                            scope.setWidth @bodyWid / 2
                            scope.setHeight @bodyHei

                            scope.resized @bodyWid / 2, @bodyHei

                        # else if @dragHelper.hasClass 'topHalf'
                        #     scope.setPosition 0, 0
                        #     scope.setWidth '100%'
                        #     scope.setHeight ( @body.height() / 2 ) 

                        #     scope.resized $(scope.session.element).width(), ( @body.height() / 2 ) 

                        else if @dragHelper.hasClass 'bottomHalf'
                            scope.setPosition 0, @body.height() / 2
                            scope.setWidth '100%'
                            scope.setHeight @body.height() / 2

                            scope.resized $(scope.session.element).width(), ( @body.height() / 2 ) 
                        else
                            scope.setPosition (e.clientX - @offset.x), (e.clientY - @offset.y)
                    else
                        scope.setPosition (e.clientX - @offset.x), (e.clientY - @offset.y)

                    @dragHelper.attr 'class', ''

                    scope.stateSaver.save()
                    scope.$apply()

            constructor: ->
                @body = $('body')
                @dragHelper = $('#windowDragHelper')

            startDrag: (e, elem, scope) ->

                if scope.session.maximized == true
                    return 

                elem.addClass 'drag'

                if $(e.target).prop("tagName") != 'INPUT'
                    # return
                    # e.stopPropagation()
                    e.preventDefault()

                if scope.session.coords?
                    currentTransform = [scope.session.coords.x, scope.session.coords.y]
                else
                    currentTransform = elem.css("transform")
                    if currentTransform?.length > 10
                        currentTransform = currentTransform.split('(')[1]
                        currentTransform = currentTransform.split(')')[0]
                        currentTransform = currentTransform.split(',')
                    else
                        currentTransform = [0,0]

                # Get offset
                @offset =
                    x: e.clientX - parseInt(currentTransform[0])
                    y: e.clientY - parseInt(currentTransform[1])

                @bodyWid = @body.width()
                @bodyHei = @body.height()

                @body.on 'mousemove.dragWindow', (e) =>
                    if e.which == 0
                        @flushDrag(scope)(e)
                        return 

                    @dragHelper.attr 'class', ''

                    elem.css 'transform', 'translate3d(' + (e.clientX - @offset.x) + 'px,' + (e.clientY - @offset.y) + 'px, 0)'

                    if scope.session.noSnap != true
                        if e.clientY < 20
                            # @dragHelper.addClass 'topHalf'
                            true
                        else if e.clientY > @bodyHei - 50
                            @dragHelper.addClass 'bottomHalf'

                        if e.clientX < 20
                            @dragHelper.addClass 'leftHalf'
                        else if e.clientX > @bodyWid - 20
                            @dragHelper.addClass 'rightHalf'

                @body.on 'mouseup.dragWindow', @flushDrag(scope, elem)

        new dragWindow()

    .directive 'dragHandler', (dragWinow) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $(element)
            elem.on 'mousedown.dragWindow', (e) ->

                if attrs.ignoreTextarea and $(e.target).prop("tagName") == 'TEXTAREA'
                    return

                $('*').blur()

                dragWinow.startDrag e, elem.parents('.appLauncher'), scope
