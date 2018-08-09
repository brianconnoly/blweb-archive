buzzlike.directive 'filterPanel', (localization, $compile) ->
    restrict: 'C'
    scope:
        sections: '='
        select: '='
        current: '='
        sortTypes: '='
        params: '='
        extra: '='
        filterMessage: '=?'
        currentChild: '=?'
    template: tC['/filterCatalog/filterPanel']
    link: (scope, element, attrs) ->
        elem = $ element
        filterBody = elem.children('.filterBody')

        scope.localization = localization
        scope.children = []

        scope.$watch 'current', (nVal) ->
            if nVal? and nVal.showChildren == true
                if typeof nVal.widgets == 'function'
                    scope.children = nVal.widgets()
                else
                    scope.children = nVal.widgets

        if attrs.extended?
            extended = $compile('<div class="'+attrs.extended+'"></div>')(scope)

            if antiscrollOn
                appendTo = filterBody.find '.scroll-box .size'
            else
                appendTo = filterBody

            $(extended).appendTo appendTo

        true