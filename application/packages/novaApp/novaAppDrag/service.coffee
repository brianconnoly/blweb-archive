class novaAppDrag

    constructor: ->
        @body = $('body')

    startDrag: (e, elem, scope) ->

        if scope.session.maximized == true
            return 

        # elem.addClass 'drag'

        if scope.session.position?
            currentTransform = [scope.session.position.x, scope.session.position.y]
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

        @body.on 'mousemove.novaAppDrag', (e) =>
            if e.which == 0
                @flushDrag(scope)(e)
                return 

            elem.css 'transform', 'translate3d(' + (e.clientX - @offset.x) + 'px,' + (e.clientY - @offset.y) + 'px, 0)'

        @body.on 'mouseup.novaAppDrag', @flushDrag(scope, elem)

    flushDrag: (scope, elem) ->
        (e) =>
            # elem.removeClass 'drag'

            @body.off 'mousemove.novaAppDrag'
            @body.off 'mouseup.novaAppDrag'

            scope.setPosition (e.clientX - @offset.x), (e.clientY - @offset.y)
            scope.$applyAsync()

new novaAppDrag()