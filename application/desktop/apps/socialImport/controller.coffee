buzzlike.controller 'socialImportCtrl', (complexMenu, groupService,  account, actionsService, importAlbumService, importContentService, contentService, $scope, communityService, buffer, localization, multiselect) ->

    $scope.widthShrinker = 182
    $scope.session.zoom = 'mid' if !$scope.session.zoom?

    $scope.multiselectState = multiselect.state
    $scope.user = account.user

    #
    # State
    #
    
    onEscape = $scope.onEscape = () ->
        $scope.closeApp()
        true

    $scope.stateTree.applyState
        'enter': ->
            $scope.import()
        'escape': () ->
            if $scope.stepStack.length > 1
                $scope.stepBack()
            else
                $scope.closeApp()
            true

    #
    # Steps mechanics
    #

    $scope.currentStep = null
    $scope.stepStack = []

    $scope.goSection = (section) ->
        multiselect.flush()
        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep = angular.copy section #$scope.currentStep

        # updateObjectFull $scope.currentStep, section
        $scope.currentStep.group = false

        $scope.stepStack.push $scope.currentStep

    $scope.itemClick = (item) ->
        if item.type != 'importAlbum'
            return false

        multiselect.flush()

        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep =
            translateTitle: if item?.title?.length > 0 then null else 'socialImportApp_noNameAlbum'
            title: item.title or null
            albumId: item.id
            query: 
                albumId: item.id
                albumType: item.albumType
                sn: item.socialNetwork
                snOwnerId: item.snOwnerId
                id: item.albumId
                communityId: item.communityId

        $scope.stepStack.push $scope.currentStep
        true

    $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0
    $scope.stepBack = ->
        if $scope.stepStack.length > 1
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]

    # 
    # Account and community selection
    #

    $scope.currentAccount = null
    $scope.currentCommunity = null

    $scope.pickCommunity = (item, acc) ->
        $scope.currentCommunity = item
        $scope.currentAccount = acc if acc?

        $scope.stepStack.length = 0
        $scope.currentStep = 
            group: true
            communityId: item.id
            title: item.name
            sn: item.socialNetwork

        $scope.stepStack.push $scope.currentStep

        true

    #
    # Filter communities
    #


    #
    # Import settings
    # Getting allowed for import communities list
    #

    if account.user.settings.importOnlyFromMyComm
        $scope.mediaplans = []
        groupService.get (list) ->
            for group in list
                for feed in group.feeds
                    community = communityService.getById feed.communityId
                    $scope.mediaplans.push community if community not in $scope.mediaplans

        # Add SN profiles
        for acc in account.user.accounts
            communityService.getByPublicId  
                snType: acc.socialNetwork
                snId:   acc.publicId
            , (community) ->
                $scope.mediaplans.push community if community not in $scope.mediaplans
    else
        feeds = []
        for acc in account.user.accounts
            feeds = feeds.concat acc.writableCommunities

        communityService.getByIds feeds, (list) ->
            $scope.mediaplans = list

    #
    # Ordering
    #

    $scope.orderCommunity = (community) ->
        if  community.communityType == 'profile' #$.inArray(community.socialNetworkId, $scope.selectedAccountIds) != -1
            return -90000000
        else
            return -community.membersCount

    $scope.formatName = (type) ->
        type[0].toUpperCase() + type.substr(1) + 's'

    #
    # Groups for grouped view
    #

    $scope.queryFunction = (query, cb) ->
        if query.albumId?
            importContentService.query query, cb
        else
            importAlbumService.query query, cb

    $scope.getGroups = (cb) ->
        result = []

        types = ['image','video','audio']

        for type in types
            if $scope.currentStep.sn in ['ok','fb'] and type in ['video','audio']
                continue
            if $scope.currentStep.sn == 'yt' and type in ['image','audio']
                continue

            result.push
                translateTitle: 'socialImportApp_' + type + 's'
                screens: 3
                lines: 3
                query: 
                    type: type
                    communityId: $scope.currentStep.communityId
                    sn: $scope.currentStep.sn

        cb? result
        result

    #
    # Actions
    #

    $scope.import = ->
        items = multiselect.getFocused()

        albums = []
        content = []

        for item in items
            if item.type == 'importAlbum'
                albums.push item
            else if item.type == 'importContent'
                content.push item

        if albums.length > 0
            # Importing albums
            for album in albums
                importAlbumService.import album, (folder) ->
                    buffer.addItem folder

        if content.length > 0
            # Importing content
            for item in content
                importContentService.import item, (contentItem) ->
                    buffer.addItem contentItem

    $scope.update = ->
        $scope.currentStep.ts = Date.now()
        true

    $scope.showMoreMenu = (e) ->
        items = multiselect.getFocused()
        if items.length == 0
            return

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
    # Saving state
    #

    $scope.stateSaver.add 'stepStack', ->
        # Saver
        stack: $scope.stepStack
        current: $scope.stepStack.indexOf $scope.currentStep
        communityId: $scope.currentCommunity?.id
        accountId: $scope.user.accounts.indexOf $scope.currentAccount
    , (data) ->
        $scope.stepStack.length = 0
        # Loader
        for step in data.stack
            $scope.stepStack.push step

        $scope.currentStep = $scope.stepStack[data.current*1]
        $scope.currentCommunity = communityService.getById data.communityId if data.communityId? 
        $scope.currentAccount = $scope.user.accounts[data.accountId]

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()

    
buzzlike.filter 'grabContent_FIX', () ->
    (items, scope) ->
        arr = makeArray items

        arr.filter (element, index, array) ->
            if scope.currentAccount?.publicId == scope.account.publicId
                return element.id in scope.account.writableCommunities
            else
                return element.communityType == 'profile' and element.id in scope.account.writableCommunities

buzzlike.directive 'selectFirst', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        if scope.currentCommunity == null and scope.$first and scope.$parent.$first
            scope.pickCommunity scope.item, scope.account

buzzlike.directive 'focusSearchOnLoad', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        setTimeout ->
            $(element).focus()
        , 1

