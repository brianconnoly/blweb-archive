buzzlike.directive 'restoreDeleted', (confirmBox, contentService, localization) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element

        elem.bind 'dblclick', (e) ->
            confirmBox.init localization.translate(56), () ->
                contentService.restoreItem scope.item


            e.stopPropagation()
            e.preventDefault()
        true