buzzlike.directive 'taskStatusAction', (teamService, taskService, userService, account, complexMenu) ->
    restrict: 'C'
    template: tC['/desktop/apps/teamManager/taskStatus']
    # replace: true
    link: (scope, element, attrs) ->

        scope.statusActionTask = scope.item or scope.currentTask

        scope.action = null
        scope.hasMoreActions = false
        scope.bigDaddy = false
        initAction = ->
            scope.action = null
            scope.hasMoreActions = false
            if !scope.taskTeam?.id?
                return

            if account.user.id in scope.statusActionTask.users
                switch scope.statusActionTask.status
                    when 'created'
                        scope.action = 'started'
                        # return
                    when 'started'
                        scope.action = 'finished'
                        scope.hasMoreActions = true
                        # return
                    when 'rejected'
                        scope.action = 'restarted'
                        # return
                    when 'finished'
                        scope.hasMoreActions = true
                        # return

            # if scope.action == null
            scope.bigDaddy = false
            if account.user.id == scope.statusActionTask.userId or account.user.id == scope.taskTeam.userId
                scope.bigDaddy = true
            else
                for user in scope.taskTeam.members
                    if user.userId == account.user.id
                        if user.roles?.editor == true or user.roles?.mainEditor == true
                            scope.bigDaddy = true
                        break

            if scope.bigDaddy
                switch scope.statusActionTask.status
                    when 'created', 'started'
                        return
                    when 'finished'
                        scope.hasMoreActions = true
                        scope.action = 'accepted'
                        return
                    when 'accepted', 'rejected'
                        scope.hasMoreActions = true
                        return

        getTeam = ->
            if scope.statusActionTask?.teamId?
                taskProcess = scope.progress.add()
                scope.taskTeam = teamService.getById scope.statusActionTask.teamId, (item) ->
                    scope.progress.finish taskProcess
                    scope.taskTeam = item
                    # initAction()

        scope.$watch 'statusActionTask.status', (nVal) ->
            initAction()

        scope.$watch 'statusActionTask.users', (nVal) ->
            initAction()
        , true

        if !scope.item?
            scope.$watch 'currentTask', (nVal) ->
                if nVal?.id?
                    scope.statusActionTask = nVal
                    getTeam()
                    initAction()
        else
            getTeam()
            initAction()

        scope.setStatus = (status) ->
            if status == 'restarted'
                status = 'started'

            statusProcess = scope.progress.add()
            taskService.call 'setStatus',
                taskId: scope.statusActionTask.id
                status: status
            , -> 
                scope.progress.finish statusProcess
                # initAction()

        scope.showMenu = (e) ->
            actions = []

            if !scope.bigDaddy and account.user.id in scope.statusActionTask.users 
                if scope.statusActionTask.status == 'finished'
                    actions.push 
                        phrase: 'task_restart'
                        action: ->
                            scope.setStatus 'started'

                if scope.statusActionTask.status == 'started'
                    actions.push 
                        phrase: 'task_revert'
                        action: ->
                            scope.setStatus 'created'

            if scope.bigDaddy

                if scope.statusActionTask.status != 'accepted'
                    actions.push 
                        phrase: 'task_accept'
                        action: ->
                            scope.setStatus 'accepted'

                if scope.statusActionTask.status != 'rejected'
                    actions.push 
                        phrase: 'task_reject'
                        action: ->
                            scope.setStatus 'rejected'

                actions.push
                    phrase: 'task_start'
                    action: ->
                        scope.setStatus 'started'

                actions.push
                    phrase: 'task_finish'
                    action: ->
                        scope.setStatus 'finished'

            if actions.length < 1
                return

            complexMenu.show [
                    type: 'actions'
                    items: actions
            ],
                top: $(e.target).offset().top + 20
                left: $(e.target).offset().left - 180

        true
