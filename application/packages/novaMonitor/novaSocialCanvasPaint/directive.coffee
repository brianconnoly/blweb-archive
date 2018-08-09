*deps: novaMenu

scope.showMenu = (e) ->
    addItems = $ e.target
    sections = [
        type: 'actions'
        items: [
            phrase: 'delete'
            action: ->
                removeElementFromArray scope.paint, scope.paints
        ]
    ]

    offset = addItems.offset()
    novaMenu.show
        position:
            x: offset.left + Math.ceil(addItems.width() / 2) #e.pageX
            y: offset.top
            hei: addItems.height() # e.pageY
        sections: sections
        menuStyle: 'center'
        noApply: true

    e.stopPropagation()
    e.preventDefault()
    true
