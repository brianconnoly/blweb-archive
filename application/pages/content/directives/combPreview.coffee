buzzlike
    .directive "combPreview", (contentService) ->
        replace: false
        template: window.templateCache['/global/directives/combPreview']
        link: (scope, element, attrs) ->
            scope.item = scope.comb
            $(element).data 'item', scope.comb
            scope.combimage =
                thumbnail: '/resources/images/test/5050.png'
            if scope.comb.picIds?[0]?
                pic = contentService.getContentById scope.comb.picIds[0]
                $(element).data 'image', pic.thumbnail
                scope.combimage = pic
            true

    .directive "dragToTimeline", (dragMaster) ->
        replace: false
        link: (scope, element, attrs) ->
            if scope.item?
                $(element).data 'item', scope.item

            new dragMaster.dragObject element[0],
                global: true
                helper: 'clone'
                start: () ->
                    true

            true