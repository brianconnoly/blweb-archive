buzzlike.directive 'notificationRequestnew', (lotService, stateManager, notificationService, desktopService, localization) ->
    template: tC['/notificationCenter/notificationRequestnew']
    link: (scope, element, attrs) ->
        if scope.notification?.itemList?[3]?
            scope.lotId = scope.notification.itemList[3].id

        scope.getSumm = ->
            if scope.notification.buzzLot
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'costDays'
            else
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'roubles'

        scope.actions = [
            phrase: 'go_to_lot_requests'
            action: ->
                notificationService.markRead scope.notification.id

                desktopService.launchApp 'lotManager', 
                    lotId: scope.notification.itemList[3].id

        ]
        true