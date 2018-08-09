*deps: account, taskService
*template: null

scope.childStatus = 'default'
getStatus = ->
    if scope.item.status == 'rejected'
        scope.childStatus = 'rejected'
        return
    if scope.item.status == 'finished'
        scope.childStatus = 'finished'
        return
    if account.user.id in scope.item.users
        scope.childStatus = 'mine'
        if scope.item.status == 'started'
            scope.childStatus = 'started'
        return
    if scope.item.status == 'created'
        scope.childStatus = 'created'
        return
    scope.childStatus = 'default'

scope.childTaskItem = scope.item
scope.$watch 'item', (nVal) ->
    if nVal.type?
        getStatus()
, true

inProgress = false
scope.markClick = (task) ->
    if inProgress
        return

    toSet = null
    switch task.status
        when 'created'
            toSet = 'started'
        when 'started'
            toSet = 'finished'
        when 'finished'
            toSet = 'accepted'
        when 'rejected'
            toSet = 'started'

    if toSet?
        inProgress = true
        taskService.call 'setStatus',
            taskId: task.id
            status: toSet
        , ->
            inProgress = false
