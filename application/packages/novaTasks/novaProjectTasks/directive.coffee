*deps: taskService

elem = $ element
scope.moduleName = 'novaProjectTasks_title'

scope.subItems = [
    phrase: 'novaProjectTasks_mine'
    mode: 'mine'
,
    phrase: 'novaProjectTasks_current'
    mode: 'current'
,
    phrase: 'novaProjectTasks_backlog'
    mode: 'backlog'
,
    phrase: 'novaProjectTasks_icebox'
    mode: 'icebox'
]

scope.isActive = (item) ->
    scope.flow?.currentCode == 'tasks_' + item.mode

scope.activateSubItem = (item) ->
    data =
        projectId: scope.session.item.id
        mode: item.mode

    if scope.session.item.type != 'project'
        data.projectId = scope.appItem.projectId
        data.entityId = scope.session.item.id

    scope.flow.addFrame
        title: 'tasks_' + item.mode
        translateTitle: 'novaTasksFrame_tasks_' + item.mode
        directive: 'novaTasksFrame'
        data: data
        code: 'tasks_' + item.mode
    true

scope.activateAll = ->

    frames = [
        translateTitle: 'novaTasksFrame_tasks_mine'
        directive: 'novaTasksFrame'
        data:
            projectId: scope.appItem.projectId or scope.session.item.id
            entityId: if scope.session.item.type != 'project' then scope.session.item.id else undefined
            mode: 'mine'
        code: 'tasks_mine'
    ,
        translateTitle: 'novaTasksFrame_tasks_backlog'
        directive: 'novaTasksFrame'
        data:
            projectId: scope.appItem.projectId or scope.session.item.id
            entityId: if scope.session.item.type != 'project' then scope.session.item.id else undefined
            mode: 'backlog'
        code: 'tasks_backlog'
    ,
        translateTitle: 'novaTasksFrame_tasks_current'
        directive: 'novaTasksFrame'
        data:
            projectId: scope.appItem.projectId or scope.session.item.id
            entityId: if scope.session.item.type != 'project' then scope.session.item.id else undefined
            mode: 'current'
        code: 'tasks_current'
    ]

    for frame in frames
        scope.flow.addFrame frame, true, true
