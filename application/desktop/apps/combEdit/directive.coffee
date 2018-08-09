buzzlike.directive 'combEdit', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element
        scope.element = elem