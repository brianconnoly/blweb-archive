*deps: operationsService
*replace: true

# Frame params
scope.flowFrame.maxWidth = 320

scope.infoItem = operationsService.get scope.flowFrame.item.type, scope.flowFrame.item.id, (item) ->
    scope.owner = operationsService.get 'user', item.userId

scope.getAttachments = ->
    if !scope.infoItem?.type?
        return
    cnt = 0
    for k,v of scope.infoItem.contentIds
        cnt += v.length
    cnt

scope.getActivity = ->
    if !scope.infoItem?.type?
        return
    cnt = 0
    for k,v of scope.infoItem.lastStats
        cnt += v if k != 'activity'
    cnt = '—' if cnt == 0
    cnt

scope.bigPreview = ->
    scope.infoItem.type in ['image','file']
