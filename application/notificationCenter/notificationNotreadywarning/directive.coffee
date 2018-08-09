buzzlike.directive 'notificationNotreadywarning', (buffer, postService, notificationService, stateManager, desktopService) ->
    template: tC['/notificationCenter/notificationNotreadywarning']
    link: (scope, element, attrs) ->

        scope.actions = [
            phrase: 'open'
            action: ->
                # stateManager.faderClick()
                notificationService.markRead scope.notification.id

                postService.getById scope.notification.itemList[0].id, (item) ->
                    desktopService.launchApp 'combEdit',
                        combId: item.combId
                        postId: item.id
        ]