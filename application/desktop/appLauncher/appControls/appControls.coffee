buzzlike.directive 'appControls', () ->
    restrict: 'C'
    template: tC['/desktop/appLauncher/appControls']
    link: (scope, element, attrs) ->

        scope.triggerSettings = ->
            scope.session.expandedHeader = !scope.session.expandedHeader
            scope.stateSaver.save()
            true
        true