buzzlike.directive 'comboboxList', (comboboxService, stateManager, localization) ->
    restrict: 'C'
    replace: true
    template: tC['/inputs/combobox/list']
    scope: {}
    link: (scope, element, attrs) ->
        scope.state = comboboxService.state
        scope.translate = localization.translate

        scope.close = ->
            scope.state.opened = false
            stateManager.goBack()
            true

        scope.select = (selected) ->
            scope.state.cb selected
            true

        true