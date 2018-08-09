buzzlike.directive 'taskItem', (teamService, taskService, userService, account, complexMenu) ->
    restrict: 'E'
    template: tC['/desktop/apps/teamManager/taskItem']
    replace: true
    link: (scope, element, attrs) ->

        if scope.$last
            $(element).parent()[0].scrollTop = scope.$parent.tasksScrollValue

        if scope.$parent.justCreated == scope.item
            scope.$parent.tasksScrollValue = scope.$index * 40
            $(element).parent()[0].scrollTop = scope.$parent.tasksScrollValue

        ownerProcess = scope.progress.add()
        scope.taskOwner = userService.getById scope.item.userId, (item) ->
            scope.progress.finish ownerProcess
            scope.fromUser = item.firstName[0].toUpperCase() + if item.lastName?[0]? then item.lastName[0].toUpperCase() else ''

        getExecutorInfo = ->
            scope.toUser = ''
            if scope.item.users.length > 0
                execProcess = scope.progress.add()
                scope.taskExecutor = userService.getById scope.item.users[scope.item.users.length - 1], (item) ->
                    scope.progress.finish execProcess
                    scope.toUser = item?.firstName?[0]?.toUpperCase() or ""
                    if item.lastName?[0]? 
                        scope.toUser += item.lastName[0].toUpperCase()

                    if scope.item.users.length > 1
                        scope.toUser += ' (' + scope.item.users.length + ')'
                    # initAction()

        getExecutorInfo()

        scope.$watch 'item.users', (nVal) ->
            getExecutorInfo()
        , true

        lastClick = 0
        scope.params =
            editTitle: ''
        scope.editTask = (e) ->
            if scope.item.editMode == true
                return true

            now = Date.now()
            diff = now - lastClick
            if diff < 1500 and diff > 500
                # for task in scope.tasks
                #     task.editMode = false
                scope.params.editTitle = scope.item.name
                scope.item.editMode = true
                lastClick = 0

            lastClick = now

        # $(element).on 'blur.taskItem', (e) ->
            # scope.item.editMode = false

        scope.saveTitle = () ->
            if scope.params.editTitle == ''
                scope.params.editTitle = scope.item.name

            if scope.params.editTitle != scope.item.name
                scope.item.name = scope.params.editTitle
                scope.$parent.saveTask scope.item

            scope.item.editMode = false

        scope.resetTitle = ->
            scope.params.editTitle = scope.item.name
            scope.item.editMode = false

        scope.test = (e) ->
            e.stopPropagation()

        # scope.hasActions = ->
        #     if !scope.taskTeam?.id?
        #         return

        #     switch scope.item.status
        #         when 'created', 'started', 'rejected'
        #             # Show only to task members
        #             return account.user.id in scope.item.users
        #         when 'finished'
        #             # Show to task owner or team administry
        #             if account.user.id == scope.item.userId
        #                 return true
        #             for user in scope.taskTeam.members
        #                 if user.userId == account.user.id
        #                     return user.roles?.editor == true or user.roles?.mainEditor == true
                            
        #         when 'accepted'
        #             return false


buzzlike.directive 'smartTaskTitle', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        $(element).on 'blur.taskTitle', (e) ->
            scope.saveTitle()
            scope.$apply()
        .on 'keydown', (e) ->
            if e.which == 13
                scope.saveTitle()
                scope.$apply()
            if e.which == 27
                e.stopPropagation()
                scope.resetTitle()
                scope.$apply()
