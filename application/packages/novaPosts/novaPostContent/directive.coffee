*deps: contentService
*replace: true

scope.postImages = []
scope.previewData =
    activeImage: null

scope.setBigPicture = (item) ->
    scope.previewData.activeImage = item

scope.$watch 'item.contentIds', (nVal) ->
    if nVal?
        scope.postImages.length = 0
        imageIds = []
        if nVal.image?
            for id in nVal.image
                imageIds.push id
        if nVal.file?
            for id in nVal.file
                imageIds.push id

        if imageIds.length > 0
            scope.postImages = contentService.getByIdsOptimized imageIds
            scope.previewData.activeImage = scope.postImages[0]
, true
