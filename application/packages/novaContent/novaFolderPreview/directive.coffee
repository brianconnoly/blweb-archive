
elem = $ element
elem.parent().on 'dblclick', (e) ->
    if scope.flowBox?
        scope.flowBox.addFlowFrame
            title: 'content'
            directive: 'novaContentFrame'
            item:
                id: scope.item.id
                type: 'folder'
            data:
                folderId: scope.item.id
        , scope.flowFrame

    scope.$apply()

scope.getIds = ->
    res = []
    if !scope.item.contentIds?
        return res

    for id,i in scope.item.contentIds
        if i > 3 then break
        res.push id
    res
