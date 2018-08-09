buzzlike.controller 'mediaPreviewCtrl', ($scope, $rootScope, operationsService, multiselect) ->

    $scope.session.expandedHeader = false

    $scope.stateTree.applyState
        'escape': $scope.closeApp
        'left': ->
            if !$scope.session.list?
                return
            index = $scope.session.list.indexOf $scope.session.contentId
            index--

            if index < 0
                index = $scope.session.list.length-1

            $scope.session.contentId = $scope.session.list[index]

            lprocess = $scope.progress.add()
            $scope.state.item = operationsService.get $scope.session.contentType or 'content', $scope.session.contentId, (item) -> # contentService.getById $scope.session.contentId, (item) ->
                $scope.state.item = item
                $scope.progress.finish lprocess
            true
        'right': ->
            if !$scope.session.list?
                return
            index = $scope.session.list.indexOf $scope.session.contentId
            index++

            if index > $scope.session.list.length-1
                index = 0

            $scope.session.contentId = $scope.session.list[index]

            lprocess = $scope.progress.add()
            $scope.state.item = operationsService.get $scope.session.contentType or 'content', $scope.session.contentId, (item) -> # contentService.getById $scope.session.contentId, (item) ->
                $scope.state.item = item
                $scope.progress.finish lprocess
            true

    image_original_width = 0
    image_original_height = 0

    $scope.state = {}
    process = $scope.progress.add()

    $scope.loading = false

    # $scope.$watch () ->
    #     multiselect.state.lastFocused
    # , (nVal, oVal) ->
    #     if nVal?
    #         nItem = angular.element(nVal[0]).scope().item

    #         if nItem != $scope.state.item
    #             $scope.state.item = $scope.state.item = nItem

    # Используем метод ресайза для начального отображения и для
    # эвента $(window).resize()
    $scope.resizeImage = (img, resized) ->
        # body_width  = $('body').width() * 0.88
        # body_height = $('body').height() - 80

        # # Сохраняем оригинальные размеры картинки, только при открытии
        # # чтобы при ресайзе окна картинка не брала не правильный размер
        # if !resized
        #     image_original_width  = img.width
        #     image_original_height = img.height

        # # уменьшаем и Позиционируем картинку по центру
        # kw = body_width / image_original_width
        # kh = body_height / image_original_height

        # scale = 1
        # scale = kh if kh < scale
        # scale = kw if kw < scale

        # w = image_original_width  * scale
        # h = image_original_height * scale

        # $scope.picture.css
        #     width: w
        #     height: h
        #     marginTop: -h/2
        #     marginLeft: -w/2

        # if !resized
        #     $scope.picture.prepend img

    rebuildPreview = () ->
        # if !$scope.state.item?
        #     $scope.state.item = null
        #     return true

        switch $scope.state.item.type
            when 'image'
                img = new Image()
                process = $scope.progress.add()
                img.onload = ->
                    $scope.picture.removeClass('wide').removeClass('tall')
                    if img.width > img.height 
                        $scope.picture.addClass 'wide'
                    else
                        $scope.picture.addClass 'tall'
                    $scope.progress.finish process
                    $scope.win.removeClass('loading')

                img.src = $rootScope.proxyPrefix + $scope.state.item.original
            #     img.src = $rootScope.proxyPrefix + $scope.state.item.original


            #     $('img', picture).removeAttr('style')

            #     $('img', picture).remove()
            #     # Если картинка загружена получаем ее размеры и ресайзим/позиционируем ее
            #     img.onload = ->
            #         $scope.resizeImage(img, false)
            #         $(window).off('resize.lightbox').on 'resize.lightbox', ->
            #             $scope.resizeImage(img, true)

            #         elem.find(".window .content .buttons").remove()
            #         buttons = $('<div class="buttons">
            #                 <div class="left"></div>
            #                 <div class="edit closer"></div>
            #                 <div class="right"></div>
            #             </div>')
            #         #elem.find(".content.picture").append(buttons)

            #         buttons.find(".edit").click ->
            #             stateManager.faderClick()
            #             contentBuilder.init(img)
            #             false

            when 'video'

                switch $scope.state.item.sourceType
                    when 'vkVideo', 'vkontakte'
                        src = $scope.state.item.embeddedPlayer.replace('http://', '//')
                        videoObj = $('<iframe>')
                        videoObj.attr('src', src)
                        videoObj.attr('width', '100%')
                        videoObj.attr('height', '100%')

                        $scope.video.empty()
                        $scope.video.append videoObj

                    when 'youtubeVideo', 'youtube'
                        id = $scope.state.item.embeddedPlayer.split('?v=')[1]
                        src = '//www.youtube.com/embed/' + id

                        videoObj = $('<iframe>')
                        videoObj.attr('src', src)
                        videoObj.attr('width', '100%')
                        videoObj.attr('height', '100%')

                        $scope.video.empty()
                        $scope.video.append videoObj

                $scope.win.removeClass('loading')

            when 'audio'
                $scope.win.removeClass('loading')

    $scope.state.item = operationsService.get $scope.session.contentType or 'content', $scope.session.contentId, (item) -> # contentService.getById $scope.session.contentId, (item) ->
        $scope.state.item = item
        $scope.progress.finish process
        # rebuildPreview()

    # $scope.$watch 'state.item', rebuildPreview, true
    # rebuildPreview()
