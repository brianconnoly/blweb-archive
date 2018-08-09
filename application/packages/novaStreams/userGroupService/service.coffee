*deps: itemService, account, rpc, novaWizard, localization, novaDesktop

class classEntity extends itemService
    itemType: 'userGroup'

    init: () ->
        super()

        novaWizard.register 'userGroup',
            type: 'simple'
            action: =>
                @create
                    type: 'userGroup'
                    name: localization.translate('userGroup_defaultTitle')
                , (userGroup) ->
                    novaDesktop.launchApp
                        app: 'novaStreamsApp'
                        item:
                            type: 'streams'
                            id: account.user.id


new classEntity()
