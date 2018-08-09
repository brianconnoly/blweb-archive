*deps: taskService, projectService
*replace: true

# Basic init
elem = $ element
openedTask = elem.find '.editOpenedTask'
subTasks = elem.find '.subTasks'
scope.taskService = taskService

scope.stateTree.applyState
    'N alt': ->
        scope.addTask()
        true
    'escape': ->
        scope.addTaskActive = false
        true

# Frame params
scope.flowFrame.maxWidth = 516

scope.compact = scope.stateSaver.register 'task_compact_' + scope.flowFrame.item.id,
    save: () ->
        scope.compact
    load: (data) ->
        scope.compact = !!data

scope.triggerCompact = ->
    scope.compact = !scope.compact
    scope.stateSaver.save 'task_compact_' + scope.flowFrame.item.id

if scope.session.item.type == 'project'
    scope.project = projectService.getById scope.session.item.id

# Subtasks
scope.childTasks = taskService.getStorageByParent scope.flowFrame.item.id
scope.showAccepted = false
scope.taskFilter = (item) ->
    if item.deleted
        return false

    if !scope.showAccepted and item.status == 'accepted'
        return false

    if scope.taskFilterString?.length > 0
        lowText = scope.taskFilterString.toLowerCase()
        if item.name?.toLowerCase().indexOf(lowText) > -1 or item.description?.toLowerCase().indexOf(lowText) > -1
            return true
        return false
    true

# Add new task
scope.addTaskActive = false
scope.newTask =
    parent: scope.flowFrame.item.id
    type: 'task'
    name: ""
    description: ""
    entities: []
    projectId: scope.flowFrame.item.projectId
scope.addTask = ->
    scope.addTaskActive = !scope.addTaskActive

# Scroll stuff
domElem = elem.children('.novaFrameContents')[0]
headState = 'default'
realHeight = 0
nuHei = 0
elem.on 'mousewheel', (e, delta) ->
    domElem.scrollTop -= delta

    if domElem.scrollTop > 0 and headState is 'default'
        headState = 'fixed'
        realHeight = openedTask.height() + 5
        subTasks[0].style.marginTop = realHeight #+ 5
        # openedTask.css 'position', 'fixed'
        openedTask.addClass 'fixed'

    else if headState is 'fixed' and domElem.scrollTop == 0
        headState = 'default'
        # openedTask.css 'position', 'relative'
        openedTask.removeClass 'fixed'
        openedTask[0].style.height = 'auto'
        subTasks[0].style.marginTop = 0

    if headState is 'fixed'
        nuHei = realHeight - domElem.scrollTop #- 2
        if nuHei < 0 #28
            nuHei = 0 #28
        openedTask[0].style.height = nuHei
