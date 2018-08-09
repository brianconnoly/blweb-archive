buzzlike.directive 'notificationUpload', (buffer, contentService, notificationService, stateManager) ->
    template: tC['/notificationCenter/notificationUpload']
    link: (scope, element, attrs) ->

        scope.previewsCount = 0

        scope.previewItems = []
        for i in [0..4]
            scope.previewItems.push scope.notification.ids[i] if scope.notification.ids[i]?

        scope.previewsCount = scope.previewItems.length

        scope.$watch 'notification', (nVal, oVal) ->
            if nVal.ids != oVal.ids
                scope.previewItems.length = 0

            if scope.previewItems.length == 0 and nVal.ids.length > 0
                for i in [0..4]
                    scope.previewItems.push nVal.ids[i] if nVal.ids[i]?

                scope.previewsCount = scope.previewItems.length
        , true

        scope.actions = [
            phrase: 'take_to_right'
            action: ->
                notificationService.markRead scope.notification.id, ->
                    contentService.getByIds scope.notification.ids, (items) ->
                        buffer.addItems items
        ]
