*deps: $compile, novaDragHelper

# Init
elem = $ element
body = $ 'body'
mode = 'still'

# Drag helper
helper = null
dragItems = []
helperScope = null
buildHelper = ->
    # Get dragged items
    getItems()

    # Build drag content preview
    helperScope = scope.$new()
    helperScope.dragItems = dragItems
    helper = $ '<div>',
        class: 'novaDragHelper'
    body.append helper
    $compile(helper)(helperScope)
    helperScope.$apply()

getItems = ->
    dragItems = []
    if scope.multiselect?
        # Copy items from multiselect to save original array
        for item in scope.multiselect.selected
            dragItems.push item
    else if scope.item?
        dragItems.push scope.item
    dragItems

currentTarget = null
setTarget = (target, e) ->
    if target == currentTarget
        return true
    currentTarget = target

    actions = currentTarget.novaDrop.getActions(dragItems, scope.itemContext, e)
    if actions.length > 0
        # Got some target
        novaDragHelper.setActions actions
        novaDragHelper.showHighLighter target
        return true
    else
        novaDragHelper.setActions []
        novaDragHelper.flushHighlighter()
        return false

foundTarget = null
elem.on 'mousedown.novaDrag', (e) ->
    # getItems()
    # console.log dragItems, scope.multiselect

    if $(e.target).parents('.novaItemDraggable')[0] != element[0]
        return true

    # Init drag
    startPos =
        x: e.pageX
        y: e.pageY

    bodyWid = body.width()
    bodyHei = body.height()

    helperPos =
        x: e.pageX
        y: e.pageY

    body.on 'mousemove.novaDrag', (e) ->

        # Start dragging if mouse moved more than 20 px
        if mode == 'still'
            if Math.abs(startPos.x - e.pageX) > 10 or Math.abs(startPos.y - e.pageY) > 10
                mode = 'drag'
                # buildHelper()
                novaDragHelper.show getItems()

        # Handle drag
        else # if mode == 'drag'

            # Positionate helper
            if e.pageX > bodyWid - 210 - 20
                helperPos.x = e.pageX - 20 - 210
                novaDragHelper.elem.addClass 'lefty'
            else
                helperPos.x = e.pageX + 20
                novaDragHelper.elem.removeClass 'lefty'

            if e.pageY > bodyHei - 120
                helperPos.y = bodyHei - 100
            else
                helperPos.y = e.pageY + 20

            novaDragHelper.elem.css 'transform', "translate3d(#{helperPos.x}px,#{helperPos.y}px, 0)"

            # Drop target
            dropTarget = document.elementFromPoint e.pageX, e.pageY
            foundTarget = false
            while dropTarget
                if dropTarget.novaDrop
                    if setTarget dropTarget, e
                        foundTarget = true
                        break
                dropTarget = dropTarget.parentNode

            if !foundTarget
                novaDragHelper.setActions []
                novaDragHelper.flushHighlighter()
                currentTarget = null
        true

    body.on 'mouseup.novaDrag', (e) ->
        # Finish drag
        body.off 'mousemove.novaDrag'
        body.off 'mouseup.novaDrag'

        if mode != 'still'
            mode = 'still'
            novaDragHelper.activate e
            #scope.$apply()
