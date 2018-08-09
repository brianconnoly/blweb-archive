buzzlike
    .directive "contentPreview", (lotSettings, operationsService, $compile, $filter, contentService, localization, requestService, $rootScope) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            render = () ->
                $(element).empty()
                element.addClass scope.item.type
                element.addClass(scope.item.albumType) if scope.item.albumType

                switch scope.item.type
                    when 'folder'
                        ids = []
                        items = contentService.getContentByIdList(scope.item.contentIds)

                        for item in items
                            ids.push(item.id)
                        scope.ctx = ctx = ids?.slice -4
                        ctx.reverse()

                        el = $compile('<div class="mini preloadItem" ng-repeat="id in ctx"><div class="contentPreview"></div></div><div class="status" ng-show="item.importInProgress"></div>')(scope)
                        element.append el
                    when 'image'
                        element.append "<img src='#{proxyPrefix}#{scope.item.thumbnail}'/>"

                    when 'url'
                        # img = scope.item.thumbnail or '/resources/images/nwflw/link.png'
                        url = urlCropper(scope.item.value, 39, 'middle')

                        urlCenter = ''
                        titleCenter = ''
                        if url.length < 13
                            urlCenter = 'center'
                        if scope.item.title.length < 13
                            titleCenter = 'center'

                        template = '<div class="site-urlcontainer">
                                <div class="site-title">
                                    <div class="site-icon"></div><div class="content" speed="30">'+url+'</div>
                                </div>
                                <div class="site-description">'+scope.item.title+'</div>
                            </div>
                        '
                        element.append $compile(template)(scope)

                    when 'text'       #Если текст в базе пустой, то отображаем надпись "Новый текст" иначе сокращаем до 200 символов и ставим многоточие
                        textContent = ''
                        if scope.item.value
                            textContent = scope.item.value.substr(0, 200).replace(/\n/g, "<br>")
                            if scope.item.value.length > 200
                                textContent += "..."
                        else
                            textContent = localization.translate("contentPreview_newText")

                        element.append('<div class="text-preview">'+textContent+'</div>')
                        if $(element).parents('.postEntity').length < 5
                            element.append('<div class="text-footer"><div class="counter">'+localization.translate("textEditor_symbols")+': '+scope.item.value.length+'</div><div class="triangle"></div></div>')
                        if scope.item.locked and !$(element).parents('.postEntity').length
                            element.append '<div class="locked"></div>'

                    when 'video'
                        views = scope.item.views * 1

                        if views > 10000000
                            views = views / 1000000 | 0
                            views = $filter("formatNumber")(views)
                            views += 'M'
                        else if views > 100000
                            views = views / 1000 | 0
                            views = $filter("formatNumber")(views)
                            views += 'k'
                        else
                            views = $filter("formatNumber")(scope.item.views) || "-"

                        duration = $filter("secondsToHumanTime")(scope.item.duration)

                        template = "<div class='top views'>#{views}</div>
                                    <div class=duration>#{duration}</div>
                                    <div class='title bottom videoName'>
                                        <span class='videoNameSpan marquee' speed=30>#{scope.item.title}</span>
                                    </div>
                                    <img src='#{proxyPrefix}#{scope.item.thumbnail}'/>
                                    <div class='play_button'></div>
                        "

                        element.append $compile(template)(scope)
                    when 'audio'
                        #element.append '<img class="audio" src="https://cdn1.iconfinder.com/data/icons/windows-8-metro-style/512/audio_file.png"/>'
                        #element.append '<div class="track_name">' + scope.item.title + '<br>' + scope.item.artist + '</div>'

                        element.append "
                            <img class='sign' src='/resources/images/icons/whiteNote.png'>
                            <div class='track-name'>
                                <p class='head'>#{scope.item.title?.slice(0, 45)}</p>
                                <p class='body'>#{scope.item.artist?.slice(0, 45)}</p>
                            </div>
                        "
                    when 'album'
                        element.removeClass "album"
                        element.css "transition-duration", "0"
                        if scope.item.albumType=='video' then element.append '<div class="play_button"></div>'
                        element.append '<div class="album_label">' + scope.item.title + '</div>'

                        if scope.item.thumbnail and scope.item.thumbnail!="https://vk.com/resources/images/x_noalbum.png"
                            elem = $ element
                            img = new Image()
                            img.src = $rootScope.proxyPrefix + scope.item.thumbnail
                            img.onload = ->
                                prop = img.width / img.height
                                dest = elem.width() / elem.height()

                                if prop >= dest # wider
                                    pr2 = elem.height() / img.height
                                    nwid = img.width * pr2
                                    wid_diff = nwid - elem.width()

                                    css =
                                        'height': '100%'
                                        'width': 'auto'
                                        'left': '-' + (Math.floor(wid_diff/2) + 1) + 'px'
                                        'top': ''

                                if prop < dest # taller
                                    pr2 = elem.width() / img.width
                                    nhei = img.height * pr2
                                    hei_diff = nhei - elem.height()

                                    css =
                                        'width': '100%'
                                        'height': 'auto'
                                        'top': '-' + (Math.floor(hei_diff/2) + 1) + 'px'
                                        'left': ''

                                element.css
                                    "background-image": "url(#{proxyPrefix}#{scope.item.thumbnail})"
                                    "background-size": css.width+" "+css.height
                                    "background-position": css.left+" "+css.top
                        else
                            element.addClass "album"

                    when 'comb'
                        makeContentIds scope.item.contentIds

                    when 'post'
                        if scope.post?.contentIds?
                            makeContentIds scope.post.contentIds
                            if scope.post.readyToSchedule == false
                                scope.error = true

                        if scope.post.scheduled
                            if $(element).parents(".selectedPanel").length
                                info = $compile('<div schedule-info="'+scope.post.id+'" class="schedule-info"></div>')(scope.$new())
                                element.append info

                        if scope.post.onSale or scope.post.requestStatus or scope.lot
                            element.append '<div class="requestStatus">
                                <div class="corner"></div>
                                <div class="icon"></div>
                            </div>'
                            info = $compile('<div request-info="'+scope.post.id+'" class="schedule-info"></div>')(scope.$new())
                            element.append info


                    when 'schedule'
                        if scope.post?.contentIds?
                            makeContentIds scope.post.contentIds
                            if scope.post.readyToSchedule == false
                                scope.error = true

                        #if scope.item.scheduleType == 'repost' or scope.item.scheduleType == 'requestRepost'
                        #    element.append '<div class="repost-label">R</div>'

                        if scope.item.scheduleType == 'request' or scope.item.scheduleType == 'requestRepost'
                            scope.item.remove = -> true
                            if scope.item.requestStatus == 'rejected'
                                scope.item.remove = ->
                                    operationsService.requestOperation
                                        action: "remove"
                                        entities: [scope.item]
                                    true

                    when 'lot'
                        if scope.post?.contentIds?
                            makeContentIds scope.post.contentIds
                            if scope.post.readyToSchedule == false
                                scope.error = true

                        if scope.post
                            element.append '<div class="requestStatus">
                                <div class="corner"></div>
                                <div class="icon"></div>
                            </div>'

                            if scope.post.requestStatus or scope.post.requestsTotal
                                info = $compile('<div request-info="'+scope.post.id+'" class="schedule-info"></div>')(scope.$new())
                                element.append info
                            else if scope.post.scheduled
                                info = $compile('<div schedule-info="'+scope.post.id+'" class="schedule-info"></div>')(scope.$new())
                                element.append info

                        else if scope.item.lotType == 'content'
                            newScope = scope.$new()
                            newScope.item = operationsService.get scope.item.entityType, scope.item.entityId
                            element.append $compile('<div class="contentPreview"></div>')(newScope)

                        #if scope.item.lotType == 'repost'
                        #    element.append '<div class="repost-label">R</div>'

                if scope.item.deleted
                    template = '<img class="deleted-mark restoreDeleted" src="https://cdn3.iconfinder.com/data/icons/streamline-icon-set-free-pack/48/Streamline-70-256.png"/>'
                    el = $compile(template)(scope)
                    element.append el
                    return false

                #sale-info begin
                sellableTypes = ['folder', 'image', 'text', 'video', 'audio', 'comb', 'post']
                containerTypes = ['folder', 'schedule', 'comb', 'post', 'lot']

                containerParentType = (scope.$parent.item?.type in containerTypes)
                containerParentType = false if scope.$parent.item?.lotType == 'content'

                if scope.item.onSale and scope.item.lotId and !containerParentType and scope.item.type in sellableTypes
                    scope.lot = operationsService.get 'lot', scope.item.lotId
                    template = '<div sale-info="'+scope.item.lotId+'" class="sale-info"></div>'
                    element.append $compile(template)(scope)
                #/sale-info end

            makeContentIds = (collection) ->
                scope.preview = preview = []
                cnt = 0

                for name, cat of collection
                    if cnt > 4 then break
                    if cat.length > 0
                        for itemId in cat.slice().reverse()
                            item = contentService.getContentById(itemId)
                            if cnt > 3 then break
                            preview.push itemId
                            cnt++

                template = ''
                if collection.image.length>0
                    scope.shield = collection.image[0]
                    newscope = scope.$new()
                    newscope.id = scope.shield
                    template = '<div class="shield preloadItem" type="content">
                                    <div class="contentPreview"></div>
                                </div>'
                    el = $compile(template)(newscope)
                    element.append el

                if cnt > 0
                    single = ''
                    if scope.preview.length == 1
                        single = 'single '
                    template = '<div class="mini preloadItem" ng-repeat="id in preview" type="content" ng-class="{\'single\':preview.length == 1}">
                                    <div class="contentPreview"></div>
                                </div>'
                    el = $compile(template)(scope)
                    element.append el

            scope.$watch 'item', () ->
                if scope.item?.type? then render()
            , true

            scope.$watch 'post', () ->
                if scope.item?.type? then render()
            , true

            true

    .directive 'isolatedItem', (contentService) ->
        scope: true
        link: (scope, element, attrs) ->
            #console.log scope, attrs
            true

    .directive 'preloadItem', (contentService, combService, postService, lotService) ->
        restrict: 'C'
        link: (scope, element, attrs) ->

            makePreview = () ->
                id = if scope.id? then scope.id else scope.iterator.id
                type = 'content'

                if attrs.type?
                    type = attrs.type

                switch type
                    when 'lot'
                        scope.item = lotService.lotsById[id]
                        scope.post = postService.getById scope.item.postId
                    when 'comb'
                        scope.item = combService.getCombById id
                    when 'post'
                        scope.post = postService.getById id
                        scope.item = scope.post
                    else
                        scope.item = contentService.getContentById id

            makePreview()

            scope.$watch 'id', (nVal, oldVal) ->
                if nVal != oldVal
                    makePreview()

    .directive "itemSelector", ($rootScope) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            element.bind 'click', (e) ->
                if $rootScope.selected.indexOf(scope.item) < 0
                    $rootScope.selected.push scope.item
                    scope.$apply()
                    #element.addClass('selected')
                else
                    $rootScope.removeSel(scope.item)
                    scope.$apply()
                    #element.removeClass('selected')
                e.stopPropagation()
                return false