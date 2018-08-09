buzzlike.controller 'addFeedCtrl', ($rootScope, rpc, complexMenu, $scope, account, communityService, groupService, notificationCenter, multiselect) ->

    $scope.currentStep =
        translateTitle: 'addFeedApp_myAccounts'

    $scope.stepStack = []
    $scope.stepStack.push $scope.currentStep

    $scope.isMailRu = false

    onEscape = $scope.onEscape = () ->
        $scope.closeApp()
        true

    addFeedState =
        'escape': ->
            $scope.closeApp()
        'enter': () ->
            $scope.doAdd()

    $scope.stateTree.applyState addFeedState

    $scope.searchcomm = ''
    $scope.options = []
    $scope.accountFirst = true
    $scope.selectedAcc = null

    $scope.multiselectState = multiselect.state

    $scope.filter =
        # my: false
        admin: false
        editor: false
        sorting: 'size'


    # Account list ================
    $scope.user = account.user
    userProcess = $scope.progress.add()
    account.update ->
        $scope.selectAccount $scope.currentAccNumber
        $scope.progress.finish userProcess

    #$scope.accounts = account.user.accounts
    $scope.currentAccNumber = 0
    $scope.selectAccount = (acc) -> # number
        $scope.currentAccNumber = acc

        $scope.isMailRu = $scope.user.accounts[$scope.currentAccNumber].socialNetwork == 'mm'

        if $scope.stepStack.length > 1
            $scope.stepStack.pop()
        $scope.currentStep =
            title: $scope.user.accounts[$scope.currentAccNumber].name
            id: acc
        $scope.stepStack.push $scope.currentStep
        true
    $scope.currentAccount = -> $scope.user.accounts[$scope.currentAccNumber]


    $scope.commFilter = (communityId) ->
        show = false

        level = $scope.currentAccount().writableCommunitiesMap[communityId]

        # if scope.filter.my
        #     if !community.my then return false

        if $scope.filter.admin
            if level == 'admin' then show = true

        if $scope.filter.editor
            if level == 'editor' then show = true

        if !$scope.filter.admin and !$scope.filter.editor and !$scope.filter.my
            show = true

        if show == true and $scope.searchcomm != ""
            commItem = communityService.getById communityId
            if commItem.name?.toLowerCase().indexOf($scope.searchcomm.toLowerCase()) == -1
                show = false

        show

    $scope.commSort = (communityId) ->
        commItem = communityService.getById communityId
        if commItem.blank?
            return 0

        if $scope.filter.sorting == 'title'
            # Страница пользователя должна выводиться на первом месте
            if commItem.socialNetworkId*1 == $scope.currentAccount().publicId*1
                return 'a'
            else
                return commItem.name
        else
            # Страница пользователя должна выводиться на первом месте
            if commItem.socialNetworkId*1 == $scope.currentAccount().publicId*1
                return -90000000
            else
                return -commItem.membersCount

    $scope.updating = false
    class spinner
        target = null
        @spinner = makeSpinner()
        @spin: =>
            target = $(".ruberRight .spinner")[0]
            @spinner.spin target
        @stop: => @spinner.stop()

    $scope.update = () ->
        if $scope.updating then return true

        spinner.spin()
        $scope.updating = true
        acc = $scope.currentAccNumber
        # $scope.selectAccount $scope.currentAccNumber
        process = $scope.progress.add()
        communityService.loadCommunities ->
            # $scope.selectAccount acc
            $scope.updating = false
            spinner.stop()
            $scope.$apply()
            $scope.progress.finish process

        true

    $scope.doAdd = () ->
        focused = multiselect.getFocused()

        if focused.length > 0
            if $scope.session.api?.onAdd?
                $scope.session.api?.onAdd? focused
                $scope.closeApp()
            else
                process = $scope.progress.add()
                
                newGroup =
                    type: 'group'
                    name: 'new_group'
                    feeds: []

                for community in focused
                    newGroup.feeds.push
                        status: 'Writable'
                        communityId: community.id
                        statusAsInt: 1

                groupService.create newGroup, ->
                    $scope.progress.finish process

                    if $scope.session.closeOnAdd == true
                        $scope.closeApp()

        else
            notificationCenter.addMessage
                text: 'importcomm_choosecomm'
                error: true


    $scope.showSortMenu = (e) ->
        complexMenu.show [
                object: $scope.filter
                type: 'select'
                param: 'sorting'
                items: [
                        phrase: 'addFeedApp_filter_size'
                        value: 'size'
                    ,
                        phrase: 'addFeedApp_filter_title'
                        value: 'title'
                ]
            ,
                object: $scope.filter
                type: 'checkbox'
                items: [
                        phrase: 'addFeedApp_filter_admin'
                        param: 'admin'
                    ,
                        phrase: 'addFeedApp_filter_editor'
                        param: 'editor'
                ]

        ],
            top: $(e.target).offset().top + 27
            left: $(e.target).offset().left

    $scope.stateSaver.add 'stepStack', ->
        stack: $scope.stepStack
        current: $scope.stepStack.indexOf($scope.currentStep)
    , (data) ->
        $scope.stepStack.length = 0

        for step in data.stack
            $scope.stepStack.push step

        $scope.currentStep = $scope.stepStack[data.current*1]
        $scope.selectAccount $scope.currentStep.id

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()


    $scope.mailRyKeyDown = (e) ->
        if e.which == 13
            e.stopPropagation()
            e.preventDefault()
            $scope.addMailRuComm $scope.searchMailRuComm

    $scope.addMailRuComm = (link) ->
        if !link?
            return

        link = link.trim()
        if link[ link.length - 1 ] == '/'
            link = link.substring(0, link.length - 1)

        rpc.call 'mm.parseUrlCommunity',
            url: link
            publicId: $scope.user.accounts[$scope.currentAccNumber].publicId
        , (result) ->
            account.update()
