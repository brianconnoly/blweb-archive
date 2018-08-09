buzzlike.directive "label", () ->
    restrict: "A"
    scope:
        model: '=label'
    link: (scope, element, attrs) ->
        elem = $ element
        elem.on 'click', ->
            scope.model = !scope.model
            scope.$parent.$apply()