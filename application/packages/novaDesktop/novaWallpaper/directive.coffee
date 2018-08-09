*deps: contentService
*replace: true
*scope: 
    params: '=?'

body = $ 'body'
elem = $ element
imgBlurred = elem.children 'img.blurred'
imgReal = elem.children 'img.real'
imgR = null

imageInRatio = (img, ratio) ->
    imgRatio = img.height / img.width

    if imgRatio > ratio
        css =
            width: '100%'
            height: 'auto'
            "margin-top": - ( (100 * imgRatio - 100 * ratio) / 2 ) + '%'
            "margin-left": 0

    else
        css =
            width: 'auto'
            height: '100%'
            "margin-left": - ( (100 * ratio / imgRatio - 100) / 2 ) + '%'
            "margin-top": 0
    $(img).css css
    return css

settingsMap = 
    wallpaper: ""
    color: '#537fb7'
    wallpaperStyle: 'stretch'

currentWallpaper = null
scope.$watch 'params', (nVal) ->
    if !nVal?
        scope.params = {}

    for k,v of settingsMap
        scope.params[k] = v if !scope.params[k]?

    elem.css
        background: scope.params.color or '#537fb7'

    if !scope.params.wallpaper? or scope.params.wallpaper == ""
        currentWallpaper = null
        elem.removeClass 'showReal'
        elem.removeClass 'showBlurred'

    if scope.params.wallpaper?.length > 0 and scope.params.wallpaper != currentWallpaper
        currentWallpaper = scope.params.wallpaper
        elem.removeClass 'showReal'

        bodyWid = body.width()
        bodyHei = body.height()

        contentService.getById scope.params.wallpaper, (image) ->
            img = new Image
            img.onload = ->
                if elem.hasClass 'showReal'
                    return
                imgBlurred[0].src = image.thumbnail
                elem.addClass 'showBlurred'

                bodyRatio = bodyHei / bodyWid
                imgBlurred.css imageInRatio img, bodyRatio

            img.src = image.thumbnail

            imgR = new Image
            imgR.onload = ->
                if scope.params.wallpaper != nVal.wallpaper
                    return

                imgReal[0].src = image.original
                elem.removeClass 'showBlurred'
                elem.addClass 'showReal'

                bodyRatio = bodyHei / bodyWid
                imgReal.css imageInRatio imgR, bodyRatio

            imgR.src = image.original
, true


$(window).on 'resize', (e) ->
    if !imgR?
        return
        
    bodyWid = body.width()
    bodyHei = body.height()
    bodyRatio = bodyHei / bodyWid
    imgReal.css imageInRatio imgR, bodyRatio

true