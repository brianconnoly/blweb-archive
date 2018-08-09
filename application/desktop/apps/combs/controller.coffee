buzzlike.controller 'combsCtrl', ($scope, desktopService, operationsService, groupService, account, teamService, complexMenu, uploadService, contentService, postService, combService, multiselect, buffer, actionsService, confirmBox, localization) ->

    $scope.session.zoom = 'mid' if !$scope.session.zoom?
    $scope.helpFile = 'themes'

    $scope.stateTree.applyState
        'V cmd': (repeat, defaultAction) ->
            items = multiselect.getFocused()
            defaultAction items

        'U cmd': (repeat, defaultAction) ->
            items = multiselect.getFocused()
            defaultAction items

        'delete': () ->
            items = multiselect.getFocused()

            if items.length > 0
                confirmBox.init 
                    realText: localization.translate(32) + ' ' + items.length + ' ' + localization.declensionPhrase items.length, 'combs_deletion_number'
                    description: 'comb_delete_description'
                , () ->

                    ids = []
                    ids.push item.id for item in items

                    buffer.removeItems items

                    deleted = []
                    for item in items
                        if item.id not in deleted
                            deleted.push item.id
                            if combService.exists item.id
                                combService.delete item

        'escape': ->
            $scope.stepBack()

    if !$scope.session.filterTypes?
        $scope.session.filterTypes = 
            image: false
            text: false
            url: false
            video: false
            audio: false
            poll: false
            file: false

    $scope.stepStack = []
    $scope.currentStep = 
        translateTitle: 'combsApp_myCombs'
        flow: true
        sortBy: 'created'
        itemType: 'comb'
        notSended: false
        notScheduled: false
        query: {}

    $scope.stepStack.push $scope.currentStep

    sortTypes = ['created', 'lastUpdated', 'lastSent', 'lastScheduled']
    $scope.showSortMenu = (e) ->
        complexMenu.show [
                object: $scope.currentStep
                type: 'select'
                param: 'sortBy'
                items: [
                        phrase: 'filter_catalog_sort_by_community'
                        value: 'communities'
                    ,
                        phrase: 'filter_catalog_sort_created'
                        value: 'created'
                    ,
                        phrase: 'filter_catalog_sort_lastUpdated'
                        value: 'lastUpdated'
                    ,
                        phrase: 'filter_catalog_sort_lastSent'
                        value: 'lastUseInSentPosts'
                        disabled: $scope.currentStep.notSended == true
                    ,
                        phrase: 'filter_catalog_sort_lastScheduled'
                        value: 'lastUseInCombs'
                        disabled: $scope.currentStep.notScheduled == true
                ]
            ,
                object: $scope.currentStep.query
                type: 'checkbox'
                items: [
                        phrase: 'filter_settings_hide_sent'
                        param: 'hideAllSent'
                        disabled: $scope.currentStep.sortBy.indexOf('lastSent') > -1
                    ,
                        phrase: 'filter_settings_hide_scheduled'
                        param: 'hideAllScheduled'
                        disabled: $scope.currentStep.sortBy.indexOf('lastScheduled') > -1
                ]

        ],
            top: $(e.target).offset().top + 27
            left: $(e.target).offset().left

    $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0

    $scope.goSection = (section) ->
        multiselect.flush()
        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep = angular.copy $scope.currentStep

        updateObjectFull $scope.currentStep, section
        if section.title?.length > 0
            delete $scope.currentStep.translateTitle
        $scope.currentStep.group = false

        $scope.stepStack.push $scope.currentStep

    $scope.stepBack = ->
        if $scope.stepStack.length > 1
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]

    $scope.triggerShared = ->
        multiselect.flush()
        if $scope.currentStep.type == 'shared'
            $scope.stepBack()
        else
            id = $scope.stepStack.indexOf($scope.currentStep)
            if id < $scope.stepStack.length - 1
                $scope.stepStack.splice id+1, $scope.stepStack.length - id

            # Go shared
            $scope.currentStep =
                translateTitle: 'generalApp_sharedWithMe'
                type: 'shared'
                itemType: 'comb'
                group: true
                query: {}
                sortBy: $scope.currentStep.sortBy
                filterTypes: $scope.currentStep.filterTypes

            $scope.stepStack.push $scope.currentStep

    # 
    # Buttons actions
    #

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
                combService.addContentIds item.id, [newText.id]

            $scope.progress.finish process

    $scope.newPost = ->
        items = multiselect.getFocused()

        if items.length > 0
            for item in items
                postService.create 
                    combId: item.id
                , (newPost) ->
                    buffer.addItem newPost
        else
            postService.create {}, (newPost) ->
                # buffer.addItem newPost
                desktopService.launchApp 'combEdit',
                    combId: newPost.combId

    $scope.showMoreMenu = (e) ->
        items = multiselect.getFocused()

        itemsActions = actionsService.getActions
            source: items

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
    # Get groups
    #

    $scope.queryFunction = (query, cb) ->
        operationsService.query $scope.currentStep.itemType, query, cb

    $scope.getGroups = (cb) ->
        groups = []

        if $scope.currentStep.sortBy == 'communities'

            result = []

            excludeCommunityIds = []

            groupService.get ->

                for id,group of groupService.storage
                    commIds = []
                    for feed in group.feeds
                        commIds.push feed.communityId
                        if feed.communityId in excludeCommunityIds
                            continue
                        excludeCommunityIds.push feed.communityId

                    groups.push
                        communityId: group.feeds[0].communityId
                        type: 'comb'
                        screens: 3
                        lines: 3
                        query:
                            entityType: 'comb'
                            communityId: #feed.communityId
                                '$in': commIds

                groups.unshift
                    translateTitle: 'combsApp_notUsedInCommunities'
                    type: 'comb'
                    screens: 3
                    lines: 3
                    query:
                        entityType: 'comb'
                        excludeCommunityIds: excludeCommunityIds

                cb? groups

        else if $scope.currentStep.type == 'shared'

            teamService.query
                member: account.user.id
            , (items) ->
                for item in items
                    groups.push 
                        # teamId: item.id
                        translateTitle: if !item.name?.length > 0 then 'generalApp_sharedWith_noNameTeam' else null
                        groupPic: item.cover
                        type: 'comb'
                        title: item.name
                        screens: 3
                        lines: 3
                        query:
                            entityType: 'comb'
                            teamId: item.id

                cb? groups

        else if $scope.currentStep.sortBy.indexOf('lastU') > -1 || $scope.currentStep.sortBy == 'created'
            # Today
            dateObj = new Date()
            startDay = new Date dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()
            startYear = new Date dateObj.getFullYear(), 0, 1
            date = dateObj.getDate()
            day = dateObj.getDay()
            day -= 1
            if day < 0 then day = 7

            startDayTS = startDay.getTime()
            groups.push
                translateTitle: 'group_by_today'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterGreater: startDayTS - 1

            groups.push
                translateTitle: 'group_by_yesterday'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startDayTS
                    filterGreater: startDayTS - DAY - 1

            groups.push
                translateTitle: 'group_by_currentWeek'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startDayTS - DAY
                    filterGreater: startDayTS - DAY * day - 1

            groups.push
                translateTitle: 'group_by_lastWeek'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startDayTS - DAY * day
                    filterGreater: startDayTS - DAY * (day + 7) - 1

            groups.push
                translateTitle: 'group_by_lastMonth'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startDayTS - DAY * (day + 7)
                    filterGreater: new Date dateObj.getFullYear(), dateObj.getMonth(), 1 #startDayTS - DAY * date - 1

            groups.push
                translateTitle: 'group_by_thisYear'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startDayTS - DAY * date
                    filterGreater: startYear.getTime() - 1

            groups.push
                translateTitle: 'group_by_laterThenEver'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterLower: startYear.getTime()
                    filterGreater: 1

            groups.push
                translateTitle: 'group_by_other'
                screens: 3
                lines: 3
                query: 
                    hideAllSent: $scope.currentStep.query.hideAllSent
                    hideAllScheduled: $scope.currentStep.query.hideAllScheduled
                    sortBy: $scope.currentStep.sortBy
                    sortType: $scope.currentStep.sortType or 'desc'
                    filterBy: $scope.currentStep.sortBy
                    filterEquals: 
                        $in: [null, 0]
        
            cb? groups

        groups

    # 
    # Save state
    #

    $scope.stateSaver.add 'stepStack', ->
        # Saver
        stack: $scope.stepStack
        current: $scope.stepStack.indexOf($scope.currentStep)
    , (data) ->
        $scope.stepStack.length = 0
        # Loader
        for step in data.stack
            $scope.stepStack.push step

        $scope.currentStep = $scope.stepStack[data.current*1]

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()

    #
    # Old code
    #
    return true


    # =============
    #  Filter View
    # =============

    # filterWidgets = () ->
    #     result = []

    #     exclude = null

    #     if $scope.queryParams.currentSort.indexOf('older') > -1
    #         exclude = 'folder'

    #     if $scope.queryParams.currentSort.indexOf('lastU') > -1 || $scope.queryParams.currentSort == 'created' || $scope.queryParams.currentSort in ['lastSent', 'lastScheduled', 'lastUpdated']
    #         # Today
    #         dateObj = new Date()
    #         startDay = new Date dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()
    #         startYear = new Date dateObj.getFullYear(), 1, 1
    #         date = dateObj.getDate()
    #         day = dateObj.getDay()
    #         day -= 1
    #         if day < 0 then day = 7

    #         startDayTS = startDay.getTime()
    #         result.push
    #             title: 'group_by_today'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterGreater: startDayTS - 1

    #         result.push
    #             title: 'group_by_yesterday'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startDayTS
    #                 filterGreater: startDayTS - DAY - 1

    #         result.push
    #             title: 'group_by_currentWeek'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startDayTS - DAY
    #                 filterGreater: startDayTS - DAY * day - 1

    #         result.push
    #             title: 'group_by_lastWeek'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startDayTS - DAY * day
    #                 filterGreater: startDayTS - DAY * (day + 7) - 1

    #         result.push
    #             title: 'group_by_lastMonth'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startDayTS - DAY * (day + 7)
    #                 filterGreater: startDayTS - DAY * date - 1

    #         result.push
    #             title: 'group_by_thisYear'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startDayTS - DAY * date
    #                 filterGreater: startYear.getTime() - 1

    #         result.push
    #             title: 'group_by_laterThenEver'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: startYear.getTime()
    #                 filterGreater: 1

    #         result.push
    #             title: 'group_by_other'
    #             screens: 3
    #             lines: 3
    #             query: 
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterEquals: 0
    #     else

    #         result.push
    #             title: 'group_by_noPosts'
    #             screens: 3
    #             lines: 3
    #             query:
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterEquals: 0

    #         result.push
    #             title: 'group_by_littlePosts'
    #             screens: 3
    #             lines: 3
    #             query:
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: 3
    #                 filterGreater: 0

    #         result.push
    #             title: 'group_by_morePosts'
    #             screens: 3
    #             lines: 3
    #             query:
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: 6
    #                 filterGreater: 2

    #         result.push
    #             title: 'group_by_muchPosts'
    #             screens: 3
    #             lines: 3
    #             query:
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterLower: 11
    #                 filterGreater: 5

    #         result.push
    #             title: 'group_by_veryMuchPosts'
    #             screens: 3
    #             lines: 3
    #             query:
    #                 entityType: 'comb'
    #                 exclude: exclude
    #                 filterBy: $scope.queryParams.currentSort
    #                 filterGreater: 10

    #     result

    # $scope.extraParams = [
    #         title: 'hide_scheduled'
    #         param: 'hideAllScheduled'
    #     ,
    #         title: 'hide_sent'
    #         param: 'hideAllSent'
    #     ,
    #         title: 'small_view'
    #         param: 'smallIcons'
    # ]

    # $scope.sections = [
    #         title: 'by_community'
    #         widgets: () ->
    #             result = []

    #             excludeCommunityIds = []

    #             for id,group of groupService.storage
    #                 for feed in group.feeds
    #                     excludeCommunityIds.push feed.communityId

    #                     result.push
    #                         communityId: feed.communityId
    #                         screens: 3
    #                         lines: 3
    #                         query:
    #                             entityType: 'comb'
    #                             communityId: feed.communityId

    #             result.unshift
    #                 title: 'group_by_other'
    #                 screens: 3
    #                 lines: 3
    #                 query:
    #                     entityType: 'comb'
    #                     excludeCommunityIds: excludeCommunityIds

    #             result

    #     ,
    #         title: 'by_sort'
    #         custom: true
    #         widgets: filterWidgets
    #     ,
    #         title: 'shared_by_teams'
    #         custom: true
    #         async: true
    #         widgets: (cb) ->
    #             result = []

    #             teamService.query
    #                 member: account.user.id
    #             , (items) ->
    #                 for item in items
    #                     result.push 
    #                         teamId: item.id
    #                         screens: 3
    #                         lines: 3
    #                         query:
    #                             entityType: 'comb'
    #                             teamId: item.id

    #                 cb? result

    #     ,
    #         title: 'all'
    #         query:
    #             entityType: 'comb'

    # ]

    # $scope.selectSection = (section) ->
    #     sectionId = $scope.sections.indexOf section
    #     $scope.currentSection = section
    #     saveFilter()
    #     true

    # $scope.queryItems = (query, cb) ->
    #     query.sortBy = $scope.queryParams.currentSort
    #     query.sortType = if $scope.queryParams.sortOrder then 'asc' else 'desc'
        
    #     query.hideAllScheduled = $scope.queryParams.hideAllScheduled
    #     query.hideAllSent = $scope.queryParams.hideAllSent

    #     combService.query query, (items, total) ->
    #         cb? items, total


    # $scope.state = state = combService.state

    # $rootScope.currentState = 'combs'

    # $scope.createComb = (e) ->
    #     target = $ e.target
    #     if target.hasClass('arrow')
    #         return false

    #     combService.create [], (comb) ->
    #         buffer.addItems [comb]

    # true
