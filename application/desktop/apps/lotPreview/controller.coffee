buzzlike.controller 'lotPreviewCtrl', (userService, buffer, desktopService, localization, smartDate, resize, $scope, stateManager, favouriteService, communityService, scheduleService, lotService, postService, contentService) ->
    
    $scope.session.expandedHeader = false

    $scope.stateTree.applyState
        'escape': $scope.closeApp

    # Globals
    $scope.bigItem = null
    $scope.contentIds = []

    $scope.community = null
    $scope.owner = null

    # Fetch lot
    process = $scope.progress.add()
    $scope.lot = lot = lotService.getById $scope.session.lotId, (item) ->
        $scope.progress.finish process

        # Fetch post
        process = $scope.progress.add()
        postService.getById item.postId, (postItem) ->
            $scope.progress.finish process

            $scope.bigItem = null
            $scope.contentIds.length = 0

            for k,v of postItem.contentIds
                for id in v
                    if k == 'image' and $scope.bigItem == null
                        $scope.bigItem = id
                    else
                        $scope.contentIds.push id

            if $scope.bigItem == null
                $scope.bigItem = $scope.contentIds.pop()

        if item.lotType == 'repost'
            schedProcess = $scope.progress.add()
            scheduleService.getOriginalByPostId item.postId, (schedItem) ->
                $scope.progress.finish schedProcess

                commProcess = $scope.progress.add()
                communityService.getById schedItem.communityId, (communityItem) ->
                    $scope.progress.finish commProcess
                    $scope.community = communityItem

        userProcess = $scope.progress.add()
        userService.getById item.userId, (userItem) ->
            $scope.progress.finish userProcess
            $scope.owner = userItem


    #
    # Lot price string generator
    #

    $scope.getLotPrice = (action = 'lotPreviewApp_for') ->
        if $scope.lot.price == 0
            return localization.translate('marketApp_lotPrice_free').toLowerCase()
            
        priceString = localization.translate(action) + ' ' + $scope.lot.price + ' '
        if $scope.lot.buzzLot
            priceString += localization.declensionPhrase $scope.lot.price, 'costDays'
        else
            priceString += localization.declensionPhrase $scope.lot.price, 'roubles'
        priceString

    $scope.getLotCustomers = ->
        if $scope.lot.boughtCounter == 0
            return localization.translate('lotPreviewApp_bought_none').toLowerCase()
        $scope.lot.boughtCounter + ' ' + localization.declensionPhrase $scope.lot.boughtCounter, 'usersDeclension'

    $scope.takeToRight = ->
        if $scope.lot.type == 'repost'
            buffer.addItem $scope.lot

        if $scope.lot.lotType == 'post'
            process = $scope.progress.add()
            lotService.call 'buy', $scope.lot.id, (bought) ->
                $scope.progress.finish process
                buffer.addItem bought

    $scope.goOwnerPage = ->
        # find vk
        for acc in $scope.owner.accounts
            if acc.socialNetwork == 'vk'
                openCommunityPage
                    communityType: 'profile'
                    socialNetwork: acc.socialNetwork
                    socialNetworkId: acc.publicId
                return

        acc = $scope.owner.accounts[0]
        openCommunityPage
            communityType: 'profile'
            socialNetwork: acc.socialNetwork
            socialNetworkId: acc.publicId
    true