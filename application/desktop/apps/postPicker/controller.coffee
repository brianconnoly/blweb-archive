buzzlike.controller 'postPickerCtrl', (inspectorService, ruleService, scheduleService, communityService, account, $scope, combService, favouriteService, lotService, postService, httpWrapped, env, stateManager) ->
    $scope.session.expandedHeader = false

    $scope.state = $scope.session
    $scope.posts = postService.storage

    if $scope.session.combId?
        $scope.comb = combService.getById $scope.session.comb

    if $scope.session.communityId?
        $scope.community = communityService.getById $scope.session.communityId

    postService.fetchMy()

    stateManager.applyState
        escape: $scope.closeApp

    # $scope.$on '$destroy', stateManager.goBack

    $scope.onEscape = $scope.closeApp

    $scope.favourites = favouriteService.storage

    $scope.placeholder =
        type: 'mediaplan'

    $scope.newpost =
        type: 'new'

    $scope.newcomb =
        type: 'comb'

    # $scope.$watch () ->
    #     favouriteService.list
    # , (nVal) ->
    #     if nVal? and nVal.length > 0
    #         $scope.favouritesBuild = []
    #         for id in $scope.favourites
    #             lotService.fetchLotById id, (lot) ->
    #                 if lot.lotType=='post' or lot.lotType=='repost'
    #                     if !$scope.favouritesBuild.indexOf(lot.id)+1
    #                         $scope.favouritesBuild.push lot.id
    # , true

    $scope.unFavourite = (id, e) ->
        e.stopPropagation()
        e.preventDefault()

        favouriteService.delete
            id: id
            type: 'favourite'

    $scope.pick = (choice, type, e) ->
        if type == 'lot'
            lot = lotService.storage[choice]
            if !lot?
                return false
            $scope.makeChoice lot, e # postService.getById lot.postId
        else if type == 'post'
            $scope.makeChoice postService.getById(choice), e #lot.postId
        else
            if choice?
                $scope.makeChoice choice, e
        true

    $scope.pickerFilter = (post) ->
        if post.scheduled == true or post.onSale == true or post.userId != account.user.id
            return false

        if $scope.comb?.id?
            return post.id in $scope.comb.postIds
        true

    $scope.makeChoice = (result, e) ->
        switch result.type
            when 'mediaplan'
                item =
                    type: 'rule'
                    ruleType: 'single'
                    timestampStart: $scope.session.timestamp
                    timestampEnd: $scope.session.timestamp + DAY
                    ad: false
                    interval: 30
                    dayMask: [true,true,true,true,true,true,true]
                    communityId: $scope.session.communityId
                    groupId: $scope.session.groupId || null
                    end: true

                ruleService.create item, (created) ->
                    inspectorService.initInspector ruleService.getPlaceholder(0, created.id, $scope.session.communityId), e
                    true

                break

            when 'new'
                scheduleService.create
                    communityId: $scope.session.communityId
                    scheduleType: 'post'
                    timestamp: $scope.session.timestamp
                    combId: $scope.session.combId

                break

            when 'post'
                if result.onSale

                    # Перетаскиваем рекламный пост
                    desktopService.launchApp 'requestMaster',
                        lotId: result.lotId
                        timestamp: $scope.session.timestamp
                        communityId: $scope.session.communityId

                else

                    scheduleService.create
                        communityId: $scope.session.communityId
                        scheduleType: 'post'
                        timestamp: $scope.session.timestamp
                        postId: result.id

                break

            when 'lot'

                desktopService.launchApp 'requestMaster',
                    lotId: result.id
                    timestamp: $scope.session.timestamp
                    communityId: $scope.session.communityId

                break

            when 'comb'

                scheduleService.create
                    communityId: $scope.session.communityId
                    scheduleType: 'post'
                    timestamp: $scope.session.timestamp
                    combId: $scope.session.combId
                    groupId: $scope.session.groupId

                break

        $scope.closeApp()
        true

