*deps: novaMenu

elem = $ element

elem.on 'contextmenu.contextMenu', (e) ->
    if $(e.target).prop("tagName") in ['INPUT','TEXTAREA']
        return

    if e.which == 3
        e.preventDefault()
        e.stopPropagation()

        novaMenu.show
            position:
                x: e.pageX
                y: e.pageY
            items: scope.getSelectedItems?() or [scope.item]
            context: scope.itemContext
            scope: scope

    false
