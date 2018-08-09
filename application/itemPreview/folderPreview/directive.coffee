buzzlike.directive 'folderPreview', ($compile) ->
    restrict: 'E'
    #template: tC['/itemPreview/folderPreview']
    replace: true
    link: (scope, element, attrs) ->

        generatePreview = (contentIds) ->
            body = $(element).parents('.body')
            element.empty()

            if contentIds.length > 0

                if session?.zoom == 'max'
                    result = contentIds.slice(0,9) #.reverse()
                else
                    result = contentIds.slice(0,4) #.reverse()
                
                
                for item in result
                    newScope = scope.$new()
                    newScope.id = item
                    newScope.type = 'content'
                    newElem = $compile('<div class="itemPreview mini" type="content" id="id" mini></div>')(newScope)
                    element.append newElem

            if scope.item.importInProgress
                element.append '<div class="importInProgress"></div>'

        scope.$watch 'previewItem.contentIds', generatePreview, true

        session = scope.$parent.session
        if session?
            scope.$watch ->
                session.zoom
            , (nVal) ->
                generatePreview scope.previewItem.contentIds
        
        true