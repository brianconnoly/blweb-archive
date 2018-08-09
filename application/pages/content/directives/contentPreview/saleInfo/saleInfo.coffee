buzzlike.directive "saleInfo", (lotSettings, operationsService, lotService, buffer, $state) ->
    template: tC['/pages/content/directives/contentPreview/saleInfo']
    link: (scope, element, attrs) ->
        id = attrs.saleInfo  #lot id
        lot = operationsService.get 'lot', id

        scope.openEditor = () ->
            lotSettings.editLotById id
            true

        scope.take = ->
            operationsService.requestOperation
                action: "buy",
                entities: [
                    id: id,
                    type: "lot",
                    lotType: "content"
                ]
                cb: (itemId) ->
                    item = operationsService.get lot.entityType, itemId
                    buffer.addItems [item]


        scope.lotStatus = ->
            lot = operationsService.get 'lot', id
            if !lot then return false

            errors = ['badTags', 'badContent']
            if lot.moderationStatus in errors then return 'rejected'
            if lot.moderationStatus == 'moderated' then return 'accepted'
            if !lot.published then return "notPublished"
            return "moderating"

        scope.button = ->
            if lotService.myLots[id]? then return "options"
            if $state.current.name != 'market' then return false # hide button
            return "buy"

        true