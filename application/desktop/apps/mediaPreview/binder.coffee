buzzlike.directive 'lightboxPreview', ($rootScope) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element 

        scope.imageUrl = ""

        scope.picture = elem.find('.picture')
        scope.video = elem.find('.video')
        scope.win = elem.find('.window')

        imgWid = 1
        imgHei = 1

        resizeImage = ->
            ratio = imgWid / imgHei
            areaHei = (scope.session.size.height - 30)
            if scope.state.item.type == 'file'
                areaHei -= 30
            screenRatio = scope.session.size.width / areaHei

            if ratio > screenRatio
                # console.log (scope.session.size.height - 30), imgHei

                scope.picture.css
                    width: scope.session.size.width
                    top: (areaHei - scope.session.size.width / ratio) / 2
                    left: 'auto'
                    height: 'auto'

            else
                scope.picture.css
                    height: areaHei
                    left: (scope.session.size.width - ratio * areaHei) / 2
                    width: ratio * areaHei
                    top: 'auto'


        scope.onResizeProgress (wid, hei) ->
            resizeImage()

        loadImage = (url, cb) ->
            scope.showType = 'image'

            img = new Image()
            process = scope.progress.add()
            img.onload = ->
                imgWid = img.width
                imgHei = img.height 

                cb?()
                resizeImage()

                scope.imageUrl = img.src

                scope.progress.finish process
                scope.win.removeClass('loading')

                scope.$apply()

            img.src = $rootScope.proxyPrefix + url

        rebuildPreview = () ->

            if scope.state.item.type == 'image' or scope.state.item.contentType == 'image'
                loadImage scope.state.item.original, ->
                    resizeWindow()

            else if scope.state.item.type == 'file'
                loadImage scope.state.item.preview?.big, ->
                    resizeWindow()

            else if scope.state.item.type == 'video' or scope.state.item.contentType == 'video'
                scope.showType = 'video'
                switch scope.state.item.sourceType
                    when 'vkVideo', 'vkontakte'
                        src = scope.state.item.embeddedPlayer.replace('http://', '//')
                        videoObj = $('<iframe>')
                        videoObj.attr('src', src)
                        videoObj.attr('width', '100%')
                        videoObj.attr('height', '100%')

                        scope.video.empty()
                        scope.video.append videoObj

                    when 'youtubeVideo', 'youtube'
                        id = scope.state.item.embeddedPlayer.split('?v=')[1]
                        if id?
                            src = '//www.youtube.com/embed/' + id + '?feature=oembed'
                        else
                            src = scope.state.item.embeddedPlayer

                        videoObj = $('<iframe>')
                        videoObj.attr('src', src)
                        videoObj.attr('width', '100%')
                        videoObj.attr('height', '100%')

                        scope.video.empty()
                        scope.video.append videoObj

                scope.win.removeClass('loading')

        resizeWindow = ->
            maxHei = $('body').height() - 40

            ratio = imgWid / imgHei
            areaHei = (scope.session.size.height - 30)
            if scope.state.item.type == 'file'
                areaHei -= 30
            screenRatio = scope.session.size.width / areaHei

            # console.log ratio, screenRatio

            if ratio < screenRatio
                newHei = scope.session.size.width / ratio

                newHei += 30
                if scope.state.item.type == 'file'
                    areaHei += 30

                if newHei > maxHei
                    newHei = maxHei

                scope.setHeight newHei

        scope.download = (e) ->
            if !$(e.target).hasClass 'downloadButton'
                return false

            if scope.state.item.type == 'file'
                e.stopPropagation()
                e.preventDefault()

                window.location = scope.state.item.source

        scope.$watch 'state.item', (nVal) ->
            if nVal?.id?
                rebuildPreview()
        , true

        currentPreview = 0
        scope.canGoLeft = ->
            scope.state.item.type == 'file' and currentPreview > 0

        scope.canGoRight = ->
            scope.state.item.type == 'file' and currentPreview < (scope.state.item.preview.other?.length or 0)

        scope.goRight = ->
            currentPreview++

            if currentPreview > scope.state.item.preview.other?.length
                currentPreview = scope.state.item.preview.other?.length

            scope.win.addClass('loading')
            loadImage scope.state.item.preview.other[currentPreview-1]
            true

        scope.goLeft = ->
            currentPreview--

            if currentPreview < 0
                currentPreview = 0

            scope.win.addClass('loading')
            if currentPreview > 0
                loadImage scope.state.item.preview.other[currentPreview-1]
            else
                loadImage scope.state.item.preview.big
            true

        scope.selectUrl = (e) ->
            if document.selection
                range = document.body.createTextRange()
                range.moveToElementText e.target
                range.select()
            else if window.getSelection
                range = document.createRange()
                range.selectNode e.target
                window.getSelection().removeAllRanges()
                window.getSelection().addRange(range)

buzzlike.directive 'allowContext', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        $(element).on 'contextmenu', (e) ->
            scope.selectUrl e
            e.stopPropagation()

        true
