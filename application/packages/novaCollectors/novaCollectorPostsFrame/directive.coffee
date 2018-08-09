*deps: ugcService, novaDesktop, postService
*replace: true

elem = $ element

# Frame params
scope.flowFrame.maxWidth = 320

scope.ugc = ugcService.getById scope.flowFrame.item.id

scope.items = postService.getByUgcId scope.flowFrame.item.id

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

scope.proposedFilter = (item) ->
    item.proposeStatus == 'created'

scope.goComb = ->
    for combId in scope.ugc.combIds
        novaDesktop.launchApp
            app: 'novaThemesApp'
            item:
                id: combId
                type: 'comb'
