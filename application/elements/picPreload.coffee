buzzlike.directive 'picPreload', ($rootScope) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element
        attrs.$observe 'src', (v) ->
            if v
                scope.processImage(v)

        scope.processImage = (src) ->
            parent = elem.parent()
            img = new Image()
            img.onload = () ->
                if attrs.previewBox?
                    elem.css imageInRatio @, 54 / 70
                else
                    elem.css imageIn @, parent.width(), parent.height(), attrs.fullView?, true

                elem.addClass 'visible'
            img.src = $rootScope.proxyImage src

        scope.processImage attrs.src
        true
