buzzlike.directive 'bufferResizeHelper', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        scope.resizeHelper = $ element

        true
