*deps: actionsService, $parse
domElem = element[0]
elem = $ element

domElem.novaDrop =
    getActions: (items, context, e) ->
        currentActions = actionsService.getActions
            source: items
            sourceContext: context
            target: scope.item
            context: $parse(attrs.novaItemContext)(scope)
            targetOnly: true
            actionsType: 'dragndrop'

        currentActions
