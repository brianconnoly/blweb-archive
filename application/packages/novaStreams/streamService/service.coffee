*deps: itemService, account, rpc, novaWizard, localization, novaDesktop, actionsService

class classEntity extends itemService
    itemType: 'stream'

    init: () ->
        super()

        # Chats
        actionsService.registerAction
            sourceType: 'userNotMe'
            phrase: 'start_chat'
            category: "A"
            action: (data) =>
                @call 'getUserChat',
                    userIds: data.ids
                , (stream) ->
                    novaDesktop.launchApp
                        app: 'novaStreamsApp'
                        stream: stream
                        item:
                            type: 'streams'
                            id: account.user.id

        actionsService.registerAction
            sourceType: 'content'
            targetType: 'streamMessageBox'
            phrase: 'add_to_message'
            action: (data) ->
                for item in data.items
                    data.target.items.push item

        actionsService.registerAction
            sourceType: 'stream'
            phrase: 'delete'
            action: (data) =>
                for id in data.ids
                    @delete
                        id: id
                        type: 'stream'

        novaWizard.register 'stream',
            type: 'simple'
            action: =>
                @create
                    type: 'stream'
                    name: localization.translate('stream_defaultTitle')
                , (stream) ->
                    novaDesktop.launchApp
                        app: 'novaStreamsApp'
                        item:
                            type: 'streams'
                            id: account.user.id


new classEntity()
