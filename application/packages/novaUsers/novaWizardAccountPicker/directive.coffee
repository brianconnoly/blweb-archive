*deps: account, accountService

scope.items = []

# scope.pickAccount = (item) ->
#     scope.wizard.data.accountPublicId = item.publicId
#     scope.nextStep()

for acc in account.user.accounts
    acc.type = 'account'
    acc.id = acc.publicId
    scope.items.push acc

    # if acc.publicId == scope.wizard.data.accountPublicId
    #     scope.pick acc
