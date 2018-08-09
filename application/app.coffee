authHash = window.location.hash.split('#')[1]
window.location.hash = ""

buzzlike = angular.module( 'buzzlike', ['ngSanitize', 'ngAnimate', 'buzzlike.environment', 'luegg.directives'] )
    .config( ($locationProvider) ->
        # $locationProvider.html5Mode(true)
    )

    .run (loginService, tableImport, uploadService, actionsRegister, buffer, timezone, localStorageService, socketNotify, requestService, favouriteService, lotService, groupService, postService, socketAuth, rpc, resize, $animate, account, touchHelper, $rootScope, $location, env, contentService, userService, combService, scheduleService, localization, stateManager, desktopState, httpWrapped, $filter) ->

        # window.dmp = new diff_match_patch()

        socketAuth.onAuth () ->

            $rootScope.user = account.user

            buffer.readState()

            groupService.get () ->
                $rootScope.$apply()

            lotService.fetchMy()
            favouriteService.fetchMy()
            requestService.fetchNew()

        #
        window.rpc = rpc
        window.filter = $filter

        #sprites preloader
        basePath = location.origin+'/resources/images/icons/'
        if !window.sprites
            window.sprites = ['inspector-handler', 'inspector_chain', 'inspector_chain_cur', 'inspector_close', 'inspector_daily', 'inspector_single', 'inspector_single_cur']

        if window.mediaCache?.length > 0
            for sprite in window.mediaCache
                $('<img>')[0].src = sprite #basePath+sprite+'.png'
                # $('<img>')[0].src = basePath+sprite+'@2x.png'

        #Put Localization service in $rootScope
        $rootScope.localization = localization
        $rootScope.translate = localization.translate

        $rootScope.postLen = 1

        # Global makeArray helper
        $rootScope.makeArray = makeArray
        $rootScope.humanizeDays = humanizeDays

        $rootScope.makePaginatorFromPages = ( pages, currentPage = null, size = 9) ->
            if !pages? then return []
            pages = pages.length or pages
            makePaginator pages, currentPage, size

        $rootScope.makePaginator = (ids, currentPage = null, size = 5, perPage = 5) ->
            if !ids? then return []

            num = Math.ceil(ids.length / perPage)
            makePaginator num, currentPage, size

        makePaginator = (num, currentPage, size) ->
            start = 0
            end = num

            if currentPage != null and num > size*2+1
                start = currentPage - size
                end = currentPage + size + 1

                if start < 0
                    end -= start
                    start = 0

                if end > num
                    start -= end - num
                    end = num

            if end < start
                return [currentPage]

            for i in [start...end]
                i

        $rootScope.makeArrayByFromTo = (from, to) ->
            for c in [from...to+1]
                c

        $rootScope.getCheckAfter = (val) ->
            if val < 1
                return ''

            hours = 0
            mins = 0
            # get hours
            if val > HOUR
                hours = val / HOUR | 0

            # get minutes
            mins = ( val - (hours * HOUR) ) / MIN | 0

            result = ''
            if hours > 0
                result += hours + ' ч.'

            if mins > 0
                result += ' ' if result != ''
                result += mins + ' мин.'

            result

        $rootScope.currentState = null

        # Global entities collections
        socketAuth.onLogout ->
            groupService.purge()
            account.purge()
            combService.purge()
            contentService.purge()
            true

        $rootScope.getSource = (item) -> item.sourceType.substring(0,2).toUpperCase()
        $rootScope.priceTag = (notify) -> if notify.buzzLot == true then 'д.' else 'р.'

        simpleCache = {}
        $rootScope.simpleNumber = (number) ->
            if simpleCache[number]?
                return simpleCache[number]

            if number >= 1000000
                simpleCache[number] = Math.round(number / 1000000) + 'm'

            else if number >= 1000
                simpleCache[number] = Math.round(number / 1000) + 'k'
            else
                simpleCache[number] = number | 0

            return simpleCache[number]

        $rootScope.getUserIdent = (user) ->
            if user.login?
                return user.login
            if user.accounts.length > 0
                acc = user.accounts[0]
                switch acc.socialNetwork
                    when 'ok'
                        return 'ok.ru/' + account.screenName or account.publicId
                    when 'vk'
                        return 'vk.com/' + account.screenName or account.publicId
                    when 'mm'
                        return 'my.mail.ru/' + account.screenName or account.publicId
                    when 'fb'
                        return 'facebook.com/' + account.screenName or account.publicId
                    when 'yt'
                        return 'youtube.com/' + account.screenName or account.publicId
            else
                return localization.translate 'unknown_user'
        # =========== #
        #  Dev stuff  #
        # =========== #
        window.cleanLS = ->
            for i of localStorage
                delete localStorage[i]

        window.cleanCookie = ->
            popup = window.open(env.baseurl)
            popup.document.cookie = ''
            popup.close()

        window.clean = ->
            cleanLS()
            cleanCookie()

        window.setVar = (key, value) ->
            localStorageService.add key, value

        window.$RS = $rootScope

        $rootScope.proxyPrefix = window.proxyPrefix
        $rootScope.proxyImage = (url) ->
            if !url or url[0]=='/' or url.substr(0,5)=='https' then return url
            $rootScope.proxyPrefix + url

        window.__pholderHelper = $ '<div>',
            class: 'placeholder previewContainer'
            id: '__pHolderHelper'
        window.__pholderIndex = -1
