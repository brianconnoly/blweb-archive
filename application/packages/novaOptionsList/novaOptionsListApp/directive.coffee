
elem = $ element

scope.session.noItem = true
scope.session.startPosition = 'center'
scope.session.size =
    width: 500
    height: 'auto'

scope.session.noSave = true

if !(scope.session.data?.options?.length > 0)
    scope.session.data.options = []

    scope.session.data.options.push
        text: 79
        action: () -> scope.closeApp()
        class: 'cancel'

    scope.session.data.options.push
        text: 'novaOptionsListApp_ok'
        action: () -> scope.accept()

scope.accept = ->
    scope.session.data.onAccept?()
    scope.closeApp()

scope.check = (option) ->
    !option.check? or option.check()

scope.fire = (option) ->
    option.action()
    scope.closeApp()
