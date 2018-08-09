*deps: postService, contentService

elem = $ element

scope.items = []
# scope.post = postService.getById scope.postId

currentStyle = null

scope.postImages = []
scope.postText = ""
prepareText = (ids) ->
    scope.postText = ""
    contentService.getByIdsOptimized ids, (textItems) ->
        for text in textItems
            if scope.postText != ""
                scope.postText += "\n"
            scope.postText += text.value
        if scope.postText.length > 87
            scope.postText = scope.postText.substring 0, 87
            scope.postText += '…'

scope.$watch 'item.contentIds.text', (nVal) ->
    scope.items.length = 0
    if nVal?
        prepareText nVal

, true
