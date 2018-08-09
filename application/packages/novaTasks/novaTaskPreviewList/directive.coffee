*deps: taskService, account
*replace: true

elem = $ element

scope.taskItem = scope.item
scope.childTasks = taskService.getStorageByParent scope.item.id
# taskService.query
#     parent: scope.item.id
scope.subtasksFilter = (item) ->
    item.status != 'accepted'

scope.completed = 0
scope.progress = 0
scope.started = 0
scope.$watch 'childTasks', (nVal) ->
    scope.completed = 0
    scope.started = 0
    if nVal?.length > 0
        for item in nVal
            if item.status == 'accepted'
                scope.completed++
            else if item.status != 'created'
                scope.started++
        scope.progress = (scope.completed / nVal.length) * 100 | 0
        if scope.completed + scope.started == nVal.length
            scope.started = 100 - scope.progress
        else
            scope.started = (scope.started / nVal.length) * 100 | 0
, true

scope.openTask = (task, e) ->
    e.stopPropagation()
    e.preventDefault()

    scope.flowFrame.flowBox.addFlowFrame
        title: 'task'
        directive: 'novaTaskFrame'
        item: task
    , scope.flowFrame

scope.taskStyle = 'default'
getStyle = ->
    if scope.item.status == 'accepted'
        scope.taskStyle = 'accepted'
        return
    if scope.item.status == 'rejected'
        scope.taskStyle = 'rejected'
        return
    if scope.item?.users?.length? and account.user.id in scope.item.users
        scope.taskStyle = 'mine'
        return
    scope.taskStyle = 'default'

lastPos = 0
scope.$watch 'item', ->
    getStyle()
    # if elem.parents('.selected').length > 0
    if scope.multiselect.isSelected scope.item
        if scope.session.size.height - 100 > elem.parent().position().top > 0
            lastPos = elem.parent().position().top
        else
            oldPos = elem.parent().parent()[0].scrollTop + elem.parent().position().top# - elem.parent().parent()[0].scrollTop
            # console.log oldPos, elem.parent().parent()[0].scrollTop, lastPos
            setTimeout ->
                # console.log elem.position(), elem.parent().position()
                elem.parent().parent().animate #[0].scrollTop += elem.parent().position().top + lastPos
                    'scrollTop': elem.parent().parent()[0].scrollTop + elem.parent().position().top - lastPos
            , 0

, true

scope.hasItems = ->
    scope.item?.entities?.length > 0 and scope.item?.entities?[0]?.id != scope.appItem.id

# # Subtask style
# scope.getChildStatus = (childTask) ->
#
