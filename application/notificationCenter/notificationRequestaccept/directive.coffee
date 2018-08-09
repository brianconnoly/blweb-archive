buzzlike.directive 'notificationRequestaccept', (postService, localization) ->
    template: tC['/notificationCenter/notificationRequestaccept']
    link: (scope, element, attrs) ->
        if scope.notification?.itemList?[2]?
            scope.postId = scope.notification.itemList[2].id

        scope.getSumm = ->
            if scope.notification.buzzLot
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'costDays'
            else
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'roubles'

        # scope.getCost = ->
        #     if scope.notification.buzzLot
        #         return scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'costDays'
        #     else
        #         return scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'roubles'