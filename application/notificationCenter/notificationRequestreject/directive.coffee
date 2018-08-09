buzzlike.directive 'notificationRequestreject', (postService) ->
    template: tC['/notificationCenter/notificationRequestreject']
    link: (scope, element, attrs) ->
        if scope.notification?.itemList?[2]?
            scope.postId = scope.notification.itemList[2].id
