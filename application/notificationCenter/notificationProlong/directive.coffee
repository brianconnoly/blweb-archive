buzzlike.directive 'notificationProlong', (localization) ->
    template: tC['/notificationCenter/notificationProlong']
    link: (scope, element, attrs) ->
        scope.getDays = ->
            scope.notification.amount + ' ' + localization.declensionPhrase scope.notification.amount, 'costDays'
        true