*deps: novaDesktop

elem = $ element
elem.on 'dblclick', (e) ->
    e.stopPropagation()
    e.preventDefault()

    novaDesktop.launchApp
        app: 'novaThemesApp'
        item:
            id: scope.item.id
            type: 'comb'

    scope.$apply()
