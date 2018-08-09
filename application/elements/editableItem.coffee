buzzlike.directive "editableItem", ($parse, desktopService, account, lotService, smartDate, communityService, multiselect, $rootScope, operationsService, contentService, combService, postService) ->
    restrict: "C"
    link: (scope, element, attrs) ->
        elem = $ element

        # elem.off '.editableItem'

        scope.editAction = editAction = (displayElem, e) ->
            if scope.id?
                type = attrs.type || 'content'
                item = operationsService.get type, scope.id
            else if attrs.id?
                id = $parse(attrs.id)(scope)
                type = attrs.type || 'content'
                item = operationsService.get type, id
            else if scope.item?
                item = scope.item

            switch item.type
                when 'importContent'
                    switch item.contentType
                        when 'image', 'video'
                            desktopService.launchApp 'mediaPreview',
                                contentType: 'importContent'
                                contentId: item.id
                                center: true

                when 'url'
                    window.open(item.value,'_blank')

                # when 'file'
                #     window.location = item.source

                when 'image', 'video', 'file'
                    desktopService.launchApp 'mediaPreview',
                        contentId: item.id
                        center: true

                when 'poll'
                    desktopService.launchApp 'pollEdit',
                        pollId: item.id
                        center: true

                when 'text'
                    #offsets = elem.offset()
                    offsets = {}

                    w = displayElem.width()
                    if w > 300 then offsets.width = w else offsets.width = 0
                    updateObject offsets, displayElem.offset()

                    desktopService.launchApp 'textEditor',
                        textId: item.id
                        coords:
                            x: offsets.left
                            y: offsets.top
                    break;
                when 'importAlbum'
                    if scope.itemClick?(item) == true
                        return

                when 'folder'
                    if scope.itemClick?(item) == true
                        return

                    multiselect.flush()
                    multiselect.state.context = null

                    #console.log contentService.getById item.id
                    # if elem.parents('#rightPanel').length > 0
                    #     selectionService.openContext item

                    desktopService.launchApp 'content',
                        folderId: item.id

                when 'team'
                    # if elem.parents('#rightPanel').length > 0
                    #     selectionService.openContext item
                    desktopService.launchApp 'teamManager',
                        teamId: item.id

                when 'task'
                    desktopService.launchApp 'teamManager',
                        teamId: item.taskId
                        taskId: item.id

                when 'comb'
                    desktopService.launchApp 'combEdit',
                        combId: item.id

                when 'post'
                    if item.onSale == true
                        lotService.query
                            postId: item.id
                        , (items) ->
                            lot = items[0]
                            desktopService.launchApp 'lotManager',
                                lotId: lot.id

                    else
                        combService.fetchById item.combId, (comb) ->
                            desktopService.launchApp 'combEdit',
                                combId: comb.id
                                postId: item.id

                when 'schedule'
                    post = postService.getById item.postId
                    if item.lotId?

                        # lotService.query
                        #     postId: item.id
                        # , (items) ->
                        #     lot = items[0]
                            # if lot.userId != account.user.id
                        desktopService.launchApp 'lotManager',
                            lotId: item.lotId

                        # desktopService.launchApp 'lotPreview',
                        #     lotId: item.lotId
                    else
                        comb = combService.getById post.combId
                        desktopService.launchApp 'combEdit',
                            combId: comb.id
                            postId: post.id

                when 'lot'
                    desktopService.launchApp 'lotPreview',
                        lotId: item.id

                when 'placeholder'

                    groupId = scope.$parent.$parent.group.id
                    lineId = scope.$parent.cId
                    
                    feedInterval = $(element).parents('.feedInterval')
                    intervalScope = angular.element(feedInterval[0]).scope()

                    #lineId = scope.item.rule.communityId
                    community = communityService.getById lineId

                    multiselect.flush()

                    desktopService.launchApp 'postPicker',
                        communityId: lineId
                        timestamp: scope.item.timestamp #smartDate.getShiftTimeBar(scope.item.timestamp)
                        socialNetwork: community.socialNetwork
                        placeholder: false
                    , e

        elem.on "dblclick.editableItem", (e) ->
            target = $ e.target

            if ( target.parents('.itemPreview').length > 0 or target.hasClass('itemPreview') ) and !$(e.target).hasClass('contentComment')

                e.stopPropagation()

                editAction $(this), e

                scope.$apply()


