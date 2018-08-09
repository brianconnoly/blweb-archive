buzzlike.directive 'wallpaper', (desktopService, contentService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        body = $ 'body'
        elem = $ element
        imgElem = elem.children 'img'
        img = null

        scope.$watch ->
            desktopService.activeDesktop?.wallpaper
        , (nVal) ->
            bodyWid = body.width()
            bodyHei = body.height()
            if nVal?
                elem.removeClass 'visible'
                contentService.getById nVal, (image) ->
                    img = new Image
                    img.onload = () ->
                        imgElem.attr 'src', image.original
                        elem.addClass 'visible'

                        imgElem.css imageIn @, bodyWid, bodyHei, false, true

                    img.src = image.original
            else
                elem.removeClass 'visible'

        $(window).on 'resize', (e) ->
            if !img?
                return
                
            bodyWid = body.width()
            bodyHei = body.height()
            imgElem.css imageIn img, bodyWid, bodyHei, false, true
            
        true