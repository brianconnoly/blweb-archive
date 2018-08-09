buzzlike.directive 'disableOnClick', () ->
    restrict: 'A'
    scope:
        status: '='
    link: (scope, element, attrs, ctrl) ->
        elem = $ element
        scope.status = 'enabled' if scope.status not in ['enabled', 'disabled']
        delay = +attrs.delay

        elem.on 'click', ->
            if scope.status == 'enabled'
                scope.status = 'disabled'
                if delay
                    setTimeout ->
                        scope.status = 'enabled'
                        scope.$apply()
                    , delay

            scope.$apply()
            true

        true
