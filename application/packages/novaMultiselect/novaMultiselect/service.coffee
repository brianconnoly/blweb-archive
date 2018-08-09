
class novaMultiselect

    constructor: (@element) ->
        @selected = []
        true

    isSelected: (item) -> item in @selected

    select: (items) ->
        if !angular.isArray(items)
            items = [items]

        for item in items
            @selected.push item if item not in @selected

    deselect: (items) ->
        if !angular.isArray(items)
            items = [items]

        for item in items
            removeElementFromArray item, @selected

    activate: ->
        state = @element.hasClass 'active'
        $('.novaMultiselect.active').removeClass 'active'
        @element?.addClass 'active'
        state

    flush: ->
        $('.novaItemSelectable.selected', @element).removeClass 'selected'
        @selected.length = 0

novaMultiselect
