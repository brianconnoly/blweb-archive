*deps: novaMenu

elem = $ element
elem.on 'click.novaMenuActivator', (e) ->
    e.preventDefault()
    e.stopPropagation()

    offset = elem.offset()

    novaMenu.show
        menuStyle: 'center'
        position:
            x: offset.left + Math.ceil(elem.width() / 2) #e.pageX
            y: offset.top + elem.height() + 5 # e.pageY
        items: [scope.item]
        context: scope.itemContext
        scope: scope


    # position:
    #     x: offset.left + addIcon.width() / 2
    #     y: offset.top + addIcon.height() + 5
    # noApply: true
