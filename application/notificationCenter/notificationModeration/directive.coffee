buzzlike.directive 'notificationModeration', (lotService, desktopService, stateManager, notificationService) ->
    template: tC['/notificationCenter/notificationModeration']
    link: (scope, element, attrs) ->

        scope.actions = [
            phrase: 'go_to_lot_requests'
            action: ->
                notificationService.markRead scope.notification.id

                desktopService.launchApp 'lotManager', 
                    lotId: scope.notification.itemList[0].id

        ]

        true