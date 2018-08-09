buzzlike.directive 'notificationButtons', () ->
    restrict: 'C'
    template: tC['/notificationCenter/notificationButtons']
    replace: true
    link: (scope, element, attrs) ->
        scope.buttons = []

        scope.sysMessages = false
        scope.unreadNotifications = false

        if $(element).parent().attr('systemmessage') == 'true'
            scope.sysMessages = true

        if $(element).parent().attr('unreadnotifications') == 'true'
            scope.unreadNotifications = true

        rebuildActions = ->
            scope.buttons.length = 0

            if scope.sysMessages
                scope.buttons.push
                    phrase: 'notification_button_close'
                    action: ->
                        scope.removeMessage scope.notification

            if scope.unreadNotifications
                scope.buttons.push
                    phrase: 'hide_notification'
                    action: ->
                        scope.markRead scope.notification

            if scope.actions?.length > 0
                for action in scope.actions
                    scope.buttons.push action

        scope.$watch 'actions', (nVal) ->
            rebuildActions()
        true