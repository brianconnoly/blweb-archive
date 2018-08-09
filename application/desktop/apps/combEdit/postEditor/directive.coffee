buzzlike
    .directive 'postEditor', (uploadService, desktopService, postService, combService, contentService, scheduleService, localization, confirmBox, complexMenu, actionsService, $rootScope) ->
        restrict: 'E'
        template: tC['/desktop/apps/combEdit/postEditor']
        replace: true
        link: (scope, element, attrs) ->

            elem = $ element

            scope.emptyPost = false

            #
            # Get initial post
            #

            scope.postContent = []
            preparePostContent = ->
                scope.emptyPost = true
                scope.postContent.length = 0

                contentOrder = 
                    'text': 0
                    'image': 1
                    'video': 2
                    'audio': 3
                    'poll': 4
                    'file': 5
                    'url': 6

                for k,arr of scope.post.contentIds
                    scope.postContent.push 
                        order: contentOrder[k]
                        list: arr
                        type: k

                    if arr.length > 0
                        scope.emptyPost = false

                # Fetch schedules
                if scope.post.scheduled == true
                    schedProcess = scope.progress.add()
                    scheduleService.fetchByPostId scope.id, ->
                        scope.progress.finish schedProcess

            process = scope.progress.add()
            scope.post = postService.getById scope.id, (post) ->
                scope.progress.finish process
                scope.post = post
                preparePostContent()

            scope.$watch 'post.contentIds', (nVal) ->
                if nVal?
                    preparePostContent()

            scope.isFullSized = (block) -> block.type in ['image', 'video'] and block.list.length == 1

            #
            # Schedules
            #

            scope.schedules = scheduleService.getByPostId scope.id

            #
            # Post actions
            #

            scope.changeOrder = (step) ->
                if !step then return false
                if typeof step == 'number'
                    step = -step
                    i = scope.comb.postIds.indexOf(scope.id) # scope.comb.postIds.length-1 - i
                    neighbour = scope.comb.postIds[i-step]
                    if neighbour
                        tempId = scope.comb.postIds[i]
                        removeElementFromArray tempId, scope.comb.postIds
                        scope.comb.postIds.splice i-step, 0, tempId

                        combService.call 'setFlags',
                            id: scope.comb.id
                            postIds: scope.comb.postIds
                        , -> 
                            true

            scope.removeFromPost = (id) ->
                process = scope.progress.add()
                postService.removeContentIds scope.id, [id], ->
                    scope.progress.finish process

            scope.deletePost = ->
                string = localization.declension 1, 'declension_post'
                title = localization.translate('comb_remove').replace "%s", string

                confirmBox.init title, () ->
                    process = scope.progress.add()
                    postService.delete
                        type: 'post'
                        id: scope.id
                    , ->
                        scope.progress.finish process

            scope.postActions = (e) ->
                itemsActions = actionsService.getActions
                    source: [scope.post]
                    context: scope.comb

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

            scope.newText = () ->
                process = scope.progress.add()
                contentService.create
                    type: 'text'
                , (textItem) ->
                    postService.addContentIds scope.post, [textItem.id], ->
                        scope.progress.finish process

                        desktopService.launchApp 'textEditor',
                            textId: textItem.id

            scope.hotUpload = () ->
                uploadService.requestUpload [scope.post]

            scope.showNetworkList = (e) ->
                networks = []
                for network in $rootScope.networks
                    networks.push
                        title: network.name #.toUpperCase()
                        value: network.type

                complexMenu.show [
                        object: scope.post
                        type: 'select'
                        param: 'socialNetwork'
                        items: networks
                        selectFunction: () ->
                            process = scope.progress.add()
                            postService.save scope.post, ->
                                scope.progress.finish process
                ],
                    top: $(e.target).offset().top + 27
                    left: $(e.target).offset().left

            true


            scope.openEditor = (id, e) ->
                desktopService.launchApp 'textEditor', 
                    textId: id
                    coords:
                        x: e.clientX - 100
                        y: e.clientY - 100

            scope.removeContentDescription = (id) ->
                process = scope.progress.add()
                delete scope.post.picComments[id]
                postService.save 
                    id: scope.post.id
                    picComments: scope.post.picComments
                , ->
                    scope.progress.finish process

    .directive 'contentComment', (contentService) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $ element

            scope.text = null

            scope.$watch () ->
                scope.post.picComments
            , (nVal) ->
                if nVal?[scope.id]
                    scope.text = contentService.getById nVal[scope.id]
            , true

            scope.$watch 'text', () ->
                scope.commentText = scope.text?.value
            , true




