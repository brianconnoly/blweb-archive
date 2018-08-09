buzzlike.directive 'breadCrombs', () ->
    restrict: 'E'
    replace: true
    template: tC['/desktop/appLauncher/breadCrombs']
    link: (scope, element, attrs) ->

        scope.lastStep = (step) -> scope.stepStack.indexOf(step) == scope.stepStack.length - 1
        scope.jumpStep = (step) ->
            scope.currentStep = step
            scope.onJumpStep? step
        true