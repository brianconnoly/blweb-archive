*deps: novaDesktop

elem = $ element
elem.parent().on 'dblclick', (e) ->
    novaDesktop.launchApp
        app: 'novaTextEditApp'
        item:
            type: 'text'
            id: scope.item.id

    scope.$apply()
