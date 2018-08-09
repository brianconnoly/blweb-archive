*deps: account, userService
*replace: true

elem = $ element

scope.user = userService.getById scope.item.userId
if scope.item.userId == account.user.id
    scope.mine = true
    elem.addClass 'mine'
