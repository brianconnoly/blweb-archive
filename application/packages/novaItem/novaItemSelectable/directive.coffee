*deps: novaMenu

# Init directive
elem = $ element

if !scope.multiselect?
    return

# Init state
if scope.multiselect.isSelected scope.item
    elem.addClass 'selected'

# Events
elem.off '.novaItemSelectable'
elem.on 'mousedown.novaItemSelectable', (e) ->

    if $(e.target).parents('.novaItemSelectable')[0] != element[0]
        return true

    cmd = (e.ctrlKey || e.metaKey)
    novaMenu.hide()
    $(':focus').blur()

    if !cmd and !elem.hasClass('selected')
        scope.multiselect.flush()
        elem.addClass 'selected'
    if cmd
        elem.toggleClass 'selected'

    if elem.hasClass 'selected'
        scope.multiselect.select scope.item

    scope.multiselect.activate()
    scope.$apply()
    true

scope.getSelectedItems = ->
    selectedItems = []
    if scope.multiselect?
        # Copy items from multiselect to save original array
        for item in scope.multiselect.selected
            selectedItems.push item
    else if scope.item?
        selectedItems.push scope.item
    selectedItems
