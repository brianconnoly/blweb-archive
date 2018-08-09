buzzlike.directive "searchMedia", (desktopService, rpc, importHelper, localization, httpWrapped, env, $rootScope, buffer, notificationCenter, stateManager, multiselect, contentService, overlayManager, resize) ->
    restrict: "C"
    link: (scope, element, attrs) ->

        elem = $ element
        input = elem.find 'input.url'

        scope.url = null

        scope.videoData = null
        scope.loading = false
        scope.thumbnail = '/resources/images/nwflw/link.png'

        scope.isCur = false

        urlsToSearch = ''

        scope.localization = localization
        scope.mediaList = []
        scope.audioList = []
        scope.imageList = []
        scope.linkList = []

        scope.ytlist = []
        scope.vklist = []

        scope.vkontakteCountItems = 0
        scope.vkontakteAudioCountItems = 0
        scope.youtubeCountItems = 0
        scope.isResized = false

        $rootScope.search_youtube = true
        $rootScope.search_vkontakte = true
        $rootScope.showHostings = true
        scope.search_vkaudio = false
        scope.search_url = false
        scope.search_video = true

        lastAudio = null
        countHost = 0
        mixVideoList = []
        scope.itemOffsetConstant = 20
        scope.itemCountConstant = 20
        itemOffset = 0
        lazyLoadingScrollTimer = {}
        lazyLoadingCount = 0
        scrollValue = 0
        spliceThis = false
        switchImportMode = {}

        scope.vkaudio_lastcount = 0
        scope.vkvideo_lastcount = 0
        scope.ytvideo_lastcount = 0

        scope.hasHTTPstring = false

        loadmoreClickHosting = null

        # для поиска видео - определям что это прямая ссылка видео или поисковый запрос
        re_search = /(https?\:\/\/)|(www\.)|(\.ru)|(\.com)|(\.org)|(\.net)/
        video_re_search = /(youtube.com\/watch)|(vk.com\/video)/

        oneurl = false
        scope.aloneurl = []

        scope.params =
            select: true
            close: true

        lazyLoading = false
        requestRun = false
        lazyEnd = false

        $rootScope.$watch 'search_youtube', (nVal) ->
            if nVal?
                scope.searchMedia()
        , true

        $rootScope.$watch 'search_vkontakte', (nVal) ->
            if nVal?
                scope.searchMedia()
        , true

        makeSpinner = () ->
            spinnerOptions =
                lines: 13
                length: 20
                width: 2
                radius: 30
                corners: 1
                rotate: 0
                direction: 1
                color: '#fff'
                speed: 1
                trail: 66
                shadow: true
                hwaccel: true
                className: 'spinner'
                zIndex: 2e9

            $('.spinner', $('.addVideoWrapper')).remove()
            $('.addVideoWrapper').append('<div class="spinner"></div>')
            target = $('.addVideoWrapper').find('.spinner')

            spinner = new Spinner(spinnerOptions).spin(target[0])

        resizeMediaList = ->
            # $('.scroll').each ->
            #     if $(this).find('li').length > 0
            #         $(this).css
            #             height: window.innerHeight - $('.scroll').offset().top - 40
            #     else
            #         $(this).css
            #             height: 0
            true
            
        searchAjax = (importUrl, urlsToSearch, type, contentType) ->
            if contentType == 'vkontakte_audio'
                if !lazyEnd

                    sendData =
                        searchString: urlsToSearch
                        offset: itemOffset
                        count: scope.itemCountConstant

                    requestRun = true
                    #httpWrapped.post importUrl, sendData, (data) ->
                    rpc.call 'import.query',
                        provider:   importUrl.provider
                        count:      sendData.count
                        offset:     sendData.offset
                        query:      sendData.searchString
                    , (data) ->

                        scope.vkaudio_lastcount = data.length

                        for item in data
                            if item?
                                item.hosting = 'vkaudio'
                                scope.vkontakteAudioCountItems++
                                scope.audioList.push item

                        $('.videoLists .videoList').transition
                            'opacity': 1
                        , 300

                        setTimeout ->
                            # Чтобы окно пересчитало высоту
                            resizeMediaList()
                            updateHostingLabels()
                        , 400

                        lazyLoading = false
                        requestRun = false
                        if data.length == 0
                            lazyEnd = true

                        if loadmoreClickHosting
                            elmHosting = $('.vkaudio')
                            setTimeout ->
                                # height = elmHosting.find('ul').height()
                                # $('.videoList .scroll').animate
                                #     scrollTop: height - 190
                                # , 500
                                updateHostingLabels()
                            , 700

                        loadmoreClickHosting = null

                        # if lazyLoadingCount >= 1 and spliceThis and data.length > 0
                        #     console.log scope.audioList.length
                        #     scope.audioList.splice 0, 200
                        #     console.log scope.audioList.length


                        $('.addVideoWrapper').find('.spinner').hide()


            else
                if contentType == 'urlsearch'
                    if urlsToSearch.indexOf(',') == -1
                        urlsToSearch = [getUrlFormat(urlsToSearch)]
                    else
                        urlsToSearchTmp = urlsToSearch.split(',')
                        urlsToSearch = []
                        for url in urlsToSearchTmp
                            urlsToSearch.push getUrlFormat(url)


                    sendData = urlsToSearch
                else if contentType == 'videourl'
                    sendData = urlsToSearch
                else
                    sendData =
                        searchString: urlsToSearch
                        offset: itemOffset
                        count: scope.itemCountConstant

                if !lazyEnd
                    #httpWrapped.post importUrl, sendData, (data) ->
                    rpc.call 'import.query',
                        provider:   importUrl.provider
                        urls:       urlsToSearch
                        count:      sendData.count
                        offset:     sendData.offset
                        query:      sendData.searchString
                    , (data) ->
                        if oneurl
                            scope.aloneurl = data[0]
                            scope.saveMedia(true)
                            oneurl = false
                            scope.aloneurl = []
                        else if contentType == 'urlsearch'
                            isTypeImage = false
                            for item in data
                                if item.type == 'image'
                                    scope.imageList.push item
                                    changeType 'image'
                                    isTypeImage = true
                                else
                                    if !item.title?
                                        item.title = ''
                                    scope.linkList.push item
                                    if !isTypeImage
                                        changeType 'link'
                        else
                            # console.log type, contentType

                            if contentType == 'youtubeVideo'
                                scope.ytvideo_lastcount = data.length
                            if contentType == 'vkVideo'
                                scope.vkvideo_lastcount = data.length

                            for item in data
                                if item?
                                    if contentType? and contentType != 'videourl'
                                        item.hosting = contentType
                                        if contentType == 'vkVideo'
                                            item.hostingShortname = 'vk'
                                            scope.vkontakteCountItems++
                                        if contentType == 'youtubeVideo'
                                            item.hostingShortname = 'yt'
                                            scope.youtubeCountItems++
                                    else
                                        item.hosting = item.sourceType
                                        if item.sourceType == 'vkVideo'
                                            item.hostingShortname = 'vk'
                                            scope.vkontakteCountItems++
                                        if item.sourceType == 'youtubeVideo'
                                            item.hostingShortname = 'yt'
                                            scope.youtubeCountItems++


                                    if item.hostingShortname == 'vk'
                                        scope.vklist.push item
                                    if item.hostingShortname == 'yt'
                                        scope.ytlist.push item


                        $('.videoLists .videoList').transition
                            'opacity': 1
                        , 300

                        setTimeout ->
                            # Чтобы окно пересчитало высоту
                            resizeMediaList()
                            updateHostingLabels()
                        , 400

                        lazyLoading = false
                        requestRun = false
                        if data.length == 0
                            lazyEnd = true

                        if loadmoreClickHosting
                            elmHosting = $('.'+loadmoreClickHosting+'video')
                            setTimeout ->
                                # height = elmHosting.find('ul').height()
                                # $('.videoList .scroll').animate
                                #     scrollTop: height - 190
                                # , 500
                                updateHostingLabels()
                            , 700

                        loadmoreClickHosting = null

                        $('.addVideoWrapper').find('.spinner').hide()

                        true

        rebuildTextarea = () ->
            textareaValue = ''
            resultUrls = []
            urlsToSearch = ''

            if re_search.test(scope.url)
                urls = scope.url.split(/[\,\;\s+]/g)
                for url in urls
                    url = $.trim(url)
                    if url != '' and url != undefined and url != ';' and url != ',' and url != '\n'
                        resultUrls.push url
                        urlsToSearch += url+','
                        textareaValue += url + '\n'

                if urlsToSearch != ''
                    urlsToSearch = urlsToSearch.substr(0,urlsToSearch.length-1)

                if resultUrls.length > 1
                    scope.isResized = true
                else
                    scope.isResized = false

                scope.url = textareaValue
            else
                urlsToSearch = scope.url

        sendSearch = (e) ->
            if e.keyCode == 13
                if (e.ctrlKey || e.metaKey)
                    scope.resizeTextarea(true)
                    resizeMediaList()
                    updateHostingLabels()
                else
                    e.preventDefault()
                    scope.searchMedia()

        lazyLoadingMedia = (e) ->
            elm = $(e.target)
            if elm.scrollTop() > scrollValue
                spliceThis = true
            else
                spliceThis = false

            scrollValue = elm.scrollTop()

            if elm.length > 0
                halfHeightOfScroll = elm.scrollTop() + elm.height()

                if elm.scrollTop() == 0 and halfHeightOfScroll > elm[0].scrollHeight / 2
                    lazyLoading = true

                if halfHeightOfScroll > elm[0].scrollHeight / 2 and !requestRun and !scope.search_url
                    if !lazyLoading
                        lazyLoading = true
                        itemOffset += scope.itemOffsetConstant
                        scope.searchMedia(itemOffset)
                        lazyLoadingCount++

        uploadedNotificationMessage = (types) ->
            notificationText = ''

            if types.length > 1
                notificationText = 'addVideo_contentimported'
            else
                if types[0] == 'video'
                    notificationText = 'addVideo_videoimported'
                if types[0] == 'audio'
                    notificationText = 'addVideo_audioimported'
                if types[0] == 'url'
                    notificationText = 'addVideo_urlimported'
                if types[0] == 'image'
                    notificationText = 'addVideo_imageimported'

            notificationText


        openSelectSearchType = ->
            if $(this).height() < 400
                $(this).css
                    height: 400

        changeType = (type) ->

            hasType = false
            if typeof type == 'string'
                hasType = true

            if $(this).attr('option')? and !$(this).hasClass('selected') || hasType

                if hasType
                    optionVal = type
                else
                    optionVal = $(this).attr('option')

                elm = $('.selectSearchType').children('.selected')
                elm.removeClass().addClass('selected type ' + optionVal+'Type')

                switch optionVal
                    when 'video'
                        scope.search_video = true
                        scope.search_vkaudio = false
                        scope.search_url = false
                        $rootScope.showHostings = true
                    when 'image'
                        scope.search_video = false
                        scope.search_vkaudio = false
                        scope.search_url = true
                        $rootScope.showHostings = false
                    when 'link'
                        scope.search_video = false
                        scope.search_vkaudio = false
                        scope.search_url = true
                        $rootScope.showHostings = false
                    when 'audio'
                        scope.search_video = false
                        scope.search_vkaudio = true
                        scope.search_url = false
                        $rootScope.showHostings = false

                if !$rootScope.showHostings
                    $('.hostingLabels').hide()
                else
                    $('.hostingLabels').show()

                setTimeout ->
                    $('.selectSearchType').css
                        height: 80
                , 10

        # Поиск медиа
        scope.searchMedia = (offset, hosting) ->
            if !offset?
                itemOffset = 0
            # rebuildTextarea()
            placeholderText = $('.searchMediaUrl').attr('placeholder')
            if $.trim(scope.url) != '' and scope.url.replace(/<.+?>/gi,'') != placeholderText and (scope.search_vkaudio || scope.search_video || scope.search_url)

                urlsToSearch = scope.url.replace(/<.+?>/g,' ')
                urlsToSearch = urlsToSearch.replace(/\s+/,' ')
                urlsToSearchArr = urlsToSearch.split(' ')
                urlsToSearch = ''

                for item in urlsToSearchArr
                    if item?
                        item = $.trim(item)
                        if item != ''
                            urlsToSearch += item + ','

                if urlsToSearch != ''
                    urlsToSearch = urlsToSearch.substr(0,urlsToSearch.length-1)

                if urlsToSearch != ''

                    if itemOffset == 0
                        # Создаем spinner пока идет поиск
                        makeSpinner()
                        # $('.addVideo').find('.spinner').show()

                        # Убираем старые результаты поиска
                        $('.videoLists .videoList').transition
                            'opacity': 0
                        , 300

                        multiselect.flush()

                    if itemOffset == 0
                        scope.vklist = []
                        scope.ytlist = []
                        scope.mediaList = []
                        scope.audioList = []
                        scope.imageList = []
                        scope.linkList = []
                        scope.vkontakteCountItems = 0
                        scope.vkontakteAudioCountItems = 0
                        scope.youtubeCountItems = 0
                        lazyEnd = false

                    importUrl = []
                    oneurl = false
                    scope.aloneurl = []
                    searchType = ''

                    # это отстой а не условие, by Phil
                    if hosting?
                        yt = false
                        vk = false
                        vkaudio = false
                        video = false

                        if hosting == 'yt'
                            yt = true
                            video = true
                        if hosting == 'vk'
                            vk = true
                            video = true
                        if hosting == 'vkaudio'
                            vkaudio = true
                            vk = true
                            video = false

                        searchList =
                            video: video
                            youtube: yt
                            vkontakte: vk
                            vkaudio: vkaudio
                            url: false

                    else
                        searchList =
                            video: scope.search_video
                            youtube: $rootScope.search_youtube
                            vkontakte: $rootScope.search_vkontakte
                            vkaudio: scope.search_vkaudio
                            url: scope.search_url

                    countHost = 0
                    mixVideoList = []
                    scope.hasHTTPstring = false

                    setTimeout ->
                        # Если это ссылка, то отправляем запросы на другой url
                        if video_re_search.test(urlsToSearch)
                            importUrl = env.baseurl + "/import/videos"

                            if urlsToSearch.indexOf(',') == -1
                                oneurl = true

                            scope.search_vkaudio = false
                            scope.search_video = true
                            scope.search_url = false

                            urls = urlsToSearch.split ','

                            searchAjax 
                                provider: 'videoUrl'
                            , urls, 'string', 'videourl'
                            changeType 'video'
                            scope.hasHTTPstring = true
                        else if re_search.test(urlsToSearch) and scope.search_url == false
                            if urlsToSearch.indexOf(',') == -1
                                oneurl = true

                            scope.search_vkaudio = false
                            scope.search_video = false
                            scope.search_url = true

                            searchAjax 
                                provider: 'picUrl'
                            , urlsToSearch, 'string', 'urlsearch'
                        else
                            for key,value of searchList
                                if value
                                    switch key
                                        when 'youtube'
                                            if searchList.video
                                                importUrl.push
                                                    provider: 'youtubeVideo'
                                                    link: env.baseurl + "/import/videos/search/youtube"
                                                    type: 'youtubeVideo'
                                        when 'vkontakte'
                                            if searchList.video
                                                importUrl.push
                                                    provider: 'vkVideo'
                                                    link: env.baseurl + "/import/videos/search/vkontakte"
                                                    type: 'vkVideo'
                                        when 'vkaudio'
                                            if searchList.vkontakte
                                                importUrl.push
                                                    provider: 'vkAudio'
                                                    link: env.baseurl + "/social/vk/audio/search"
                                                    type: 'vkontakte_audio'
                                        when 'url'
                                            importUrl.push
                                                provider: 'picUrl'
                                                link: env.baseurl + "/import/url"
                                                type: 'urlsearch'

                            if importUrl.length > 0
                                for item in importUrl
                                    searchAjax item, urlsToSearch, 'array', item.type
                            else
                                resizeMediaList()
                                $('.addVideoWrapper').find('.spinner').hide()
                    , 300

        scope.isVideoSelected = (video) ->
            video.selected == true

        scope.resizeTextarea = (keypress) ->
            if scope.url.indexOf('\n') > -1 || keypress
                scope.isResized = true
            else
                scope.isResized = false

        scope.saveMedia = (force) ->

            if $('.selectableItem.selected', $('.videoLists')).length == 0 and !force?
                return false

            contentTypes = []

            if oneurl
                item = scope.aloneurl

                newItem = $.extend {}, item
                delete newItem.id

                rpc.call 'import.import', newItem, (importedItem) ->
                #contentService.create newItem, (item) ->
                    item = contentService.handleItem importedItem

                    if scope.params.select
                          buffer.addItems [item]

                    if $.inArray(item.type, contentTypes) == -1
                        contentTypes.push item.type

                    notificationCenter.addMessage
                        text: uploadedNotificationMessage(contentTypes)
            else
                allItems = $('.selectableItem.selected', $('.videoLists'))
                allItemsCount = allItems.length
                i = 0
                allItems.each (key, value) ->
                    item = angular.element(value).scope().item
                    if $.inArray(item.type, contentTypes) == -1
                        contentTypes.push item.type

                    newItem = $.extend {}, item
                    delete newItem.id

                    rpc.call 'import.import', newItem, (importedItem) ->
                    #contentService.create newItem, (item) ->
                        item = contentService.handleItem importedItem
                        
                        if scope.params.select
                                buffer.addItems [item]

                        if i == allItemsCount-1
                            allItems.removeClass('selected')
                            multiselect.flush()

                            notificationCenter.addMessage
                                text: uploadedNotificationMessage(contentTypes)
                        i++

            if scope.params.close
                overlayManager.unloadOverlay 'importMedia'
                stateManager.goBack()

            # tutorialService.nextLesson('contentsearch', [5])

            true

        scope.itemClick = (item) ->
            desktopService.launchApp 'mediaPreview',
                contentId: item.id
            true

        scope.clear = () ->
            scope.url = ''

            scope.videoData = null
            scope.loading = false
            scope.thumbnail = 'https://cdn1.iconfinder.com/data/icons/windows-8-metro-style/512/link.png'

            input.focus()

        scope.search_onlyurl = () ->
            scope.search_video = false
            scope.search_vkaudio = false
            scope.mediaList = []
            scope.audioList = []

        scope.search_withouturl = () ->
            scope.search_url = false

            placeholderText = $('.searchMediaUrl').attr('placeholder')
            if $.trim(scope.url) != '' and scope.url.replace(/<.+?>/gi,'') != placeholderText
                selectElementContents($('.searchMediaUrl')[0])

        scope.openAudioPlayer = (item) ->

            $(document.body).find('audio').remove()
            if item != lastAudio
                $(document.body).append("<audio src='#{item.source}' autoplay loop></audio>")

            lastAudio = item
            if $(document.body).find('audio').length == 0
                lastAudio = null

        scope.switchHostingFilter = ($event) ->
            ngModelName = $(event.target).attr('ng-model')
            if scope[ngModelName]
                scope[ngModelName] = false
            else
                scope[ngModelName] = true

            clearTimeout switchImportMode
            switchImportMode = setTimeout ->
                if $.trim(scope.url) != ''
                    scope.searchMedia()
            , 1000

        scope.loadmore = (hosting) ->
            if !lazyLoading
                lazyLoading = true
                loadmoreClickHosting = hosting

                # Youtube считает первую пачку с 1, поэтому нужно сделать +1
                if itemOffset > 0
                    itemOffset += scope.itemOffsetConstant
                else
                    if hosting == 'yt'
                        itemOffset += scope.itemOffsetConstant+1
                    else
                        itemOffset += scope.itemOffsetConstant

                scope.searchMedia(itemOffset, hosting)
                lazyLoadingCount++

        updateHostingLabels = ->
            if $('.hostingLabels').length > 0
                angular.element($('.hostingLabels')).scope().updateLabels()

        blurSearch = ->
            if $.trim($(this).text()) == ''
                $(this).html('')

        addVideoClick = (e) ->
            if !$(e.target).hasClass('selectSearchType') and $(e.target).parents('.selectSearchType').length == 0
                $('.selectSearchType').css
                    height: 80

        init = ->
            $(element).on 'keydown', '.searchMediaUrl', sendSearch
            $(element).on 'blur', '.searchMediaUrl', blurSearch
            $(element).find('.selectSearchType').on 'click', openSelectSearchType
            $(element).find('.selectSearchType .type').on 'click', changeType
            $(element).on 'mousewheel', updateHostingLabels
            $(element).on 'click', addVideoClick
            setTimeout ->
                $('.searchMediaUrl').focus()
            , 500
        init()

        resize.registerCb resizeMediaList