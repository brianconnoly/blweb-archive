buzzlike.directive 'bufferResizer', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        scope.buffer = $ element
        true