*deps: postService

# Frame params
scope.flowFrame.maxWidth = 320

unreg = scope.$watch 'flowFrame.item.postId', (nVal) ->
    if nVal?
        scope.post = postService.getById nVal #scope.flowFrame.item.postId
        unreg()
, true
