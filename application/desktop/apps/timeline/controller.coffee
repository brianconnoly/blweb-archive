buzzlike.controller 'timelineCtrl', (buffer, actionsService, complexMenu, postService, contentService, scheduleService, inspectorService, desktopService, ruleService, confirmBox, localization, notificationCenter, multiselect, socketAuth, $rootScope, $scope, groupService, smartDate, localStorageService, account, teamService) ->

    $scope.session.zoom = 'mid' if !$scope.session.zoom?
    $scope.helpFile = 'timeline'

    $scope.session.statsType = 'percent' if !$scope.session.statsType?

    #
    # Actions
    #

    $scope.addFeed = ->
        desktopService.launchApp 'addFeed',
            closeOnAdd: true

    $scope.newText = ->
        items = multiselect.getFocused()

        process = $scope.progress.add()
        contentService.create
            type: 'text'
            value: ''
        , (newText) ->
            buffer.addItem newText

            desktopService.launchApp 'textEditor',
                textId: newText.id

            for item in items
                postService.addContentIds item.postId, [newText.id]

            $scope.progress.finish process

    $scope.newPost = ->
        postService.create {}, (newPost) ->
            buffer.addItem newPost

    $scope.showMoreMenu = (e) ->
        items = multiselect.getFocused()

        if items.length > 0
            itemsActions = actionsService.getActions
                source: items
        else
            itemsActions = actionsService.getActions
                context: {type:'timelineApp'}

        if itemsActions?.length > 0
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
    # State actions
    #

    activeGroup = null
    getActiveGroup = () ->
        if multiselect.state.focusedHash.length > 0
            return $(multiselect.state.lastFocused).parent()
        else
            return $('.feedGroup:hover')[0]

    $scope.stateTree.applyState
        'name': 'timeline'

        'C cmd': () ->            
            items = multiselect.getFocused()
            item = items[0]
            postService.getById item.postId, (post) ->
                multiselect.copyItem post

        'U cmd': (repeat, defaultAction) ->
            
            items = multiselect.getFocused()
            where = []
            for item in items
                if item.type == 'schedule'
                    where.push
                        type: 'post'
                        id: item.postId
                else
                    where.push item
            defaultAction where

        'V cmd': (repeat, defaultAction) ->
            items = multiselect.getFocused()
            defaultAction items

        'delete': () ->
            focused = multiselect.getFocused() # $('.selectableItem.selected', $('.workarea'))
            scheds = []
            cnt = focused.length
            rulesCnt = 0
            schedsCnt = 0

            if cnt > 0

                hasRule = false
                hasScheds = false
                placeholders = []
                for item in focused
                    if item.type == 'placeholder'
                        hasRule = true
                        placeholders.push item
                        rulesCnt++
                    else
                        hasScheds = true
                        scheds.push item
                        schedsCnt++

                if hasRule and hasScheds
                    deleteRules placeholders, (res) ->
                        deleteScheds scheds, schedsCnt
                else if hasRule
                    deleteRules placeholders, (res) ->
                        inspectorService.reset()
                else if hasScheds
                    deleteScheds scheds, schedsCnt
            true

        'left alt': (repeat) =>
            if repeat
                return false

            activeGroup = getActiveGroup()

            if !activeGroup?
                return false

            angular.element(activeGroup).scope().step(-1, false)
            true

        'left alt up': () =>
            if !activeGroup?
                return false

            angular.element(activeGroup).scope().stopStep()
            true

        'right alt': (repeat) ->
            if repeat
                return false

            activeGroup = getActiveGroup()

            if !activeGroup?
                return false

            angular.element(activeGroup).scope().step(1, false)
            true

        'right alt up': () ->
            if !activeGroup?
                return false

            angular.element(activeGroup).scope().stopStep()
            true

    deleteScheds = (focused, cnt) ->
        confirmBox.init 
            realText: localization.translate('post_delete_question') + ' ' + cnt + ' ' + localization.declensionPhrase(cnt, 'post_delete') + '?'
            description: 'post_delete_description'
        , () ->
            deleted = []

            for item in focused

                if item.type == 'schedule'
                    if item.userId != account.user.id
                        notificationCenter.addMessage
                            realText: 'Нельзя распланировать пост, запланированный другим пользователем'
                            error: true
                        return

                    now = new Date().getTime()
                    if smartDate.getShiftTimeBar(item.timestamp) < smartDate.getShiftTimeBar(now) + ( 5*MIN )
                        notificationCenter.addMessage
                            realText: 'Нельзя распланировать пост из прошлого'
                            error: true
                        return

                    if item.id not in deleted
                        deleted.push item.id

                        #scheduleService.removeScheduleById item.id
                        scheduleService.delete 
                            id: item.id

    deleteRules = (placeholders, cb) ->
        simpleDelete = false

        actions = [
            {
                text: 'remove_one'
                action: () ->
                    ruleService.removePlaceholders placeholders
                    return cb? true
            },
            {
                text: 'remove_chain'
                action: () ->
                    for item in placeholders
                        item.cut = true
                    ruleService.removePlaceholders placeholders, true
                    return cb? true
            }
        ]

        for item in placeholders
            if item.ruleType == 'single'
                simpleDelete = true

        if simpleDelete
            actions = [
                {
                    text: 'remove_one'
                    action: () ->
                        ruleService.removePlaceholders placeholders
                        return cb? true
                }
            ]

        desktopService.launchApp 'optionsList',
            message: 'post_delete_question'
            options: actions

    #
    #
    #

    $scope.smartDate = smartDate

    $scope.groups = groupService.storage

    teamService.query
        member: account.user.id
    , (items) ->
        teamIds = []

        for item in items
            if item.openContent != false or item.userId == account.user.id
                teamIds.push item.id
                continue

            for user in item.members
                if user.userId == account.user.id
                    if user.roles?.editor == true or user.roles?.mainEditor == true or user.roles?.timeManager == true or user.roles?.client == true
                        teamIds.push item.id
                    break

        groupService.query
            teamId: 
                '$in': teamIds
        , -> true

    socketAuth.init () ->
        $scope.user = account.user

    true