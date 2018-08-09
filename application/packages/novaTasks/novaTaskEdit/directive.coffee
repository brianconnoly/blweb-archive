*deps: $parse, taskService

elem = $ element

scope.childTasks = []
scope.createMode = attrs.novaTaskCreate?

unreg = scope.$watch 'item.type', (nVal) ->
    if !nVal?
        return
    unreg()
    scope.taskItem = scope.item #$parse(attrs.novaItemObject)(scope)

scope.taskModes = ['current','backlog','icebox']
# Updating stuff
scope.updateTask = ->
    if !scope.createMode and scope.item.blank != true
        taskService.save scope.item

scope.updateMode = ->
    taskService.call 'setMode',
        taskId: scope.item.id
        mode: scope.item.mode

# Creating stuff
scope.addSubTask = ->
    scope.childTasks.push
        name: ""

scope.canCreate = ->
    scope.item.name.length > 0
scope.doCreateTask = ->
    scope.$parent.addTaskActive = false

    taskService.create scope.item, (createdTask) ->

        for child in scope.childTasks
            if child.name.length > 0
                taskService.create
                    name: child.name
                    parent: createdTask.id
                    projectId: createdTask.projectId

    scope.item.name = ""
    scope.item.description = ""
    scope.item.entities.length = 0

scope.jumpDescription = ->
    elem.find('.taskDescription').focus()
