*deps: account, taskService, localization, rpc

elem = $ element
analogStatus = $ elem.find('.analogStatus')[0]
novaLoader = $ elem.find('.novaLoader')[0]
novaLoader.detach()

scope.state = 'status'
scope.actions = []
scope.inProgress = false

exStatus = null
exStatusElem = null
loaderPlaced = false
newButton = (id) ->
    button = $ '<div>',
        class: 'novaButton ' + id
        html: localization.translate 'task_' + id
    button.on 'click', (e) ->
        scope.fireAction id
        scope.$apply()
    button

userEditor = (user, project) ->
    if !(project?.type == 'project')
        return false
    if project.userId == user.id
        return true
    for member in project.members
        if member.userId == user.id
            if member.role in ['mainEditor', 'editor']
                return true
            break
    false

recountButtons = (loader = false) ->
    scope.actions.length = 0

    if exStatus == scope.item.status and !loader
        return

    if loaderPlaced
        novaLoader.detach()
        loaderPlaced = false

    newStatus = $ '<div>',
        class: 'statusBlock ' + (if !exStatus? then '' else 'right')

    # Check if can start
    hasButtons = false
    if !loader then switch scope.item.status
        when 'created', null
            if scope.item.users.length == 0
                # Check if user can take tasks
                # scope.actions.push 'start'
                newStatus.append newButton('start')
                hasButtons = true
            else if account.user.id in scope.item.users
                # scope.actions.push 'start'
                newStatus.append newButton('start')
                hasButtons = true
        when 'started'
            if account.user.id in scope.item.users
                # scope.actions.push 'finish'
                newStatus.append newButton('finish')
                hasButtons = true
        when 'finished'
            # Check team owners
            if account.user.id == scope.item.userId or userEditor(account.user, scope.appItem)
                # scope.actions.push 'accept'
                # scope.actions.push 'reject'
                newStatus.append newButton('reject')
                newStatus.append newButton('accept')
                hasButtons = true
        when 'rejected'
            if account.user.id in scope.item.users
                # scope.actions.push 'restart'
                newStatus.append newButton('restart')
                hasButtons = true

    if loader
        loaderPlaced = true
        hasButtons = true
        newStatus.append novaLoader

    if !hasButtons
        newStatus.append $ '<div>',
            class: 'taskStatus'
            html: localization.translate 'taskItem_status_' + scope.item.status

    analogStatus.append newStatus

    if exStatusElem?
        ((exElm) ->
            exElm.addClass 'left'
            setTimeout ->
                exElm.remove()
            , 200
        ) exStatusElem

    exStatusElem = newStatus
    exStatus = scope.item.status

    setTimeout ->
        newStatus.removeClass 'right'
    , 0

scope.$watch 'item.status', ->
    recountButtons()

scope.$watch 'item.users', ->
    recountButtons()
, true

scope.fireAction = (action) ->
    scope.actions.length = 0
    # elem.addClass 'inProgress'
    recountButtons true
    if action == 'restart'
        action = 'start'
    action += 'ed'

    rpc.call
        method: 'task.setStatus'
        data:
            taskId: scope.item.id
            status: action
        error: ->
            recountButtons true
    true
