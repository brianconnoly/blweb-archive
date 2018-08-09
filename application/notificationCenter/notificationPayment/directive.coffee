buzzlike.directive 'notificationPayment', (localization) ->
    template: tC['/notificationCenter/notificationPayment']
    link: (scope, element, attrs) ->
        scope.getSumm = ->
            scope.notification.amount + ' ' + localization.declensionPhrase scope.notification.amount, 'roubles'
        true