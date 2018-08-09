buzzlike.directive 'dropHelper', (dropHelper, localization, buffer) ->
    restrict: 'C'
    scope: {}
    replace: true
    template: tC['/dragdrop/dropHelper']
    link: (scope, element, attrs) ->
        scope.status = dropHelper.status
        # scope.translate = localization.translate
        scope.fireAction = (action, e) ->

            items = action.action(e)

            if !e.altKey and dropHelper.fromBuffer and @status.actions[0].leaveItems != true
                buffer.removeItems items

            dropHelper.flush true

        scope.closeHelper = ->
            dropHelper.flush true
        true