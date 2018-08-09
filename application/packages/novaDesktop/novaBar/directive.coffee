*deps: projectService, account, rpc, novaDesktop, novaMenu

elem = $ element
systemMenu = $ elem.find('.systemMenu')[0]

scope.user = account.user
scope.novaDesktop = novaDesktop

projectService.query
    member: account.user.id

launchers = []
scope.getLaunchers = ->
    launchers.length = 0
    for id, launcher of novaDesktop.launchers
        launchers.push launcher if launcher.dock == true
    launchers

scope.showOptions = ->
    rpc.call 'auth.logout'

scope.showSystemMenu = (e) ->
    sections = [
        type: 'actions'
        items: [
            phrase: 'novaSystemMenu_about'
            action: ->
                window.open('https://vk.com/buzzlike','_blank');
        ,
            phrase: 'novaSystemMenu_settings'
            action: ->
                novaDesktop.launchApp
                    app: 'novaSettingsApp'
        ,
            phrase: 'novaSystemMenu_logout'
            description: 'streamFrame_import_description'
            action: ->
                novaDesktop.launchApp
                    app: 'novaOptionsListApp'
                    noSave: true
                    data:
                        text: 'popup_exit_title'
                        description: 'popup_exit_subtitle'
                        onAccept: =>
                            rpc.call 'auth.logout'
        ]
    ]

    offset = systemMenu.offset()
    novaMenu.show
        position:
            x: offset.left + Math.ceil(systemMenu.width() / 2) #e.pageX
            y: offset.top - 10
        sections: sections
        menuStyle: 'center'
        noApply: true
    true

scope.launchApp = (launcher) ->
    novaDesktop.launchApp
        app: launcher.app
        item: launcher.item

scope.newBuffer =
    type: 'newBuffer'
