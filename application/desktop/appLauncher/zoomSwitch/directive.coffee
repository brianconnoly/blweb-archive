buzzlike.directive 'zoomSwitch', () ->
    restrict: 'E'
    replace: true
    template: tC['/desktop/appLauncher/zoomSwitch']
    link: (scope, element, attrs) ->
        elem = $ element

        true