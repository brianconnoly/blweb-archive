*deps: novaMultiselect, novaMenu
*scope: true

# Init DOM
elem = $ element
body = $ 'body'

# Init range selector
range = $ '<div>',
    class: 'novaRangeSelector'
elem.append range

# Init service
scope.multiselect = new novaMultiselect elem
if attrs.novaMultiselectParentObject?.length > 0
    index = attrs.novaMultiselectParentIndex*1 or 1
    if index == 1
        scope.$parent[attrs.novaMultiselectParentObject] = scope.multiselect
    else if index == 2
        scope.$parent.$parent[attrs.novaMultiselectParentObject] = scope.multiselect

msId = getRandomInt(0,10000)
# Init events
elem.off '.novaMultiselect' + msId
elem.on 'mousedown.novaMultiselect' + msId, (e) ->
    if $(e.target).parents('.novaItemSelectable').length > 0
        return true
    # e.stopPropagation()
    e.preventDefault()

    novaMenu.hide()

    if scope.multiselect.activate()
        scope.multiselect.flush()

    scope.$apply()

    areaWidth  = elem.width()
    areaHeight = elem.height()

    offset   = elem.offset()
    startPos =
        x: e.pageX - offset.left
        y: e.pageY - offset.top

    currentPos = null
    rangeStyles = {}

    range.css
        'left': startPos.x
        'top': startPos.y

    # Init range selector
    body.on 'mousemove.novaMultiselectRange', (e) ->
        # Range selection
        range.addClass 'active'

        currentPos =
            x: e.pageX - offset.left
            y: e.pageY - offset.top

        rangeStyles.width = Math.abs currentPos.x - startPos.x
        rangeStyles.height = Math.abs currentPos.y - startPos.y

        if currentPos.x > startPos.x
            rangeStyles.left = startPos.x
            rangeStyles.right = 'auto'
        else
            rangeStyles.left = 'auto'
            rangeStyles.right = areaWidth - startPos.x

        if currentPos.y > startPos.y
            rangeStyles.top = startPos.y
            rangeStyles.bottom = 'auto'
        else
            rangeStyles.top = 'auto'
            rangeStyles.bottom = areaHeight - startPos.y

        range.css rangeStyles
        true

    body.on 'mouseup.novaMultiselectRange', (e) ->
        body.off 'mousemove.novaMultiselectRange'
        body.off 'mouseup.novaMultiselectRange'

        range.removeClass 'active'
