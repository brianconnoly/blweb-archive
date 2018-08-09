# BuzzLike.Market
# Директива отображения лотов контента

buzzlike.directive 'lotContentPreview', (operationsService) ->
    restrict: 'C'
    template: tC['/pages/market/directives/lotContentPreview']
    link: (scope, element, attrs) ->

        operationsService.get scope.item.entityType, scope.item.entityId, (result) ->
            scope.previewItem = result

        true