buzzlike.directive 'notificationRequestbet', (postService, localization) ->
    template: tC['/notificationCenter/notificationRequestbet']
    link: (scope, element, attrs) ->
        if scope.notification?.itemList?[2]?
            scope.postId = scope.notification.itemList[2].id

        scope.getSumm = ->
            if scope.notification.buzzLot
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'costDays'
            else
                scope.notification.cost + ' ' + localization.declensionPhrase scope.notification.cost, 'roubles'

