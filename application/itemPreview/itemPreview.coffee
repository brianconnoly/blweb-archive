buzzlike.directive 'itemPreview', (operationsService, smartDate, $compile, $filter, localization, scheduleService, lotService, postService, teamService, requestService) ->
    restrict: 'C'
    scope: 
        item: '=?'
        id: '=?'
        type: '@'
        counter: '=?'
    link: (scope, element, attrs) ->

        if scope.$parent?.$parent?.$parent?.$parent?.$parent?.refreshItem?
            return

        jElem = $ element
        currentParams = null
        allParams = {}
        # scheduleInfo - аватарка сообщества и время, куда был зашедулен пост
        # scheduleStatus - статус шедула с расшифровкой
        # requestInfo - количество запросов
        # requestStatus - иконка статуса реквеста
        # adStatus - желтый треугольник (рекламный пост)
        # saleInfo - шестеренка и аудитория проданного контента
        # lotRepostInfo - аватарка сообщества и цена репоста
        # в массиве к каждому оверлею указаны типы, для которых применим этот оверлей

        allParams['timeline'] =
            scheduleStatus: true
            #requestStatus: true
            # lotRepostInfo: ['lot', 'post']
            saleInfo: ['post']
            # scheduleInfo: ['post']
            timeInfo: ['post']

        allParams['contentPage'] =
            #saleInfo: true

        allParams['combPage'] =
            #saleInfo: true

        allParams['catalog'] =
            #saleInfo: true
            #scheduleInfo: true
            lotRepostInfo: ['lot', 'post']

        allParams['rightPanel'] =
            saleInfo: true
            scheduleInfo: ['post']
            lotRepostInfo: ['lot']

        allParams['blView'] =
            saleInfo: ['lot']
            # lotRepostInfo: ['lot']

        currentParams = allParams[attrs.overlay] if attrs.overlay

        if !currentParams
            currentParams = {}
            if attrs.overlay
                arr = attrs.overlay.split '/'
                for i in arr
                    currentParams[i] = true

        lockableTypes = ['text']

        allowOverlay = (overlay) ->
            overlay and (overlay == true or scope.item?.type in overlay)

        displayItem = (item) ->   # need refactor

            element.removeClass 'empty'
            # Base preview
            scope.previewItem = item
            if !scope.item?
                scope.item = item
            element.addClass item.type

            # Счетчик для сгруппированных сущностей
            if scope.counter?
                element.append '<div class="counterStack">' + scope.counter + '</div>'

            # 2 типа провью.
            # Первый собирается вручную.
            # Второй работает с помощью директивы и replace

            if !item.type?
                return true

            if scope.builded == true and item.type not in ['image', 'post']
                return true

            if scope.builded == true and item.type not in ['comb', 'post']
                element.empty()


            switch item.type
                when 'text'
                    textContent = ''
                    textLength = 0
                    if scope.previewItem.value?
                        textLength = scope.previewItem.value.length
                    if scope.previewItem.value
                        textContent = scope.previewItem.value.substr(0, 200).replace(/\n/g, "<br>")
                        if textLength > 200
                            textContent += "..."
                    else
                        textContent = localization.translate("contentPreview_newText")

                    element.append('<div class="text-preview">'+textContent+'</div>')

                                                                                # замки:
                    #if !scope.item.locked                                      # - всюду на вышедших  (be test)
                    #if !scope.item.locked and scope.item.type in lockableTypes # - невышедшие тексты  (fe test)
                    if scope.item.locked and scope.item.type in lockableTypes   # - вышедшие тексты (нормально)
                        $(element).append '<div class="locked">'
                            
                    scope.$watch 'previewItem.value', (nVal) ->
                        textContent = ''
                        if nVal
                            textContent = nVal.substr(0, 200).replace(/\n/g, "<br>")
                            if nVal.length > 200
                                textContent += "..."
                        else
                            textContent = localization.translate("contentPreview_newText")
                            
                        $(element).children('.text-preview').html textContent

                when 'image'
                    imgElem = $ "<img class='picPreload' src='#{proxyPrefix}#{item.thumbnail}'>"
                    element.append imgElem
                    $compile(imgElem)(scope)

                when 'file'
                    tmpl = ""
                    if item.preview.small?.length > 0
                        tmpl += "<img class='picPreload' src='#{proxyPrefix}#{item.preview.small}'>"
                    else
                        date = $filter('timestampMask')(item.created, 'DD MMM YYYY hh:mm')
                        size = humanize.filesize item.size
                        tmpl += "<div class='infoBlock'><div class='size'>#{size}</div><div class='date'>#{date}</div></div>"

                        if item.fileType in ['zip', 'rar', '7z', '7zip', 'arj']
                            tmpl += "<img class='icon' src='/resources/images/desktop/files/archive.svg'/>"
                        else
                            tmpl += "<img class='icon' src='/resources/images/desktop/files/other.svg'/>"

                    tmpl += "<div class='name bottom'>#{item.name}</div><div class='extension ext_#{item.fileType}'>#{item.fileType}</div>"

                    imgElem = $ tmpl
                    element.append imgElem
                    $compile(imgElem)(scope)

                when 'audio'
                    element.append "
                            <img class='sign' src='/resources/images/desktop/audio.svg'>
                            <div class='track-name'>
                                <p class='audioHead'>"+item.title?.slice(0, 45)+"</p>
                                <p class='artist'>"+item.artist?.slice(0, 45)+"</p>
                            </div>
                        "
                when 'folder'
                    # Генерим директиву
                    if !scope.$parent?.$parent?.$parent?.refreshItem?
                        elem = $compile('<folder-preview>')(scope)
                        element.append elem
                when 'poll'
                    template = '<img class="sign" src="/resources/images/desktop/poll.svg">'

                    if scope.previewItem.lastStats?.total > 0
                        template += '<div class="totalVotes">⦿ ' + scope.previewItem.lastStats.total + '</div>'

                    template += '<div class="site-title">
                                    <div class="description">{{previewItem.value}}</div>
                                    <div class="siteTitle">{{previewItem.name}}</div>
                                </div>
                    '

                    tmpl = $ template
                    element.append tmpl
                    $compile(tmpl)(scope)
                when 'url'
                    url = urlCropper(scope.previewItem.value, 39, 'middle')

                    urlCenter = ''
                    titleCenter = ''
                    if url.length < 13
                        urlCenter = 'center'
                    if scope.previewItem.title == null
                        scope.previewItem.title = ""
                    if scope.previewItem.title.length < 13
                        titleCenter = 'center'

                    template = '<img class="sign" src="/resources/images/desktop/url.svg">
                                <div class="site-title">
                                    <div class="description">'+scope.previewItem.title+'</div>
                                    <div class="siteTitle">'+url+'</div>
                                </div>
                    '
                    element.append template
                
                when 'video'
                    views = scope.previewItem.views * 1

                    if views > 10000000
                        views = views / 1000000 | 0
                        views = $filter("formatNumber")(views)
                        views += 'M'
                    else if views > 100000
                        views = views / 1000 | 0
                        views = $filter("formatNumber")(views)
                        views += 'k'
                    else
                        views = $filter("formatNumber")(scope.previewItem.views) || "-"

                    duration = $filter("secondsToHumanTime")(scope.previewItem.duration)

                    template = "
                                <div class='name bottom'>#{scope.previewItem.title}</div>
                                <img src='#{proxyPrefix}#{scope.previewItem.thumbnail}'/>
                                <div class='play_button'></div>
                                <div class='duration'>#{duration}</div>
                    "

                    element.append template

                when 'comb', 'post'
                    if scope.builded != true
                        elem = $compile('<complex-preview>')(scope)
                        element.append elem

                        if item.type == 'post'
                            element.append $compile('<div ng-class="item.needWork" class="needWorkMark" ng-if="item.needWork && $parent.sched.status == \'planned\'"></div>')(scope)
                        else
                            element.append $compile('<div class="statsLabel activityIndicator", ng-if="item.lastStats.likes || item.lastStats.comments || item.lastStats.reposts || item.lastStats.commLikes"><div class="statsIcon">⦿</div><div class="statsValue">{{item.lastStats.likes + item.lastStats.comments + item.lastStats.reposts + item.lastStats.commLikes}}</div></div>')(scope)

                when 'lot'
                    lotScope = scope.$new()

                    if item.lotType != 'content'
                        lotScope.id = item.postId

                        elem = $compile('<div class="itemPreview" type="post", id="id">' + "<div class='itemPreview shield topShield' type='image' id='item.cover' ng-if='item.cover'></div>")(lotScope)
                        element.append elem

                when 'community'
                    src = item.photo #|| '/resources/images/icons/timeline-empty-avatar@2x.png'
                    template = "<img src='#{proxyPrefix}#{src}'>
                        <div class='name'>#{item.name}</div>
                        <div class='members'>#{item.membersCount}</div>"

                    # elem = $compile(template)(scope)
                    element.append template

                when 'user'
                    src = item.photo #|| '/resources/images/icons/timeline-empty-avatar@2x.png'
                    template = $ "<img src='#{proxyPrefix}#{src}' class='picPreload userPic' >"

                    # scope.$watch 'previewItem.photo', (nVal) ->
                    #     $(element).find('img').attr('src',nVal+'?a=1')

                    #elem = $compile(template)(scope)
                    element.append template #elem
                    $compile(template)(scope)

                when 'team'
                    template = "<div ng-repeat='member in item.members' class='itemPreview' ng-class='{" + '"mini":item.members.length > 1, "single":item.members.length == 1' + "}' type='user' id='member.userId'></div>
                        <div class='itemPreview shield' type='image' id='item.cover' ng-if='item.cover'></div>
                        "

                    elem = $compile(template)(scope)
                    element.append elem

                when 'task'
                    if scope.previewItem.teamId?
                        scope.team = teamService.getById scope.previewItem.teamId
                    tmpl = "
                            <img class='sign' src='/resources/images/desktop/task-icon-black.svg'>
                            <div class='track-name'>
                                <p class='audioHead'>{{item.name}}</p>
                                <p class='artist'>{{team.name}}</p>
                            </div>
                        "

                    elem = $compile(tmpl)(scope)
                    element.append elem

                when 'importAlbum'
                    src = item.thumbnail #|| '/resources/images/icons/timeline-empty-avatar@2x.png'
                    if !src? or src?.length < 1 or src == 'http://vk.com/resources/images/m_noalbum.png'
                        switch item.albumType
                            when 'image'
                                src = '/resources/images/desktop/importAlbums/imageAlbum.svg'
                            when 'audio'
                                src = '/resources/images/desktop/importAlbums/audioAlbum.svg'
                            when 'video'
                                src = '/resources/images/desktop/importAlbums/videoAlbum.svg'

                    template = "<img src='#{proxyPrefix}#{src}' class='picPreload' preview-box >
                        <div class='name'>#{item.title}</div>"

                    if item.size > 0
                        template += "<div class='size'>#{item.size}</div>"

                    elem = $compile(template)(scope)
                    element.append elem

                when 'importContent'
                    switch item.contentType
                        when 'image'
                            template = "<img class='picPreload' src='#{item.thumbnail}' preview-box>"
                            elem = $compile(template)(scope)
                            element.append elem
                            # scope.processImage()

                        when 'audio'
                            element.addClass 'audio'
                            element.append "
                                <img class='sign' src='/resources/images/desktop/audio.svg'>
                                <div class='track-name'>
                                    <p class='head'>"+item.title?.slice(0, 45)+"</p>
                                    <p class='artist'>"+item.artist?.slice(0, 45)+"</p>
                                </div>
                            "

                        when 'video'
                            views = scope.previewItem.views * 1

                            if views > 10000000
                                views = views / 1000000 | 0
                                views = $filter("formatNumber")(views)
                                views += 'M'
                            else if views > 100000
                                views = views / 1000 | 0
                                views = $filter("formatNumber")(views)
                                views += 'k'
                            else
                                views = $filter("formatNumber")(scope.previewItem.views) || "-"

                            duration = $filter("secondsToHumanTime")(scope.previewItem.duration)

                            template = "<div class='top views'>#{views}</div>
                                        <div class='duration'>#{duration}</div>
                                        <div class='name bottom nowrap'>
                                            <span class='videoNameSpan marquee' speed=30>#{scope.previewItem.title}</span>
                                        </div>
                                        <img src='#{proxyPrefix}#{scope.previewItem.thumbnail}'/>
                                        <div class='play_button'></div>
                            "

                            element.append template

                        when 'url'
                            element.addClass 'url'
                            url = urlCropper(scope.previewItem.value, 39, 'middle')

                            urlCenter = ''
                            titleCenter = ''
                            if url.length < 13
                                urlCenter = 'center'
                            if scope.previewItem.title == null
                                scope.previewItem.title = ""
                            if scope.previewItem.title.length < 13
                                titleCenter = 'center'

                            template = '<img class="sign" src="/resources/images/desktop/url.svg">
                                        <div class="site-title">
                                            <div class="description">'+scope.previewItem.title+'</div>
                                            <div class="siteTitle">'+url+'</div>
                                        </div>
                            '
                            element.append template


            if !attrs.mini # вешаем различные ~info
                switch item.type
                    when 'lot'
                        if scope.item.lotType in ['post', 'repost']
                            #operationsService.get 'post', scope.item.postId, (post) ->
                                #currentParams.adStatus = true
                                #element.append '<div class="requestStatus">
                                #    <div class="corner"></div>
                                #    <div class="icon"></div>
                                #</div>'

                                #if post.requestStatus or post.requestsTotal
                                #    info = $compile('<div request-info="'+post.id+'" class="schedule-info"></div>')(scope.$new())
                                #    element.append info
                                #else
                                #if post.scheduled
                                #    info = $compile('<div schedule-info="'+post.id+'" class="schedule-info"></div>')(scope.$new())
                                #    element.append info

                        else if scope.item.lotType == 'content'
                            newScope = scope.$new()
                            newScope.id = scope.item.entityId
                            newScope.type = scope.item.entityType
                            element.append $compile('<div class="itemPreview" id="id", type="{{type}}"></div>')(newScope)

                if currentParams.scheduleStatus # только таймлайн
                    jElem.children('.generatedStatus').remove()

                    if scope.builded != true

                        sched = scope.$parent.sched

                        #if !sched then return
                        # Если заявка не подтверждена или ждёт подтверждения, статус не показываем
                        if sched.requestStatus not in ['rejected']
                            status = {}
                                #icon: '<div class="icon"></div>'
                            #----- title -----
                            # if sched.status and sched.status!='error'
                            #     status.title = localization.translate("post_status")[sched.status]

                            # status.title = $('<div class="title">').html(status.title) if status.title
                            #----- explanation ------
                            # if sched.status=='error'
                            #     error = localization.translate("rpc_error_"+sched.errorDetails?.code)
                            #     status.explanation = $('<div class="explanation">')
                            #         .append('<div class="caption">'+sched.errorDetails?.code+': '+error['caption']+'</div>')
                            #         .append('<div class="text">'+error['text']+'</div>')
                            # #----- compiling -----
                            # tmpl = $('<div class="status generatedStatus">')
                            #     .addClass sched.status  # instead of ng-class
                            # for i of status
                            #     tmpl.append status[i]

                            tmp = $ '<div>',
                                class: 'statusLayer'
                                status: 'sched.status'

                            element.append tmp
                            $compile(tmp[0])(scope)

                if currentParams.adStatus
                    jElem.children('.requestStatus').remove()

                    post = null
                    switch item.type
                        when 'post'
                            post = item
                        when 'lot'
                            if item.lotType in ['post', 'repost']
                                adType = true
                                post =
                                    id: item.postId

                    if post
                        operationsService.get 'post', post.id, (post) ->
                            if post.onSale or adType
                                status = if scope.item.requestStatus then ' '+scope.item.requestStatus else ''
                                element.append '<div class="requestStatus'+status+'">
                                    <div class="corner"></div>
                                    <div class="icon"></div>
                                </div>'

                #--------
                if currentParams.requestStatus
                    jElem.children('.requestStatus').remove()

                    if attrs.overlay == 'timeline'
                        sched = scope.$parent.sched

                    if attrs.overlay == 'outboxRequests'
                        sched =
                            scheduleType: 'request'
                            requestStatus: scope.$parent.request.requestStatus

                    if sched.scheduleType in ['request', 'requestRepost']
                        status =
                            corner: '<div class="corner"></div>'
                            icon: $('<div class="icon"></div>')
                                .click ->
                                    if sched.requestStatus == 'rejected'
                                        requestService.delete scope.item
                                        scope.$apply()
                                    return true

                        tmpl = $('<div class="requestStatus">')
                            .addClass sched.requestStatus  # instead of ng-class

                        for i of status
                            tmpl.append status[i]

                        element.append $compile(tmpl)(scope)

                #--------
                if currentParams.requestInfo
                    jElem.children('.schedule-info').remove()

                    switch item.type
                        when 'post'
                            post = item

                            if post.requestStatus or post.requestsTotal
                                info = $compile('<div request-info="'+post.id+'" class="schedule-info"></div>')(scope.$new())
                                element.append info

                #--------
                if allowOverlay currentParams.scheduleInfo
                    jElem.children('.schedule-info').remove()
                    if item.type == 'post' then scope.post = post = item

                    if post and post.scheduled
                        info = $compile('<div post="post" class="schedule-info"></div>')(scope.$new())
                        element.append info

                if !scope.builded and allowOverlay currentParams.timeInfo
                    sched = scope.$parent.sched
                    tsCache = {}
                    scope.getFormatedDate = () ->
                        ts = smartDate.getShiftTimeBar(sched.timestamp)
                        if !tsCache[ts]?
                            tsCache[ts] = $filter('timestampMask')(ts, 'hh:mm')
                        tsCache[ts]
                    info = $('<div class="timeInfo"></div>') #(scope) {{getFormatedDate()}}
                    info.html scope.getFormatedDate()
                    element.append info

                    scope.$watch '$parent.sched.timestamp', ->
                        info.html scope.getFormatedDate()


                if !scope.builded and currentParams.saleInfo and item.type in currentParams.saleInfo
                    sellableTypes = ['lot', 'folder', 'image', 'text', 'video', 'audio', 'comb'] #,'post']

                    sched = scope.$parent.sched

                    if item.type == 'post' and sched.requestId?
                        scope.priceItem = requestService.getById sched.requestId
                        
                        # scope.getPriceTag = ->
                        #     if !sched?.id?
                        #         return ''

                            
                        #     console.log scope.priceItem
                        #     if !scope.priceItem?.id?
                        #         return ''

                        #     if scope.priceItem.cost == 0
                        #         return localization.translate 'marketApp_lotPrice_free'
                                
                        #     priceString = scope.priceItem.cost + ' '
                        #     if scope.priceItem.buzzLot
                        #         priceString += localization.declensionPhrase scope.priceItem.cost, 'costDays'
                        #     # else
                        #     #     priceString += localization.declensionPhrase scope.item.price, 'roubles'
                        #     priceString

                        element.append $compile('<div class="priceTag">{{priceItem.cost}}</div>')(scope)

                    else if item.type == 'lot'

                        scope.getPriceTag = ->

                            if item.price == 0
                                return localization.translate 'marketApp_lotPrice_free'
                                
                            priceString = item.price + ' '
                            if item.buzzLot
                                priceString += localization.declensionPhrase item.price, 'costDays'
                            # else
                            #     priceString += localization.declensionPhrase scope.item.price, 'roubles'
                            priceString

                        element.append $compile('<div class="priceTag">{{getPriceTag()}}</div>')(scope)

                    # lot = {}
                    # displayLotInfo = ->
                    #     if item.type == 'lot' and item.lotType == 'content'
                    #         lot.onSale = lot.sellable = true
                    #         lot.id = item.id
                    #     else if item.sourceId
                    #         lot.id = item.sourceId
                    #         lot.onSale = lot.sellable = true
                    #     else
                    #         lot.onSale = item.onSale
                    #         lot.sellable = item.type in sellableTypes
                    #         lot.id = item.lotId

                    #     if item.type == 'post' and item.scheduled
                    #         return

                    #     $(element).find('.price').remove()
                    #     if lot.onSale and lot.id and lot.sellable and lot.price
                    #         operationsService.get 'lot', lot.id, (lotItem) ->
                    #             scope.lot = lotItem
                    #             # template = '<div sale-info="'+lot.id+'" class="sale-info"></div>'
                    #             priceString = lot.price + ' '
                    #             if lot.buzzLot
                    #                 priceString += localization.declenstionPhrase lot.price, 'costDays'
                    #             else
                    #                 priceString += localization.declenstionPhrase lot.price, 'roubles'
                    #             element.append $compile('<div class="priceTag">{{item.price}}</div>')(scope)
                                # element.append $compile(template)(scope)

                    # if scope.previewItem.sourceId?
                    #     watcher = 'previewItem.sourceId'
                    # else if scope.previewItem.lotId
                    #     watcher = 'previewItem.lotId'
                    # else if scope.previewItem.type == 'lot'
                    #     watcher = 'previewItem.id'
                    # else
                    #     watcher = 'previewItem.lotId'

                    # if watcher
                    #     scope.$watch watcher
                    #     , () ->
                    #         displayLotInfo()

                if currentParams.lotRepostInfo and item.type in currentParams.lotRepostInfo
                    flow = new AsyncFlow()

                    scope[item.type] = item
                    if item.type == 'post'
                        flow.add
                            name: 'getting lot'
                            action: (next) ->
                                if item.lotId
                                    lotService.getById item.lotId, (lot) ->
                                        scope.lot = lot
                                        scope.status = 'requestStatus'
                                        next()
                                else
                                    next()

                    if item.type == 'lot'
                        flow.add
                            name: 'getting post'
                            action: (next) ->
                                if item.postId
                                    postService.getById item.postId, (post) ->
                                        scope.post = post
                                        scope.status = 'socialNetwork'
                                        next()
                                else
                                    next()

                    flow.fire (res) ->
                        jElem.children('.lot-repost-info').remove()
                        if res
                            if !scope.post or !scope.lot then return false
                            if !scope.post.scheduled or !scope.post.onSale then return false
                            info = $compile('<div post="post" lot="lot" status="status" class="lot-repost-info"></div>')(scope.$new())
                            element.append info

            if item.name? and !attrs.noname? and item.type not in [ 'task', 'poll', 'file' ]
                jElem.children('.name').remove()
                name = item.name.substr(0, 40)
                if item.name.length > 40 then name += '...'
                element.append $compile('<div class="name bottom", ng-if="previewItem.name.length > 0">{{previewItem.name}}</div>')(scope)

            scope.builded = true

        scope.refreshItem = ->
            # element[0].innerHTML = ''

            if scope.item?
                return displayItem scope.item

            if scope.id? and scope.type?
                return operationsService.get scope.type, scope.id, displayItem

            if !scope.item?.id and !scope.id
                return element.addClass 'empty'

        scope.$watch 'id', (nVal) ->
            if nVal?
                operationsService.get scope.type, scope.id, displayItem

        if scope.item? and !scope.item?.type?
            unreg = scope.$watch 'item', (nVal) ->
                if nVal.type?
                    scope.refreshItem()
                    unreg()
            , true
        else
            scope.refreshItem()

        true

buzzlike.directive 'needWorkMark', (confirmBox, rpc, postService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        
        $ element
        .click ->
            post = scope.post or scope.item

            if post.needWork?

                toSet = if post.needWork == 'inprogress' then 'ready' else 'inprogress'

                confirmBox.init 
                    phrase: 'confirmBox_set_post_needWork_' + toSet
                    description: 'confirmBox_set_post_needWork_' + toSet + '_description'
                , () =>
                    # if toSet == 'ready'
                    #     rpc.call 'smartActions.acceptPostTasks', post.id
                        
                    # postService.save
                    #     id: post.id
                    #     needWork: toSet
                    postService.call 'setNeedWork',
                        postId: post.id
                        needWork: toSet

            scope.$apply()



