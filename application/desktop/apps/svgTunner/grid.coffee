buzzlike.directive 'svgTunnerGrid', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element

        buildLines = () ->
            elem.empty()

            for x in [1..scope.size.width]
                elem.append $ '<div>',
                    class: 'vertLine'
                    css: 
                        'left': x * scope.size.zoom

            for y in [1..scope.size.height]
                elem.append $ '<div>',
                    class: 'horLine'
                    css: 
                        'top': y * scope.size.zoom

        scope.$watch 'size', buildLines, true
            