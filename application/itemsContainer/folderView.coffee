buzzlike.directive 'folderView', (contentService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element

        reloadView = ->
            if scope.progress?
                    process = scope.progress.add()

            scope.folder = contentService.getById scope.currentStep.folderId, (item) ->

                contentService.getByIds item.contentIds, ->

                    if process?
                        scope.progress.finish process

        scope.$watch 'currentStep.folderId', (nVal) ->
            if nVal?
                reloadView()

        scope.itemSort = (id) ->
            item = contentService.getById id
            if !item?.type?
                return
            return item[scope.currentStep.sortBy]

        scope.itemFilter = (id) ->
            filterSet = false
            for k,v of scope.currentStep.filterTypes 
                if v == true then filterSet = true

            if filterSet == false
                return true

            item = contentService.getById id
            if item.type == 'folder'
                return true
                
            if !item?.type?
                return
            return scope.currentStep.filterTypes[item.type]
        true