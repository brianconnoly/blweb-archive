buzzlike
    .directive 'ugcDropBack', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    ugcService.save
                        id: scope.currentCollector.id
                        background: elem.dragObject.items[0].id
                    scope.$apply()
            true

    .directive 'ugcDropLogo', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    ugcService.save
                        id: scope.currentCollector.id
                        logo: elem.dragObject.items[0].id
                    scope.$apply()
            true

    .directive 'ugcDropTeam', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'team'
                drop: (elem, e) ->
                    ugcService.save
                        id: scope.currentCollector.id
                        teamId: elem.dragObject.items[0].id
                    scope.$apply()
            true

    .directive 'ugcDropPopupImage', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    scope.currentCollector.settings.popupImageId = elem.dragObject.items[0].id
                    ugcService.save
                        id: scope.currentCollector.id
                        settings: scope.currentCollector.settings
                    scope.$apply()
            true

    .directive 'ugcDropRatingHeaderImage', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    scope.currentCollector.settings.ratingHeaderImageId = elem.dragObject.items[0].id
                    ugcService.save
                        id: scope.currentCollector.id
                        settings: scope.currentCollector.settings
                    scope.$apply()
            true

    .directive 'ugcDropRatingPostImage', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    scope.currentCollector.settings.finalRatingPostImageId = elem.dragObject.items[0].id
                    ugcService.save
                        id: scope.currentCollector.id
                        settings: scope.currentCollector.settings
                    scope.$apply()
            true

    .directive 'ugcDropLoaderImage', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'image'
                drop: (elem, e) ->
                    scope.currentCollector.settings.loaderImageId = elem.dragObject.items[0].id
                    ugcService.save
                        id: scope.currentCollector.id
                        settings: scope.currentCollector.settings
                    scope.$apply()
            true


    .directive 'ugcDropFaqText', (ugcService, dragMaster) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    element.addClass('content-drop')
                leave: (elem) ->
                    $(element).removeClass('content-drop')
                canAccept: (elem, e) ->
                    elem.dragObject.items.length == 1 and elem.dragObject.items[0].type == 'text'
                drop: (elem, e) ->
                    scope.currentCollector.settings.faqTextId = elem.dragObject.items[0].id
                    ugcService.save
                        id: scope.currentCollector.id
                        settings: scope.currentCollector.settings
                    scope.$apply()
            true


            