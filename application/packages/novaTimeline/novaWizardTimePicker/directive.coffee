*deps: groupService, communityService

scope.timestamp = Date.now() + 5 * MIN

scope.date = new Date(scope.timestamp)
scope.year = scope.date.getFullYear()
scope.month = scope.date.getMonth()
scope.day = scope.date.getDate()
scope.hour = scope.date.getHours()
scope.minute = scope.date.getMinutes()

scope.updateDate = ->
    scope.date = new Date(scope.year, scope.month, scope.day, scope.hour, scope.minute)
    scope.timestamp = toMinutes scope.date.getTime()
    scope.wizard.pick
        id: scope.timestamp
    true

scope.updateDate()
