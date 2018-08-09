*deps: ugcService, novaDesktop, postService
*replace: true

elem = $ element

# Frame params
scope.flowFrame.maxWidth = 320

scope.items = postService.getByCombId scope.flowFrame.item.id
scope.ugcs = ugcService.getByCombId scope.flowFrame.item.id

# scope.page = 0
# scope.total = null
# getPage = ->
#     if scope.total? and scope.items.length >= scope.total
#         return
#
#     postService.query
#         limit: 20
#         page: scope.page
#         proposedTo: scope.flowFrame.item.id
#     , (items, total) ->
#         for item in items
#             scope.items.push item
#     scope.page++
#
# getPage()

scope.postFilter = (item) ->
    !item.scheduled

scope.goComb = ->
    novaDesktop.launchApp
        app: 'novaThemesApp'
        item:
            id: scope.flowFrame.item.id
            type: 'comb'

scope.showProposed = ->
    lastFrame = scope.flowFrame
    for ugc in scope.ugcs
        frame = scope.flowFrame.flowBox.addFlowFrame
            title: 'ugc'
            directive: 'novaCollectorPostsFrame'
            item:
                id: ugc.id
                type: 'ugc'
        , lastFrame
        lastFrame = frame

scope.createPostActive = false
scope.createPost = ->
    scope.createPostActive = !scope.createPostActive

scope.closePostCreate = ->
    scope.createPostActive = false
