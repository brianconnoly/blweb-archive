*deps: itemService, account, rpc, actionsService

class classEntity extends itemService
    itemType: 'contactList'

    init: () ->
        @byUserId = {}
        super()

        actionsService.registerAction
            sourceType: 'userNotMe'
            sourceContext: 'contactList'
            phrase: 'remove_from_list'
            action: (data) =>
                @call 'removeMembers',
                    id: data.sourceContext.id
                    users: data.ids

    getByUserId: (userId, cb) ->
        if @byUserId[userId] == true
            cb? @byUserId[userId]
            return @byUserId[userId]

        @call 'getByUserId', (item) =>
            cb? @handleItem item

    handleItem: (item) ->
        handled = super item

        @byUserId[handled.userId] = handled

        handled

new classEntity()
