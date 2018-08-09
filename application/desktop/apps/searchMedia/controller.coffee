buzzlike.controller 'searchMediaCtrl', ($rootScope, $scope, buffer, stateManager, localization, rpc, multiselect, importContentService, actionsService, complexMenu) ->

    $scope.session.zoom = 'mid' if !$scope.session.zoom?

    $scope.data =
        searchField: ""
    re_search = /(https?\:\/\/)|(www\.)|(\.ru)|(\.com)|(\.org)|(\.net)/
    video_re_search = /(youtube.com\/watch)|(vk.com\/video)/

    $scope.stateTree.applyState
        'escape': ->
            if $scope.stepStack.length > 1
                $scope.stepBack()
            else
                $scope.closeApp()
            true
        'enter': ->
            $scope.doAdd()

    #
    # Steps
    #

    $scope.stepStack = []

    $scope.currentStep =
        translateTitle: 'searchMediaApp_title'
        type: 'main'
        searchField: ''
        searchType:
            image: false
            video: false
            audio: false

        query: {}

    $scope.stepStack.push $scope.currentStep

    #
    # Step navigarion
    #

    $scope.goSection = (section) ->
        multiselect.flush()
        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep = angular.copy section # $scope.currentStep

        # updateObjectFull $scope.currentStep, section
        $scope.currentStep.group = false

        $scope.stepStack.push $scope.currentStep

    #
    # Go back
    #

    $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0
    $scope.stepBack = ->
        if $scope.stepStack.length > 0
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]

    #
    # Groups generator
    #

    $scope.getGroups = (cb) ->
        result = []

        switch $scope.currentStep.type
            when 'generalSearch'

                allOff = true
                for k,v of $scope.currentStep.searchType
                    if v == true
                        allOff = false
                        break

                videoOff = true
                for k,v of $scope.currentStep.videoType
                    if v == true
                        videoOff = false
                        break

                if allOff or $scope.currentStep.searchType.video

                    if videoOff or $scope.currentStep.videoType.vk

                        result.push
                            translateTitle: 'searchMediaApp_videoSearch_vk'
                            searchField: $scope.data.searchField
                            custom: true
                            group: false
                            query: 
                                provider: 'vkVideo'
                                sortBy: 'created'
                                sortType: 'desc'
                                query: $scope.data.searchField

                    if videoOff or $scope.currentStep.videoType.yt

                        result.push
                            translateTitle: 'searchMediaApp_videoSearch_yt'
                            searchField: $scope.data.searchField
                            custom: true
                            group: false
                            query: 
                                provider: 'youtubeVideo'
                                sortBy: 'created'
                                sortType: 'desc'
                                query: $scope.data.searchField

                if allOff or $scope.currentStep.searchType.audio

                    result.push
                        translateTitle: 'searchMediaApp_audioSearch_vk'
                        searchField: $scope.data.searchField
                        custom: true
                        group: false
                        query: 
                            provider: 'vkAudio'
                            sortBy: 'created'
                            sortType: 'desc'
                            query: $scope.data.searchField


        cb result
        result

    $scope.queryFunction = (query, cb) ->
        # lotService.query query, cb
        query.count = query.limit
        query.offset = 0
        if query.provider?
            process = $scope.progress.add()
            rpc.call 'import.query', query, (data) ->
                $scope.progress.finish process

                cb importContentService.handleItems data
        else
            cb []


    #
    # Search mechanics
    #

    $scope.keyDown = (e) ->
        if e.which == 13
            $scope.progress.flush()

            if $scope.stepStack.length > 1
                $scope.stepStack.splice 1, $scope.stepStack.length - 1

            parseQuery $scope.data.searchField

    $scope.showSources = ->
        if $scope.currentStep.custom == true
            return false

        if $scope.currentStep.type == 'main'
            return false

        if $scope.currentStep.searchType?.video == true
            return true

        for k,v of $scope.currentStep.searchType
            if v == true
                return false
        true


    $scope.submitSearch = ->
        $scope.progress.flush()

        if $scope.stepStack.length > 1
            $scope.stepStack.splice 1, $scope.stepStack.length - 1

        parseQuery $scope.data.searchField

    $scope.doSearch = ->
        $scope.progress.flush()

        if $scope.stepStack.length > 1
            $scope.stepStack.splice 1, $scope.stepStack.length - 1

        parseQuery $scope.data.searchField

    parseQuery = (string) ->
        # if $.trim(string) != ''

            urlsToSearch = string.replace(/<.+?>/g,' ')
            urlsToSearch = urlsToSearch.replace(/\s+/,' ')
            urlsToSearchArr = urlsToSearch.split(' ')
            urlsToSearch = ''

            for item in urlsToSearchArr
                if item?
                    item = $.trim(item)
                    if item != ''
                        urlsToSearch += item + ','

            if urlsToSearch != ''
                urlsToSearch = urlsToSearch.substr(0,urlsToSearch.length-1)

            # if urlsToSearch != ''

            # Если это ссылка, то отправляем запросы на другой url
            if video_re_search.test(urlsToSearch)
                urls = []
                for item in urlsToSearchArr
                    urls.push getUrlFormat $.trim item

                $scope.currentStep = 
                    translateTitle: 'searchMediaApp_videoSearch'
                    searchField: $scope.data.searchField
                    custom: true
                    group: false
                    query:
                        provider: 'videoUrl'
                        urls: urls

                $scope.stepStack.push $scope.currentStep

            else if re_search.test(urlsToSearch)
                urls = []
                for item in urlsToSearchArr
                    urls.push getUrlFormat $.trim item

                $scope.currentStep = 
                    translateTitle: 'searchMediaApp_addUrl'
                    searchField: $scope.data.searchField
                    custom: true
                    group: false
                    query:
                        provider: 'picUrl'
                        urls: urls
                $scope.stepStack.push $scope.currentStep
            else
                $scope.currentStep = 
                    title: localization.translate('searchMediaApp_searchRegular') + ' ' + urlsToSearch
                    searchField: $scope.data.searchField
                    group: true
                    type: 'generalSearch'
                    availableType:
                        video: true
                        audio: true
                    searchType:
                        video: false
                        audio: false
                    videoType:
                        vk: false
                        yt: false

                $scope.stepStack.push $scope.currentStep

    #
    # Actions
    #

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

    $scope.doAdd = ->
        items = multiselect.getFocused()

        for item in items
            importContentService.import item, (item) ->
                buffer.addItem item

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
        $scope.data.searchField = $scope.currentStep.searchField

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()
        $scope.data.searchField = $scope.currentStep.searchField


