buzzlike
    .controller 'teamManagerCtrl', ($scope, localization, buffer, $filter, smartDate, complexMenu, actionsService, multiselect, taskService, userService, teamService, updateService, account, confirmBox, desktopService) ->
        
        $scope.myUser = account.user

        $scope.session.textMemory = {} # if !$scope.session.textMemory?
        $scope.tasksScrollValue = 0

        $scope.stateTree.applyState
            'enter': (a,b,e) -> #'default'
                if $(e.target).prop("tagName") in ['INPUT','TEXTAREA']
                    return false
                focused = multiselect.getFocused()
                if focused.length > 0
                    buffer.addItems focused
                else if $scope.currentTeam?
                    buffer.addItem $scope.currentTeam

            'delete': () ->
                items = multiselect.getFocused()

                if items.length > 0
                    confirmBox.init 
                        realText: localization.translate(32) + ' ' + items.length + ' ' + localization.declensionPhrase(items.length, 'teamManagerApp_removeTasks_declension') + '?'
                        description: 'teamManagerApp_removeTasks_description'
                    , () ->

                        ids = []
                        ids.push item.id for item in items

                        buffer.removeItems items

                        for item in items
                            taskService.delete
                                id: item.id
                                type: item.type

            'V cmd': (repeat, defaultAction) ->
                items = multiselect.getFocused()
                tasks = []
                for item in items
                    if item.type == 'task'
                        tasks.push item

                if tasks.length > 0
                    defaultAction tasks
                else if $scope.currentTask.id?
                    defaultAction [$scope.currentTask]
                else
                    defaultAction()

            'U cmd': (repeat, defaultAction) ->
                items = multiselect.getFocused()
                tasks = []
                for item in items
                    if item.type == 'task'
                        tasks.push item

                if tasks.length > 0
                    defaultAction tasks
                else if $scope.currentTask.id?
                    defaultAction [$scope.currentTask]
                else
                    defaultAction()

            'escape': ->
                if $scope.currentTask.created > Date.now() - 3 * SEC
                    taskService.delete $scope.currentTask
                    $scope.closeApp()
                    return

                $scope.stepBack()

        # Invitation stuff -----------------------
        $scope.isInvited = () ->
            if !$scope.currentTeam?
                return false
            for user in $scope.currentTeam.members
                if user.userId == account.user.id and user.roles?.invited == true
                    return true
            false
        $scope.inviteDecline = () ->
            process = $scope.progress.add()
            teamService.call 'declineInvite',
                teamId: $scope.currentTeam.id
            , ->
                $scope.progress.finish process
                $scope.currentTeam.hide = true

                $scope.currentStep = $scope.stepStack[0]
                $scope.stepStack.length = 1
                applyStep $scope.currentStep

        $scope.inviteAccept = () ->
            process = $scope.progress.add()
            teamService.call 'acceptInvite',
                teamId: $scope.currentTeam.id
            , ->
                $scope.progress.finish process

        #
        # Date format optimizer
        #

        tsCache = {}
        $scope.getFormatedDate = (ts) ->
            ts = smartDate.getShiftTimeline(ts)

            if !tsCache[ts]?
                tsCache[ts] = $filter('timestampMask')(ts, 'DD.MMM.YY hh:mm')
            tsCache[ts]

        #
        # Chat
        #

        $scope.account = account
        $scope.newMessage =
            text: ""

        $scope.chatActive = false
        $scope.setChat = (value) -> $scope.chatActive = !!value

        $scope.sendOnEnter = (e) ->
            if e.which == 13 and !e.shiftKey
                e.preventDefault()
                $scope.sendMessage()

        $scope.sendMessage = ->
            if $.trim($scope.newMessage.text) == ""
                return

            toSend = $.trim $scope.newMessage.text
            $scope.newMessage.text = ""

            process = $scope.progress.add()
            taskService.call 'addMessage',
                taskId: $scope.currentTask.id
                text: toSend
            , ->
                $scope.progress.finish process
                true

        $scope.getUser = (id) -> userService.getById id

        #
        # Actions
        #

        $scope.invite = ->
            if !$scope.currentTeam?.id?
                return 

            desktopService.launchApp 'inviteUser', 
                api: 
                    pickUser: (user, rule) ->
                        process = $scope.progress.add()
                        teamService.call 'invite', 
                            teamId: $scope.currentTeam.id
                            userId: user.id
                            role: rule
                        , (res) ->
                            $scope.progress.finish process
                            getUsers()

        $scope.crateTeam = ->
            process = $scope.progress.add()
            teamService.create
                name: 'Новая команда'
                members: [
                    'userId': account.user.id
                    'roles':
                        'owner': true
                ]
            , (team) ->
                $scope.progress.finish process
                $scope.selectTeam team

        $scope.justCreated = null
        $scope.createTask = (e) ->
            process = $scope.progress.add()
            taskService.create
                name: 'Новая задача'
                description: ''
                teamId: $scope.currentTask?.teamId or $scope.currentTeam?.id
                status: 'created'
                parent: $scope.currentTask?.id
            , (task) ->
                $scope.progress.finish process

                $scope.justCreated = task

                if isCmd e
                    desktopService.launchApp 'teamManager',
                        teamId: task.teamId
                        taskId: task.id
                else
                    task.editMode = true
                # $scope.selectTask task if diveIn

        $scope.showMoreMenu = (e) ->
            items = multiselect.getFocused()

            if items.length > 0
                itemsActions = actionsService.getActions
                    source: items
                    context: $scope.currentTask or $scope.currentTeam
            else if $scope.currentTeam?.id?
                    itemsActions = actionsService.getActions
                        source: [$scope.currentTeam]
            else if $scope.currentTask?.id?
                    itemsActions = actionsService.getActions
                        source: [$scope.currentTask]
            
            else
                itemsActions = actionsService.getActions
                    source: [
                        type: 'teamManagerApp'
                    ]

            if itemsActions.length > 0
                groups = {}
                list = []

                for action in itemsActions
                    if !groups[action.category]?
                        groups[action.category] = 
                            type: 'actions' 
                            items: []

                    groups[action.category].items.push 
                        phrase: action.phrase
                        action: action.action
                        priority: action.priority

                for k,actions of groups
                    actions.items.sort (a,b) ->
                        if a.priority > b.priority
                            return -1
                        if a.priority < b.priority
                            return 1
                        0

                complexMenu.show groups,
                    top: $(e.target).offset().top + 27
                    left: $(e.target).offset().left

            true

        #
        # Users
        #

        $scope.users = []

        getUsers = ->
            $scope.users.length = 0

            if $scope.currentTeam?.members?

                for user in $scope.currentTeam.members
                    $scope.users.push user.userId

            else if $scope.currentTask?.users?

                for user in $scope.currentTask.users
                    $scope.users.push user

            else
                $scope.users.push account.user.id

        $scope.$watch 'currentTask.users', (nVal) ->
            getUsers()
        , true

        $scope.$watch 'currentTeam.members', (nVal) ->
            getUsers()
        , true

        $scope.inTask = (userId) ->
            if !$scope.currentTask?.id?
                return true

            userId in $scope.currentTask.users

        $scope.notInTask = (userId) ->
            if !$scope.currentTask?.id?
                return false

            userId not in $scope.currentTask.users

        $scope.userCode = -> account.user.firstName[0].toUpperCase() + if account.user.lastName?[0]? then account.user.lastName[0].toUpperCase() else ''

        $scope.myTasks = false
        $scope.triggerMy = ->
            $scope.myTasks = !$scope.myTasks

            $scope.resetTaskList()
            $scope.fetchTasksPage()

        $scope.memberRole = (id) ->
            if !$scope.currentTeam?.id?
                return 'member'

            member = null
            for user in $scope.currentTeam.members
                if user.userId == id
                    member = user

            if !member?
                return 'member'

            if $scope.currentTeam.userId == member.userId
                return 'owner'
            if member.roles?.invited
                return 'invited'
            if member.roles?.mainEditor
                return 'mainEditor'
            if member.roles?.editor
                return 'editor'

            if member.roles?.contentManager
                return 'contentManager'

            if member.roles?.timeManager
                return 'timeManager'

            if member.roles?.postManager
                return 'postManager'

            if member.roles?.client
                return 'client'

            return 'member'

        #
        # Current task
        #

        $scope.currentTask = null

        $scope.selectTask = (task) ->

            index = $scope.stepStack.indexOf $scope.currentStep
            if $scope.stepStack.length > 1
                $scope.stepStack.splice index+1, $scope.stepStack.length - index

            $scope.currentStep.scrollValue = $scope.tasksScrollValue
            $scope.tasksScrollValue = 0

            $scope.currentStep =
                translateTitle: if task.name?.length > 0 then null else 'taskManagerApp_taskTasks'
                title: task.name
                taskId: task.id
                teamId: task.teamId

            $scope.stepStack.push $scope.currentStep

            preloadTask(task)

        preloadTask = (task) ->
            $scope.currentTask = task
            $scope.tasks.length = 0

            if task.description?.length > 0 or task.entities.length > 0
                $scope.showSettings = true
            else
                $scope.showSettings = false

            $scope.resetTaskList()
            $scope.fetchTasksPage()

            if !$scope.session.textMemory[task.id]?
                $scope.session.textMemory[task.id] = 
                    text: ""
            $scope.newMessage = $scope.session.textMemory[task.id]

            getUsers()

        $scope.saveTask = (task) ->
            process = $scope.progress.add()
            taskService.save task or $scope.currentTask, ->
                $scope.progress.finish process

            task?.editMode = false

        #
        # Current team
        #

        $scope.currentTeam = null
        $scope.taskTeams = []

        $scope.showSettings = false

        $scope.tasks = []

        flushHandler = null
        flushTeam = (teamId) ->
            if flushHandler != null

                clearTimeout flushHandler
                flushHandler = null

            flushHandler = setTimeout ->
                process = $scope.progress.add()
                teamService.flushNew teamId, ->
                    $scope.progress.finish process
            , 5000

        $scope.selectTeam = (team) ->

            $scope.showSettings = false

            if $scope.stepStack.length > 1
                $scope.stepStack.splice 1, $scope.stepStack.length - 1

            $scope.currentStep =
                translateTitle: if team.name?.length > 0 then null else 'teamManagerApp_teamTasks'
                title: team.name
                teamId: team.id

            $scope.stepStack.push $scope.currentStep

            preloadTeam(team)

        preloadTeam = (team, fetchTasks = true) ->
            $scope.currentTeam = team
            $scope.currentTask = null
            $scope.tasks.length = 0

            if fetchTasks
                $scope.resetTaskList()
                $scope.fetchTasksPage()

                getUsers()

        $scope.saveTeam = ->
            process = $scope.progress.add()
            teamService.save $scope.currentTeam, ->
                $scope.progress.finish process

        $scope.isOwner = ->
            account.user.id == $scope.currentTeam.userId

        $scope.leaveTeam = ->
            confirmBox.init 
                phrase: 'teamManager_confirm_leave_team'
                description: 'teamManager_confirm_leave_team_description'
            , ->
                teamService.call 'removeMembers',
                    teamId: $scope.currentTeam.id
                    users: [account.user.id]
                , ->
                    $scope.stepBack()
                    true
            , ->
                 true

        $scope.$watch 'currentTeam.deleted', (nVal) ->
            if nVal == true
                $scope.currentStep = $scope.stepStack[0]
                applyStep $scope.currentStep
                $scope.stepStack.lenght = 1

        #
        # Team lazy loading
        #

        $scope.teamOrder = (item) ->
            map = item?.userUpdated?[0]
            if map?.userId == account.user.id
                if map.unread 
                    return '3' + map.timestamp 
                if map.updates > 0
                    return '2' + map.timestamp
                return '1' + map.timestamp

        $scope.teamFilter = (item) -> 
            if item.deleted == true or item.hide == true
                return false

            if item.userId == account.user.id
                return true

            for user in item.members
                if user.userId == account.user.id
                    return true

            false
            

        $scope.teamParams =
            pageSize: 0
            page: 0
            total: 0
            isLoading: false
            reloadOnStart: false

        $scope.resetTeamList = ->
            $scope.teamParams.pageSize = Math.ceil( ($scope.session.size.height - 100) / 120 ) * 2
            $scope.teamParams.page = 0
            $scope.teamParams.total = 0
            # $scope.taskTeams.length = 0
            $scope.teamParams.isLoading = false
            $scope.teamParams.reloadOnStart = false

        $scope.resetTeamList()

        $scope.fetchTeamsPage = () ->
            if $scope.teamParams.isLoading == true
                return 

            tasksProcess = $scope.progress.add()
            $scope.teamParams.isLoading = true
            teamService.query
                member: account.user.id
                # updateUser: account.user.id
                # limit: $scope.teamParams.pageSize
                # page: $scope.teamParams.page
                # sortBy: 'userUpdated.timestamp'
                # sortType: 'desc'
            , (items, total) ->
                if $scope.taskParams.page == 0
                    $scope.tasks.length = 0

                $scope.progress.finish tasksProcess
                $scope.teamParams.page++
                $scope.teamParams.total = total

                for item in items
                    $scope.taskTeams.push item if item not in $scope.taskTeams

                $scope.teamParams.isLoading = false

        #
        # Tasks lazy loading
        #

        # $scope.taskScrollerOptions = 
        #     minHeight: 40
        #     total: 0
        #     perPage: 0
        #     itemVar: 'item'
        #     template: '<task-item></task-item>'
        #     # watchObject: 'allPosts'
        #     heightOffset: 80
        #     topOffset: 0
        #     bottomOffset: 0
        #     getPage: (page, cb) ->
        #         taskService.query
        #             teamId: $scope.currentTeam?.id
        #             parent: $scope.currentTask?.id or if $scope.currentTeam? then 'null' else undefined
        #             limit: $scope.taskParams.pageSize
        #             page: page
        #             member: if $scope.myTasks then account.user.id else if $scope.currentTeam?.id? then undefined else account.user.id
        #             sortBy: 'created'
        #             sortType: 'desc'
        #         , (items, total) ->
        #             $scope.taskScrollerOptions.total = total
        #             cb items

        $scope.showAccepted = false
        $scope.triggerAccepted = () ->
            $scope.showAccepted = !$scope.showAccepted

            $scope.resetTaskList()
            $scope.fetchTasksPage()

        $scope.taskOrder = (item) ->
            multiply = '1'
            if item.status == 'started' # and item.toUserId == account.user.id
                multiply = '5' 
                if account.user.id in item.users
                    multiply = '9'
            if item.status == 'rejected'
                multiply = '4'
                if account.user.id in item.users
                    multiply = '8'
            if item.status == 'created'
                multiply = '2'
                if account.user.id in item.users
                    multiply = '7'
            if item.status == 'finished'
                multiply = '6'
                if account.user.id == item.userId
                    multiply = 'a'
            if item.status == 'accepted' # and item.fromUserId == account.user.id
                multiply = '0'

            multiply + (item.lastUpdated or item.created)

        
        $scope.taskFilter = (item) ->
            if $scope.currentTeam?
                if $scope.currentTask?
                    return item.parent == $scope.currentTask.id
                else
                    return !item.parent?
            else 
                return true


        $scope.taskParams = 
            pageSize: 0
            page: 50
            total: 0
            isLoading: false
            reloadOnStart: false

        $scope.resetTaskList = ->
            $scope.taskParams.pageSize = Math.ceil( ($scope.session.size.height - 100) / 40 ) * 2
            $scope.taskParams.page = 0
            # $scope.tasks.length = 0
            $scope.taskParams.total = 0
            $scope.taskParams.isLoading = false
            $scope.taskParams.reloadOnStart = false

        $scope.fetchTasksPage = () ->
            if $scope.taskParams.isLoading == true
                return 

            $scope.taskParams.isLoading = true
            tasksProcess = $scope.progress.add()
            taskService.query
                teamId: $scope.currentTeam?.id
                parent: $scope.currentTask?.id or if $scope.currentTeam? then 'null' else undefined
                limit: if $scope.currentTeam? then undefined else $scope.taskParams.pageSize
                page: $scope.taskParams.page
                member: if $scope.myTasks then account.user.id else if $scope.currentTeam?.id? then undefined else account.user.id
                sortBy: 'created'
                sortType: 'desc'
                status: if $scope.showAccepted == true then undefined else {'$ne': 'accepted'}
            , (items, total) ->
                if $scope.taskParams.page == 0
                    multiselect.flush()
                    $scope.tasks.length = 0

                $scope.taskParams.page++
                $scope.taskParams.total = total

                if $scope.currentTeam?
                    $scope.taskParams.pageSize = total

                $scope.progress.finish tasksProcess

                for item in items
                    $scope.tasks.push item if item not in $scope.tasks

                $scope.taskParams.isLoading = false

        updateId = updateService.registerUpdateHandler (data) ->
            if data['team']? 
                if $scope.teamParams.page < 2 or $scope.tasksScrollValue < 300
                    $scope.resetTeamList()
                    $scope.fetchTeamsPage()
                else
                    $scope.teamParams.reloadOnStart = true

            if data['task']?
                if $scope.taskParams.page < 2 or $scope.tasksScrollValue < 300
                    $scope.resetTaskList()
                    $scope.fetchTasksPage()
                else
                    $scope.taskParams.reloadOnStart = true

        $scope.$on '$destroy', ->
            if flushHandler != null
                clearTimeout flushHandler
            updateService.unRegisterUpdateHandler updateId

        $scope.fetchTeamsPage()

        #
        # Steps
        #

        $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0

        $scope.stepBack = ->
            if $scope.stepStack.length > 1
                $scope.stepStack.pop()
                $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]
                applyStep $scope.currentStep

        $scope.stepStack = []

        $scope.currentStep =
            translateTitle: 'teamManagerApp_title'

        $scope.stepStack.push $scope.currentStep

        applyStep = (step) ->
            $scope.showSettings = false
            $scope.chatActive = false

            $scope.tasksScrollValue = step.scrollValue or 0

            if step.teamId?
                process = $scope.progress.add()
                teamService.getById step.teamId, (item) ->
                    $scope.progress.finish process

                    if step.taskId?

                        preloadTeam item, false
                        process = $scope.progress.add()
                        taskService.getById step.taskId, (item) ->
                            $scope.progress.finish process

                            preloadTask item
                    else
                        $scope.currentTask = null
                        preloadTeam item

            else if step.taskId?

                process = $scope.progress.add()
                taskService.getById step.taskId, (item) ->
                    $scope.progress.finish process

                    preloadTask item

            else
                $scope.resetTaskList()
                $scope.currentTeam = null
                $scope.currentTask = null
                $scope.fetchTasksPage()

                getUsers()

        $scope.onJumpStep = ->
            applyStep $scope.currentStep

        # 
        # Save state
        #

        $scope.stateSaver.add 'stepStack', ->
            # Saver
            stack: angular.copy $scope.stepStack
            current: angular.copy $scope.stepStack.indexOf($scope.currentStep)
        , (data) ->
            delete $scope.session.teamId if $scope.session.teamId?
            delete $scope.session.taskId if $scope.session.taskId?

            if data.stack?.length > 0
                $scope.stepStack.length = 0
                # Loader
                for step in data.stack
                    $scope.stepStack.push step

                $scope.currentStep = $scope.stepStack[data.current*1]
                # applyStep $scope.currentStep if $scope.currentStep?

        $scope.$watch 'currentStep', (nVal) ->
            $scope.stateSaver.save()

        if $scope.session.teamId?

            process = $scope.progress.add()
            teamService.getById $scope.session.teamId, (teamItem) ->
                $scope.progress.finish process

                $scope.selectTeam teamItem

                if $scope.session.taskId?
                    process = $scope.progress.add()
                    taskService.getById $scope.session.taskId, (taskItem) ->
                        $scope.progress.finish process

                        $scope.selectTask taskItem

        else if $scope.session.taskId?
            process = $scope.progress.add()
            taskService.getById $scope.session.taskId, (taskItem) ->
                $scope.progress.finish process

                $scope.selectTask taskItem

        else
            applyStep $scope.currentStep

        true

    .directive 'loadFirstTeam', () ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            if !scope.currentTeam? and scope.$index == 0
                scope.selectTeam scope.item

    # .directive 'rememberTaskScroll', () ->
    #     restrict: 'C'
    #     priority: 1
    #     link: (scope, element, attrs) ->
    #         console.log scope
    #         scope.$watch '$parent.tasksScrollValue', (nVal) ->
    #             console.log nVal, element[0], element[0].scrollTop, $(element).children().size()
    #             element[0].scrollTop = nVal
