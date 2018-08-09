*deps: novaListScroller, dynamicStyle, taskService, updateService, account, projectService
*replace: true

scope.stateTree.applyState
    'N alt': ->
        scope.addTask()
        true
    'escape': ->
        scope.addTaskActive = false
        true

# Basic init
elem = $ element
scope.taskService = taskService

if scope.session.item.type == 'project'
    scope.project = projectService.getById scope.session.item.id

scope.compact = scope.stateSaver.register 'tasks_compact_' + scope.flowFrame.data.mode,
    save: () ->
        scope.compact
    load: (data) ->
        scope.compact = !!data

scope.triggerCompact = ->
    scope.compact = !scope.compact
    scope.stateSaver.save 'tasks_compact_' + scope.flowFrame.data.mode

# Frame params
scope.flowFrame.maxWidth = 516

# Scroller ==============
scrollerElem = elem.find '.novaFrameContents'
# scope.scroller = new novaListScroller
#     query:
#         projectId: scope.flowFrame.data.projectId or null
#         users: if scope.flowFrame.data.mode == 'mine' then account.user.id else undefined
#         status:
#             $ne: 'accepted'
#     sortBy: 'created'
#     pageHeight: scrollerElem.height()
#     elem: scrollerElem
#     lineHei: 30
#     queryFunc: taskService.query
#     apply: ->
#         scope.$applyAsync()
#     sortFunc: (item) ->
#         taskService.taskOrder item #, true) * 1

# scope.handleResizeEnd = ->
    # scope.scroller.rebuild()

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

# Simple scroller
scope.tasks = []
currentPage = 0
loadingInProgress = false
getPage = ->
    if loadingInProgress
        return
    loadingInProgress = true
    query =
        limit: 60
        page: currentPage
        entityId: scope.flowFrame.data.entityId
        projectId: scope.flowFrame.data.projectId
        status:
            $ne: 'accepted'
        parent: null
    currentPage++

    if scope.flowFrame.data.mode == 'mine'
        query.users = account.user.id
        query.mode = 'current'
        delete query.parent
    else
        query.mode = scope.flowFrame.data.mode

    if scope.showAccepted
        delete query.status

    if query.page == 0
        scope.tasks.length = 0

    taskService.query query, (items) ->
        ids = []
        for item in items
            ids.push item.id

        for item in items
            if item.parent not in ids
                scope.tasks.push item
        loadingInProgress = false

getPage()

# Accepted
scope.showAccepted = false
scope.$watch 'showAccepted', (nVal, oVal) ->
    if nVal != oVal
        # if nVal == true
        #     delete scope.scroller.query.status if scope.scroller.query.status?
        # else
        #     scope.scroller.query.status =
        #         $ne: 'accepted'
        # scope.scroller.reloadAll()
        currentPage = 0
        getPage()

# Add new task
scope.addTaskActive = false
scope.newTask =
    type: 'task'
    name: ""
    description: ""
    entities: []
    projectId: if scope.flowFrame.data.projectId? then scope.flowFrame.data.projectId else null
    mode: scope.flowFrame.data.mode

if scope.session.item.type != 'project'
    scope.newTask.entities.push
        id: scope.session.item.id
        type: scope.session.item.type

scope.addTask = ->
    scope.addTaskActive = !scope.addTaskActive

updateId = updateService.registerUpdateHandler (data, action, items) ->

    if action in ['update','create','delete']
        if data['task']?
            affected = []
            for item in items
                if !item.parent? and item.type == 'task'

                    if scope.session.item.type != 'project'
                        for entity in item.entities
                            if entity.id == scope.session.item.id
                                affected.push item
                                continue

                    else

                        if scope.flowFrame.data.projectId?
                            if item.projectId != scope.flowFrame.data.projectId
                                continue

                        affected.push item

                if item in scope.tasks
                    affected.push item

            if affected.length > 0
                # scope.scroller.updated affected, action
                for item in affected
                    if item.deleted == true or item.parent?
                        removeElementFromArray item, scope.tasks
                    else
                        scope.tasks.push item if item not in scope.tasks
                scope.$apply()

scope.$on '$destroy', ->
    updateService.unRegisterUpdateHandler updateId
