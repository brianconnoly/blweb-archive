*deps: contentService, postService

scope.addText = ->
    console.log scope
    contentService.create
        type: 'text'
    , (textItem) ->
        postService.addContentIds scope.item, [textItem.id]
