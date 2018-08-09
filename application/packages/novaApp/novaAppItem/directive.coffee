*deps: operationsService

loadItem = ->
    operationsService.get scope.localItem.type, scope.localItem.id, (item) ->
        scope.item = item

if scope.flowFrame?
    # Dont take app item if flowFrame exist
    if scope.flowFrame.item?.type?
        scope.localItem = scope.flowFrame.item
        loadItem()
    return

if scope.session.item?.type?
    scope.localItem = scope.session.item
    loadItem()

# Wait if item will appear
# else
#     watcher = scope.$watch 'session.item.type', (nVal) ->
#         if scope.session.item?.type?
#             watcher()
#             loadItem()
