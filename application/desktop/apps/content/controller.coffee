buzzlike.controller 'contentCtrl', ($scope, desktopService, complexMenu, uploadService, operationsService, contentService, multiselect, buffer, actionsService, localization, confirmBox, notificationCenter) ->  
    
    $scope.session.zoom = 'mid' if !$scope.session.zoom?
    $scope.helpFile = 'materials'

    $scope.stateTree.applyState
        'V cmd': (repeat, defaultAction) ->
            items = multiselect.getFocused()
            folders = []
            for item in items
                if item.type == 'folder'
                    folders.push item

            if folders.length > 0
                defaultAction folders
            else if $scope.currentStep.parent?
                folder = contentService.getById $scope.currentStep.parent
                defaultAction [folder]
            else
                defaultAction()

        'U cmd': (repeat, defaultAction) ->
            items = multiselect.getFocused()
            folders = []
            for item in items
                if item.type == 'folder'
                    folders.push item

            if folders.length > 0
                defaultAction folders
            else if $scope.currentStep.parent?
                folder = contentService.getById $scope.currentStep.parent
                defaultAction [folder]
            else
                defaultAction()

        'delete': ->
            items = multiselect.getFocused()

            ids = []
            ids.push item.id for item in items

            if items.length > 0
                confirmBox.init 
                    realText: localization.translate(32) + ' ' + items.length + ' ' + localization.declensionPhrase items.length, 'content_delete'
                    description: 'content_delete_description'
                , () ->

                    multiselect.flush()

                    if $scope.currentStep.parent?
                        contentService.removeContentIds $scope.currentStep.parent, ids

                    ids = []
                    ids.push item.id for item in items

                    buffer.removeItems items

                    contentService.deleteByIds ids, ->
                        notificationCenter.addMessage
                            text: 99

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
        translateTitle: 'contentApp_myContent'
        flow: true
        sortBy: 'created'
        itemType: 'content'
        notUsed: false
        filterTypes:
            image: false
            text: false
            url: false
            video: false
            audio: false
            poll: false
            file: false
        query: {}

    $scope.stepStack.push $scope.currentStep

    sortTypes = ['created', 'lastUpdated', 'lastUseInCombs', 'lastUseInSentPosts']

    $scope.showSortMenu = (e) ->
        complexMenu.show [
                object: $scope.currentStep
                type: 'select'
                param: 'sortBy'
                items: [
                        phrase: 'filter_catalog_sort_type'
                        value: 'type'
                    ,
                        phrase: 'filter_catalog_sort_created'
                        value: 'created'
                    ,
                        phrase: 'filter_catalog_sort_lastUpdated'
                        value: 'lastUpdated'
                    ,
                        phrase: 'filter_catalog_sort_lastUseInCombs'
                        value: 'lastUseInCombs'
                        disabled: $scope.currentStep.notUsed == true
                    ,
                        phrase: 'filter_catalog_sort_lastUseInSentPosts'
                        value: 'lastUseInSentPosts'
                        disabled: $scope.currentStep.notUsed == true
                ]
            ,
                object: $scope.currentStep.query
                type: 'checkbox'
                items: [
                        phrase: 'filter_settings_not_used'
                        param: 'notInCombs'
                        disabled: $scope.currentStep.sortBy.indexOf('lastUse') > -1
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
        $scope.currentStep.group = false

        $scope.stepStack.push $scope.currentStep

    $scope.stepBack = ->
        if $scope.stepStack.length > 1
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]

    $scope.itemClick = (item) ->
        if item.type != 'folder'
            return false

        multiselect.flush()

        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep =
            translateTitle: if item?.name?.length > 0 then null else 'contentApp_noNameFolder'
            title: item.name or null
            # type: 'folder'
            # folderId: item.id
            # sortBy: $scope.currentStep.sortBy
            # filterTypes: #angular.copy $scope.currentStep.filterTypes
            #     image: false
            #     text: false
            #     url: false
            #     video: false
            #     audio: false
            #     poll: false
            #     file: false
            flow: true
            sortBy: $scope.currentStep.sortBy
            itemType: 'content'
            parent: item.id
            filterTypes:
                image: false
                text: false
                url: false
                video: false
                audio: false
                poll: false
                file: false
            query: angular.copy $scope.currentStep.query

        $scope.stepStack.push $scope.currentStep
        true

    $scope.getDropable = ->
        if $scope.currentStep.parent?
            return contentService.getById $scope.currentStep.parent
        
        type: 'contentApp'

    $scope.queryFunction = (query, cb) ->
        operationsService.query $scope.currentStep.itemType, query, cb

    #
    # Buttons actions
    #

    $scope.upload = ->
        if $scope.currentStep.parent?
            uploadService.requestUpload 
                type: 'folder'
                id: $scope.currentStep.parent
        else
            uploadService.requestUpload()
        true

    $scope.newPoll = ->
        process = $scope.progress.add()
        contentService.create
            type: 'poll'
            value: ''
        , (newPoll) ->
            buffer.addItem newPoll
            desktopService.launchApp 'pollEdit',
                pollId: newPoll.id

            if $scope.currentStep.parent?
                contentService.addContentIds $scope.currentStep.parent, [newPoll.id], ->
                    $scope.progress.finish process
            else
                $scope.progress.finish process

    $scope.newText = ->
        process = $scope.progress.add()
        contentService.create
            type: 'text'
            value: ''
        , (newText) ->
            buffer.addItem newText
            desktopService.launchApp 'textEditor',
                textId: newText.id

            if $scope.currentStep.parent?
                contentService.addContentIds $scope.currentStep.parent, [newText.id], ->
                    $scope.progress.finish process
            else
                $scope.progress.finish process

    $scope.newFolder = ->
        items = multiselect.getFocused()
        ids = []
        ids.push item.id for item in items

        process = $scope.progress.add()
        contentService.create
            type: 'folder'
            items: ids
            parent: $scope.currentStep.parent or null
        , (newFolder) ->
            buffer.addItem newFolder
            $scope.progress.finish process

    $scope.showMoreMenu = (e) ->
        items = multiselect.getFocused()

        if items.length == 0
            itemsActions = actionsService.getActions
                source: if $scope.currentStep.parent? then [contentService.getById $scope.currentStep.parent] else null
        else
        
            itemsActions = actionsService.getActions
                context: if items.length > 0 and $scope.currentStep.parent? then contentService.getById $scope.currentStep.parent else null
                source: items
                target: if $scope.currentStep.parent? then contentService.getById $scope.currentStep.parent else null

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
    # Save state
    #

    $scope.stateSaver.add 'stepStack', ->
        # Saver
        stack: $scope.stepStack
        current: $scope.stepStack.indexOf($scope.currentStep)
    , (data) ->
        delete $scope.session.folderId if $scope.session.folderId?

        $scope.stepStack.length = 0
        # Loader
        for step in data.stack
            $scope.stepStack.push step

        $scope.currentStep = $scope.stepStack[data.current*1]

    # $scope.$watch 'stepStack', (nVal) ->
    #     $scope.stateSaver.save()
    # , true

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()


    if $scope.session.folderId?

        process = $scope.progress.add()
        contentService.getById $scope.session.folderId, (item) ->
            $scope.progress.finish process
            $scope.currentStep =
                translateTitle: if item?.name?.length > 0 then null else 'contentApp_noNameFolder'
                title: item.name or null
                
                parent: $scope.session.folderId
                itemType: 'content'
                flow: true
                sortBy: 'created'
                filterTypes:
                    image: false
                    text: false
                    url: false
                    video: false
                    audio: false
                    poll: false
                    file: false
                query: angular.copy $scope.currentStep.query


            $scope.stepStack.push $scope.currentStep

    true