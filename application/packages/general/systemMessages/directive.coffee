*deps: notificationCenter, notificationService

scope.messages = notificationCenter.messages

scope.hasPreview = (msg) -> msg.item?
scope.removeMessage = (msg, hover) ->
    if msg.notificationType? and hover
        return false

    if msg.notificationType?
        notificationService.markRead msg.id

    if (hover and !msg.error and !msg.solid) or !hover
        notificationCenter.removeMessage(msg)