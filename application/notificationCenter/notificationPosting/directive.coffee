buzzlike.directive 'notificationPosting', (buffer, postService, notificationService, stateManager) ->
    template: tC['/notificationCenter/notificationPosting']
    link: (scope, element, attrs) ->

        scope.actions = [
            phrase: 'take_to_right'
            action: ->
                # stateManager.faderClick()
                notificationService.markRead scope.notification.id

                postService.getById scope.notification.itemList[0].id, (item) ->
                    buffer.addItems [item]
        ]