buzzlike.directive 'complexMenu', (complexMenu) ->
    restrict: 'C'
    replace: true
    template: tC['/complexMenu']
    link: (scope, element, attrs) ->

        elem = $ element
        menu = elem.find '.menuFrame'

        scope.complexMenu = complexMenu

        scope.clickItem = (item, section, e) ->
            switch section.type
                when 'checkbox'
                    section.object[item.param] = !section.object[item.param]
                    section.selectFunction?(item)

                when 'select'
                    if section.object? and section.param?
                        section.object[section.param] = item.value
                    section.selectFunction?(item)

                when 'actions'
                    item.action(e)

            complexMenu.hide()

        scope.selected = (item, section) ->
            if section.value?
                return section.value == item.value

            section.object?[section.param] == item.value
        true
