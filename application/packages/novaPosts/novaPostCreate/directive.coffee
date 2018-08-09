*deps: groupService, localization, account, scheduleService, postService, combService, $filter, contentService, novaWizard, novaMenu

elem = $ element
addItems = $ elem.find('.addItems')[0]
# Cursor stuff
now = new Date()
scope.cursorTime = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
scope.scrollerParams =
    cursor: scope.cursorTime
scope.cursorChanged = ->
    oldTime = new Date scope.postParams.timestamp
    newTime = new Date scope.scrollerParams.cursor
    scope.postParams.timestamp = new Date(newTime.getFullYear(), newTime.getMonth(), newTime.getDate(), oldTime.getHours(), oldTime.getMinutes()).getTime()

# Post params
scope.postParams =
    timestamp: scope.session.data?.timestamp or new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes() + 15).getTime()
    projectId: scope.session.data?.projectId or account.user.id
    channelId: scope.session.data?.channelId or null
    combId: scope.session.data?.combId or null
    pickedCommunities: []
    newPostText: ""
    newThemeName: ""
    newPost:
        type: 'post'
        virtual: true
        id: 'createNewPost'+getRandomInt(0,1000)+Date.now()
        contentIds:
            image: []
            audio: []
            video: []
            url: []
            poll: []
            text: []

if scope.fullView
    scope.stateSaver.register 'postParams',
        save: ->
            scope.postParams
        load: (data) ->
            # emptyObject scope.postParams
            for k,v of data
                scope.postParams[k] = v

            saved = new Date scope.postParams.timestamp
            scope.scrollerParams.cursor = new Date(saved.getFullYear(), saved.getMonth(), saved.getDate()).getTime()

    scope.$watch 'postParams', (nVal) ->
        scope.stateSaver.save 'postParams'
    , true

scope.$watch 'postParams.projectId', (nVal) ->
    if nVal?
        groupService.getByProjectId nVal, (items) ->
            scope.postParams.channelId = items[0]?.id

# Graph stuff
scope.block =
    dayBreakType: 'day'
    timestamp: scope.scrollerParams.cursor

# Community ids
scope.communityIds = []
scope.$watch 'postParams.channelId', (nVal) ->
    if nVal?
        groupService.getById nVal, (group) ->
            scope.communityIds.length = 0
            for feed in group.feeds
                scope.communityIds.push feed.communityId

            fixPicked = false
            for picked in scope.postParams.pickedCommunities
                if picked not in scope.communityIds
                    fixPicked = true
                    break

            if fixPicked or scope.postParams.pickedCommunities.length == 0
                scope.postParams.pickedCommunities.length = 0
                for id in scope.communityIds
                    scope.postParams.pickedCommunities.push id


scope.getCommunities = ->
    if scope.postParams.pickedCommunities.length == 0
        return localization.translate 'novaPostCreate_noCommunities'
    if scope.postParams.pickedCommunities.length == scope.communityIds.length
        return localization.translate 'novaPostCreate_allCommunities'
    return scope.postParams.pickedCommunities.length + ' ' + localization.translate('novaPostCreate_of') + ' ' + scope.communityIds.length

scope.combPickerName = ->
    localization.translate 'novaScreenPicker_placeholder_pickComb'

scope.flushComb = ->
    scope.postParams.combId = null

scope.getPostButton = ->
    if scope.postParams.postId
        return localization.translate 'novaPostCreate_pick_post'
    return localization.translate 'novaPostCreate_from_storage'

scope.handlePastedItems = (items) ->
    if !scope.postParams.postId?
        for item in items
            scope.postParams.newPost.contentIds[item.type].push item.id if item.id not in scope.postParams.newPost.contentIds[item.type]
    else
        ids = []
        ids.push item.id for item in items
        postService.addContentIds scope.postParams.postId, ids

scope.addItems = (e) ->
    sections = [
        type: 'actions'
        items: [
            phrase: 'novaPostCreate_add_upload_content'
            action: ->
                novaWizard.fire 'upload',
                    projectId: scope.postParams.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_from_storage'
            action: ->
                novaWizard.fire 'contentBrowser',
                    projectId: scope.postParams.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_import'
            action: ->
                novaWizard.fire 'importContent',
                    projectId: scope.postParams.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_text'
            action: ->
                contentService.create
                    type: 'text'
                    projectId: scope.postParams.projectId
                , (textItem) ->
                    scope.handlePastedItems [textItem]
        ]
    ]

    offset = addItems.offset()
    novaMenu.show
        position:
            x: offset.left + Math.ceil(addItems.width() / 2) #e.pageX
            y: offset.top
            hei: addItems.height() # e.pageY
        sections: sections
        menuStyle: 'center'
        noApply: true

    e.stopPropagation()
    e.preventDefault()
    true

scope.addItemsUpload = ->
    novaWizard.fire 'upload',
        projectId: scope.postParams.projectId
        cb: scope.handlePastedItems

scope.addItemsStorage = ->
    novaWizard.fire 'contentBrowser',
        projectId: scope.postParams.projectId
        cb: scope.handlePastedItems

# Final stuff
scope.createBlocked = ->
    scope.postParams.pickedCommunities.length < 1 or
    scope.postParams.timestamp < Date.now()

scope.doCancel = ->
    if scope.flow?
        # Close popup
        scope.closePostCreate?()
    else
        # Close app
        scope.closeApp()

scope.saveText = (textItem) ->
    contentService.save textItem

createPost = (combId, cb) ->
    scope.postParams.newPost.combId = combId
    scope.postParams.newPost.projectId = scope.postParams.projectId
    delete scope.postParams.newPost.id
    postService.create scope.postParams.newPost, (postItem) ->
        if scope.postParams.newPostText?.length > 0
            contentService.create
                type: 'text'
                value: scope.postParams.newPostText
                projectId: scope.postParams.projectId
            , (item) ->
                postService.addContentIds postItem, [item.id]
                combService.addContentIds combId, [item.id]

        for communityId in scope.postParams.pickedCommunities
            scheduleService.create
                scheduleType: 'post'
                timestamp: scope.postParams.timestamp
                communityId: communityId
                projectId: scope.postParams.projectId
                postId: postItem.id

scope.doCreate = ->
    if scope.createBlocked()
        return

    if scope.postParams.postId?
        for communityId in scope.postParams.pickedCommunities
            scheduleService.create
                scheduleType: 'post'
                timestamp: scope.postParams.timestamp
                communityId: communityId
                projectId: scope.postParams.projectId
                postId: scope.postParams.postId
    else
        if scope.postParams.combId?
            createPost scope.postParams.combId
        else
            ids = []
            for k,v of scope.postParams.newPost.contentIds
                for id in v
                    ids.push id

            combService.create
                type: 'comb'
                name: scope.postParams.newThemeName or $filter('timestampMask')(Date.now(), 'hh:mm DD MMM YY')
                projectId: scope.postParams.projectId
                items: ids
            , (newComb) ->
                createPost newComb.id

    scope.doCancel()
