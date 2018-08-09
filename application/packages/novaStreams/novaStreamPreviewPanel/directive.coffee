*deps: userService, account

userIds = []
for member in scope.item.members
    userIds.push member.userId if member.userId != account.user.id

scope.title = ""
scope.userPhoto = null
userService.getByIds userIds, (users) ->
    scope.userPhoto = users[0]?.photo
    for user in users
        scope.title += ', ' if scope.title != ""
        scope.title += user.name
