*deps: account, userService
# *replace: true

elem = $ element

if scope.appItem.profileUserId?
    if scope.item.userId == account.user.id
        scope.me = true

scope.user = userService.getById scope.item.userId
if scope.item.userId == account.user.id
    scope.mine = true
    elem.addClass 'mine'
