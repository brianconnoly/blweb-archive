*deps: localization, account, scheduleService, postService, combService, $filter, contentService, novaWizard, novaMenu

elem = $ element
addItems = $ elem.find('.addItems')[0]

# Post params
scope.postParams =
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
                    projectId: combItem.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_from_storage'
            action: ->
                novaWizard.fire 'contentBrowser',
                    projectId: combItem.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_import'
            action: ->
                novaWizard.fire 'importContent',
                    projectId: combItem.projectId
                    cb: scope.handlePastedItems
        ,
            phrase: 'novaPostCreate_add_text'
            action: ->
                contentService.create
                    type: 'text'
                    projectId: combItem.projectId
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
    if scope.postParams.newPostText.length > 0
        return false
    for k,v of scope.postParams.newPost.contentIds
        if v.length > 0
            return false
    true

scope.doCancel = ->
    scope.closePostCreate?()

scope.saveText = (textItem) ->
    contentService.save textItem

createPost = (combId, cb) ->
    scope.postParams.newPost.combId = combId
    scope.postParams.newPost.projectId = combItem.projectId
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

combItem = combService.getById scope.flowFrame.item.id

scope.doCreate = ->
    if scope.createBlocked()
        return

    createPost scope.flowFrame.item.id
    scope.doCancel()
