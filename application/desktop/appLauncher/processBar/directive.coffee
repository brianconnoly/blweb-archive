buzzlike.directive 'processBar', () ->
    restrict: 'E'
    replace: true
    template: tC['/desktop/appLauncher/processBar']
    link: (scope, element, attrs) ->

        elem = $ element

        hideTimeout = null
        animTimeout = null

        scope.$watch ->
            scope.progress.showed
        , (nVal) ->
            if nVal == true
                elem.removeClass 'full'
                elem.addClass 'animated'
                elem.addClass 'showed'

                if hideTimeout?
                    clearTimeout hideTimeout
                    hideTimeout = null
            else
                elem.removeClass 'showed'
                if hideTimeout?
                    clearTimeout hideTimeout
                hideTimeout = setTimeout ->
                    elem.css 'width', 0
                , 200

        scope.$watch -> 
            scope.progress.done
        , (nVal, oVal) ->
            if nVal?
                if nVal < oVal or nVal == 0
                    elem.removeClass 'animated'
                    elem.css 'width', nVal + '%'

                    if animTimeout?
                        clearTimeout animTimeout
                    animTimeout = setTimeout ->
                        elem.addClass 'animated'
                    , 1
                else
                    if animTimeout?
                        clearTimeout animTimeout
                        animTimeout = null
                        
                    elem.css 'width', nVal + '%'
                    if nVal == 100
                        elem.addClass 'full'


        true