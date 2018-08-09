# BuzzLike.Market
# Директива отображения лота постов и репостов

buzzlike.directive 'lotPostPreview', (favouriteService, postService, $filter) ->
    restrict: 'C'
    template: tC['/pages/market/directives/lotPostPreview']
    link: (scope, element, attrs) ->
        elem = $ element

        postId = scope.item.postId
        scope.post = postService.getById postId
        scope.previewItem = scope.post

        scope.triggerFavourite = ->
            favouriteService.triggerLotId scope.item.id
            true

        scope.isFavourite = () ->
            favouriteService.byLotId[scope.item.id]?

        scope.writeValues = ->
            values = []
            values.push
                time: $filter("timestampMask", "time date")(scope.item.dateFrom)
            values.push
                time: $filter("timestampMask", "time date")(scope.item.dateTo)

            elem
                .find(".bind.value")
                .each (i, elem) ->
                    for key, val of values[i]
                        $(elem).find("."+key).html(val)

        scope.writeValues()


        #if scope.item.lotType == 'repost'
        #    elem.append '<div class="repost-label">R</div>'

        true