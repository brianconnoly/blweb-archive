buzzlike.directive 'workareaResizer', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        scope.workarea = $ element
        true