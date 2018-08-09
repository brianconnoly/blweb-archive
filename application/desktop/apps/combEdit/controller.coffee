buzzlike.controller 'combEditCtrl', ($filter, desktopService, uploadService, resize, confirmBox, contextMenu, contentService, localization, $scope, multiselect, combService, postService, scheduleService, dragMaster, operationsService, complexMenu, actionsService) ->

    $scope.session.zoom = 'mid' if !$scope.session.zoom?

    $scope.stateTree.applyState
        'V cmd': (repeat, defaultAction) ->
            defaultAction [$scope.comb]
            $scope.paginatorParams.currentPage = $scope.shortcuts['text'] if $scope.shortcuts['text']?

        'U cmd': (repeat, defaultAction) ->
            defaultAction [$scope.comb]

        'delete': () ->
            focused = $(".combEdit .selected")

            content = []
            contentIds = []
            posts = []
            postIds = []
            contentInPost = []

            postItems = {}

            for elem in focused
                scope = angular.element(elem).scope()
                if scope.id? and scope.type?
                    item = operationsService.get scope.type, scope.id
                else
                    item = scope.item
                elem = $ elem

                ctx = elem.parents(".multiselect")[0]
                ctx = $ ctx

                #blog item, ctx

                if item.type == 'post'
                    posts.push item
                    postIds.push item.id
                else
                    if ctx.hasClass 'postContent'
                        postId = angular.element(ctx).scope().post.id

                        postItems[postId] = [] if !postItems[postId]?
                        postItems[postId].push item.id
                        contentInPost.push item

                    else if ctx.hasClass 'rightContent'
                        content.push item
                        contentIds.push item.id

            #blog content, posts, contentInPost

            flow =
                counter: 0
                chain: []
                next: () ->
                    flow.chain[flow.counter++]?.apply this, arguments

            if content.length
                flow.chain.push ->
                    string = content.length + ' ' + localization.declension content.length, 'declension_element'
                    title = localization.translate('comb_removeFromComb').replace "%s", string

                    confirmBox.init 
                        phrase: title
                        description: 'optionsList_comb_delete_description'
                    , () ->
                        combService.removeContentIds $scope.comb, contentIds, () ->
                            updateContentView()

                            flow.next()
                    , flow.next

            if posts.length
                flow.chain.push ->
                    string = posts.length + ' ' + localization.declension posts.length, 'declension_post'
                    title = localization.translate('comb_remove').replace "%s", string
                    confirmBox.init title, () ->
                        postService.deleteByIds postIds, (result) ->
                            flow.next()
                    , flow.next
                    true

            if contentInPost.length
                flow.chain.push ->
                    string = contentInPost.length + ' ' + localization.declension contentInPost.length, 'declension_element'
                    title = localization.translate('comb_removeFromPost').replace "%s", string
                    confirmBox.init title, () ->
                        for postId,items of postItems
                            postService.removeContentIds postId, items

                        flow.next()
                    , flow.next
                    true

            multiselect.flush()
            flow.next()


            true

    $scope.$watch 'session.zoom', (nVal) ->
        updateContentView()

    $scope.shortcuts = {}

    $scope.filterSettings = 
        sortBy: 'order'
        hideAllSent: false
        hideAllScheduled: false
        invert: false

    #
    # Open single post
    #

    $scope.id = $scope.session.postId
    $scope.backToAllPosts = ->
        $scope.id = null
        
    #
    # Posts scroller
    #

    $scope.postsScroller =
        total: $scope.allPosts?.length
        perPage: 0
        itemVar: 'id'
        template: '<post-editor></post-editor>'
        watchObject: 'allPosts'
        heightOffset: 80
        getPage: (page, cb) ->
            if $scope.allPosts?
                cb? $scope.allPosts.slice page * $scope.postsScroller.perPage, (page + 1) * $scope.postsScroller.perPage
            else
                cb? []

    updatePostScroller = ->
        $scope.postsScroller.total = $scope.allPosts.length
        # $scope.contentScroller.total = $scope.allContent.length

    #
    # Content scroller
    #

    $scope.contentScroller = 
        total: $scope.allContent?.length
        perPage: 0
        itemVar: 'id'
        template: '<li class="contextMenu previewContainer selectableItem editableItem droppableItem" context="comb" type="content" ng-dblclick="contentClick(item, $event)">' +
                    '<div class="itemPreview" ng-dblclick="contentClick(id, $event)" type="content" id="id"></div>' + '</li>'
        watchObject: 'allContent'
        heightOffset: 80
        getPage: (page, cb) ->
            if $scope.allContent?.length > 0
                cb? $scope.allContent.slice page * $scope.contentScroller.perPage * screen.perLine, (page + 1) * $scope.contentScroller.perPage * screen.perLine
            else
                cb? []

    #
    # Super paginator stuff
    #

    screen = 
        wid: 5
        hei: 1
        cont_hei: 1
        cont_wid: 1
        cont_wid_mini: 2
        perLine: 1

    $scope.pageSize = screen.wid * screen.hei

    $scope.paginatorParams = 
        currentPage: 0
        contentTypes: []
            
    $scope.postWidth = 'auto'

    updateContentView = () ->
        if !$scope.comb?
            return

        switch $scope.session.zoom
            when 'min'
                $scope.contentScroller.minHeight = 74
                itemWidth = 90
                itemHeight = 74
            when 'mid'
                $scope.contentScroller.minHeight = 123
                itemWidth = 159
                itemHeight = 123
            when 'max'
                $scope.contentScroller.minHeight = 161
                itemWidth = 197
                itemHeight = 161

        teamPanel = if $scope.comb.teamId? then 99 else 0
        postsLine = ($scope.session.size.width - 390 - teamPanel) / itemWidth | 0
        postsCol = ($scope.session.size.height - 120)/ itemHeight | 0

        screen.perLine = postsLine

        totalItems = $scope.allContent.length

        $scope.contentScroller.total = Math.ceil(totalItems / postsLine)
        $scope.contentScroller.rebuildPages?()

    # 
    # Comb load stuff
    #

    $scope.allContent = []
    $scope.allPosts = []

    sortContent = ->
        if !$scope.comb?
            return
            
        $scope.allContent.length = 0
        for k,v of comb.contentIds
            for id in v by -1
                $scope.allContent.push id

    sortPosts = ->
        if !$scope.comb?
            return

        $scope.allPosts.length = 0

        list = $filter('filter')(comb.postIds, $scope.postFilter)
        list = $filter('orderBy')(list, $scope.postOrder)

        orderBy = if $scope.filterSettings.invert == true then 1 else -1
        
        for id in list by orderBy #-1
            $scope.allPosts.push id

    process = $scope.progress.add()
    $scope.comb = comb = combService.getById $scope.session.combId, (item) ->
        $scope.progress.finish process
        $scope.comb = comb = item

        sortContent()
        sortPosts()

        updateContentView()

        updatePostScroller()

    $scope.$watch 'comb.contentIds', (nVal) ->
        if nVal?
            sortContent()
            updateContentView()
    , true

    $scope.$watch 'comb.postIds', (nVal) ->
        if nVal?
            sortPosts()
            updatePostScroller()
    , true

    $scope.$watch 'comb.teamId', (nVal) ->
        updateContentView()

    $scope.onResize (wid, hei) ->
        updateContentView()
        $scope.contentScroller.rebuildPages?()
        $scope.postsScroller.rebuildPages?()
    #
    # Sorting and filtering stuff
    #

    $scope.postOrder = (id) ->
        post = postService.getById id

        if post.scheduled == true
            sched = scheduleService.getOriginalByPostId id

        switch $scope.filterSettings.sortBy
            when 'created', 'lastUpdated'
                return post[$scope.filterSettings.sortBy]
            when 'planned'
                return sched?.created or 0
            when 'sended'
                return sched?.timestamp or 0
            when 'order'
                return $scope.comb.postIds.indexOf id

    $scope.postFilter = (id) ->
        post = postService.getById id
        if post.deleted == true
            return false

        if post.scheduled == true
            sched = scheduleService.getOriginalByPostId id
        else
            return true

        if $scope.filterSettings.hideAllSent
            return sched.status == 'planned'

        if $scope.filterSettings.hideAllScheduled
            return !post.scheduled

        true


    $scope.showSortMenu = (e) ->
        complexMenu.show [
                object: $scope.filterSettings
                type: 'select'
                param: 'sortBy'
                selectFunction: ->
                    sortPosts()
                items: [
                        phrase: 'filter_catalog_sort_order'
                        value: 'order'
                    ,
                        phrase: 'filter_catalog_sort_created'
                        value: 'created'
                    ,
                        phrase: 'filter_catalog_sort_lastUpdated'
                        value: 'lastUpdated'
                    ,
                        phrase: 'filter_catalog_sort_planned'
                        value: 'planned'
                    ,
                        phrase: 'filter_catalog_sort_sended'
                        value: 'sended'
                ]
            ,
                object: $scope.filterSettings
                type: 'checkbox'
                selectFunction: ->
                    sortPosts()
                items: [
                        phrase: 'filter_settings_hide_sent'
                        param: 'hideAllSent'
                    ,
                        phrase: 'filter_settings_hide_scheduled'
                        param: 'hideAllScheduled'
                    ,
                        phrase: 'filter_settings_invert'
                        param: 'invert'
                ]

        ],
            top: $(e.target).offset().top + 27
            left: $(e.target).offset().left

    #
    # Actions
    #

    $scope.multiselectState = multiselect.state
    $scope.addToEachPost = ->
        items = multiselect.getFocused()
        ids = []
        ids.push item.id for item in items

        process = $scope.progress.add()
        combService.addToEveryPost 
            combId: $scope.comb.id
            ids: ids
        , ->
            $scope.progress.finish process

    $scope.newPost = ->
        items = multiselect.getFocused()
        ids = []
        ids.push item.id for item in items

        process = $scope.progress.add()
        postService.create
            combId: $scope.comb.id
            items: ids
        , ->
            $scope.progress.finish process

    $scope.newText = ->
        process = $scope.progress.add()
        contentService.create
            type: 'text'
        , (textItem) ->
            combService.addContentIds $scope.comb.id, [textItem.id], ->
                $scope.progress.finish process
                desktopService.launchApp 'textEditor',
                    textId: textItem.id

                $scope.paginatorParams.currentPage = $scope.shortcuts['text'] if $scope.shortcuts['text']?

    $scope.upload = ->
        uploadService.requestUpload $scope.comb

    $scope.showMoreMenu = (e) ->
        items = multiselect.getFocused()

        if items.length > 0
            itemsActions = actionsService.getActions
                source: items
                context: $scope.comb
                target: $scope.comb
        else
            itemsActions = actionsService.getActions
                source: [$scope.comb]

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




