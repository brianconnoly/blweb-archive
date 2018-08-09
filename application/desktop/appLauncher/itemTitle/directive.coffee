buzzlike.directive 'itemTitle', ($parse, operationsService, localization) ->
    restrict: 'E'
    replace: true
    template: tC['/desktop/appLauncher/itemTitle']
    link: (scope, element, attrs) ->
        elem = $ element

        prevName = ""
        # scope.editedItem = operationsService.get attrs.type, $parse(attrs.id)(scope), (item) ->
        #     prevName = item.name

        scope.$watch attrs.id, ->
            scope.editedItem = operationsService.get attrs.type, $parse(attrs.id)(scope), (item) ->
                prevName = item.name

        scope.save = ->

            if scope.progress?
                process = scope.progress.add()

            operationsService.save attrs.type, 
                type: scope.editedItem.type
                id: scope.editedItem.id
                name: scope.editedItem.name
            , ->
                if process?
                    scope.progress.finish process

        scope.$on '$destroy', ->
            if scope.editedItem.name != prevName
                scope.save()

        localization.onLangLoaded ->
            elem.attr 'placeholder', localization.translate attrs.placeholdertext
        true