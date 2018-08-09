buzzlike.directive 'activeDesktop', (appsService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element

        elem.on 'mousedown.activeDesktop', (e) ->
            scope.blMenu = false
            appsService.flushActive()
            scope.$apply()
        true