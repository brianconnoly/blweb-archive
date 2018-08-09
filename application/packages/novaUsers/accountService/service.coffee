*deps: itemService, account

class accountService extends itemService

    itemType: 'account'

    constructor: ->
        super()

    fetchById: (id, cb) ->
        console.log id
        for acc in account.user.accounts
            if acc.publicId == id
                handled = @handleItem acc
                cb? handled
                return handled

        handled = @handleItem
            id: id
        cb? handled
        handled

new accountService()
