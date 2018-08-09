*deps: operationsService, $parse

if attrs.streamItem?
    scope.streamItem = $parse(attrs.streamItem)(scope)

scope.noItems = scope.streamItem.value in ['accepted_invite', 'rejected_invite']

scope.parent = operationsService.get scope.streamItem.parent.type, scope.streamItem.parent.id

scope.uniqParents = []
scope.$watch 'streamItem.items', (nVal) ->
    if !(nVal?.length > 0)
        return
    map = {}
    scope.uniqParents.length = 0
    for item in scope.streamItem.items
        map[item.parent.id] = item.parent if item.parent.id != scope.appItem.id
    for k,v of map
        scope.uniqParents.push v
, 0

scope.getParent = (parent) -> operationsService.get parent.type, parent.id

scope.trim = (str, index) ->
    $.trim(str) + if index < scope.uniqParents.length - 1 then ',' else ''
