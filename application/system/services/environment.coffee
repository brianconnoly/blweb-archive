angular.module('buzzlike.environment', ['LocalStorageModule'])
    # .factory('user', (localization, httpWrapped, lotService, $location, $state, $http, localStorageService, env, res, $rootScope, communityService, smartDate, account, ruleService, requestService) ->

    #     lStorage = localStorageService

    #     @userId = null
    #     @userRole = null
    #     @authenticated = lStorage.get 'user.authenticated' ? true : false

    #     @env = env

    #     animPrefs =
    #         liveWp: if lStorage.get('user.liveWp') then true else false
    #         blurBg: if lStorage.get('user.blurBg') then true else false
    #         turbo: if lStorage.get('user.turbo') then true else false
    #         snow: if lStorage.get('user.snow') then true else false

    #     # if animPrefs.turbo
    #     #     topBar.toggle !animPrefs.turbo

    #     $rootScope.turbo = animPrefs.turbo

    #     firstDataLoad = () ->
    #         # res.getAccounts()
    #         # account.getSettings()

    #         # communityService.init()
    #         # communityService.loadCommunitiesList()
    #         # communityService.getGroups()

    #         # combService.init()
    #         # contentService.init()

    #         # postService.init()

    #         # ruleService.fetchMy()

    #         # lotService.init()
    #         # requestService.fetchFrom()
    #         # favouriteService.fetch()

    #         # Показать статы и опрос если стоит флаг

    #     onLogout = () ->
    #         #selectionService.setUserId null
    #         true

    #     onLoginCbs = []
    #     onLogoutCbs = []
    #     onLogin: (cb) ->
    #         if @authenticated == true
    #             cb? @userId
            
    #         onLoginCbs.push cb

    #     onLogout: (cb) ->
    #         onLogoutCbs.push cb

    #     animPrefs: animPrefs
    #     getAnimPrefs: () -> animPrefs

    #     setLiveBg: (val) ->
    #         animPrefs.liveWp = val
    #         lStorage.remove 'user.liveWp'
    #         lStorage.add 'user.liveWp', val

    #     setBlur: (val) ->
    #         animPrefs.blurBg = val
    #         lStorage.remove 'user.blurBg'
    #         lStorage.add 'user.blurBg', val

    #     setTurbo: (val) ->
    #         animPrefs.turbo = val
    #         $rootScope.turbo = val

    #         # topBar.toggle !val

    #         lStorage.remove 'user.turbo'
    #         lStorage.add 'user.turbo', val

    #     setSnow: (val) ->
    #         animPrefs.snow = val

    #         lStorage.remove 'user.snow'
    #         lStorage.add 'user.snow', val

    #     getId: () => @userId

    #     ###
    #     checkStatus: () =>
    #         if window.location.href.indexOf('front.dev.bl')>-1
    #             @userId = 1
    #             @userRole = 1
    #             @authenticated = true
    #             lStorage.add 'user.authenticated', true
    #         #return true

    #         $http({
    #             method: 'GET'
    #             url: env.authStatus
    #             withCredentials: true
    #         })
    #         .success (result) =>
    #             if result.err?
    #                 console.log result.err
    #             else
    #                 if result.data.authenticated
    #                     if result.data.userId != lStorage.get 'user.id'
    #                         lStorage.remove 'user.lang'
    #                         lStorage.remove 'user.nohints'
    #                         lStorage.remove 'user.timezone'
    #                         lStorage.add 'user.id', result.data.userId

    #                     authUser result.data
    #                 else
    #                     @authenticated = false
    #                     onLogout()
    #                     lStorage.remove 'user.authenticated'
    #                     if $state.current.name.indexOf('about') == -1
    #                         $location.path '/login'
    #         .error () =>
    #             if $state.current.name.indexOf('about') == -1
    #                 $location.path '/login'

    #         true
    #     ###

    #     isAuthenticated: () =>
    #         @authenticated

    #     login: (username, password, cb) =>
    #         if env == null
    #             cb
    #                 err: null
    #                 data: []
    #             @authenticated = true
    #             $location.path '/timeline'
    #             lStorage.add 'user.authenticated', true
    #             return false
    #         $http({
    #             method: 'POST'
    #             url: env.authLogin
    #             data:
    #                 'login': username
    #                 'password': password
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join "&"
    #             withCredentials: true
    #         })
    #         .success (resut) =>
    #             if !resut.err?
    #                 if resut.data.authenticated
    #                     authUser resut.data

    #             cb resut

    #         true

    #     logout: () =>
    #         $http({
    #             method: 'POST'
    #             url: env.authLogout
    #             data: ''
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
    #             withCredentials: true
    #         })
    #         .success (data) =>
    #             @authenticated = false
    #             $location.path '/login'
    #             lStorage.remove 'user.authenticated'

    #             $rootScope.detailsType = ''
    #             combService.purge()
    #             contentService.purge()
    #             lotService.purge()
    #             requestService.purge()
    #             #$rootScope.mediaplans = []

    #             onLogout()

    #             emptyObject account.user
    #             account.user.loaded = false
    #         .error () =>
    #             $location.path '/login'
    #         true

    #     register: (username, password, fn, ln, cb) =>
    #         $http({
    #             method: 'POST'
    #             url: env.register
    #             data:
    #                 'login': username
    #                 'password': password
    #                 'firstName': fn
    #                 'lastName': ln
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded;'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join "&"
    #             withCredentials: true
    #         })
    #         .success (result) =>
    #             if !result.err?
    #                 if result.data
    #                     console.log "success"
    #                     #$location.path '/timeline'
    #                     #lStorage.add 'user.authenticated', true
    #             else
    #                 console.log result.err
    #             cb result
    #         true

    #     resend: (username, cb) =>
    #         $http({
    #             method: 'POST'
    #             url: env.resend
    #             data:
    #                 login: username
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded;'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join "&"
    #             withCredentials: true
    #         })
    #             .success (result) =>
    #                 cb result
    #         true

    #     checkLoginAvailable: (username, cb) =>
    #         $http({
    #             method: 'GET'
    #             url: env.checkLoginAvailable + '?login=' + username
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded;'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join "&"
    #             withCredentials: true
    #         })
    #         .success (result) =>
    #             if !result.err?
    #                 if !result.data
    #                     console.log "Available"
    #             cb result
    #         true

    #     forgotPass: (username, cb) =>
    #         $http({
    #             method: 'GET'
    #             url: env.forgotPass + '?login=' + username
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded;'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join "&"
    #             withCredentials: true
    #         })
    #         .success (result) =>
    #             cb result
    #         true

    #     setOptions: (options, password) =>
    #         $http({
    #             method: 'POST'
    #             url: env.update
    #             data:
    #                 'firstName': options.firstName || ''
    #                 'lastName': options.lastName || ''
    #                 'password': password || ''
    #                 'timezone': options.timezone || ''
    #                 'frozen': options.frozen || ''
    #             headers:
    #                 'Content-Type': 'application/x-www-form-urlencoded;'
    #             transformRequest: (obj) ->
    #                 str = []
    #                 for k,v of obj
    #                     str.push encodeURIComponent(k) + "=" + encodeURIComponent(v)
    #                 str.join '&'
    #             withCredentials: true
    #         })
    #         .success (result) =>
    #             if !result.err?
    #                 if result.data
    #                     for i of options
    #                         account.user[i] = options[i]
    #                     account.user.name = ''
    #                     if options.firstName? then account.user.name += options.firstName
    #                     if options.lastName?  then account.user.name += ' ' + options.lastName
    #                     if !options.firstName&&!options.lastName then account.user.name = options.login
    #                     account.user.loaded = true
    #         true

    #     firstDataLoad: firstDataLoad

    # )
    .factory 'env', ($location, properties) ->

        fetchServerUrl = () ->
            loc = $location.host()

            baseurl = location.protocol

            # Production
            if loc == 'www.buzzlike.pro'
                baseurl += '//api.buzzlike.pro/'
                return baseurl

            # Alpha
            if loc == 'alpha.buzzlike.pro'
                console.log 'BuzzLike ALPHA environment is set'
                if baseurl == 'http:'
                    alphaUrl = localStorage.alphaUrl or '//api-alpha.buzzlike.pro:3000/'
                else
                    alphaUrl = localStorage.alphaUrl or '//api-alpha.buzzlike.pro/'
                baseurl += alphaUrl
                return baseurl

            # local
            if loc == 'front.int.bl'
                console.log 'BuzzLike local environment is set'
                baseurl += '//back.buzzlike.pro:5000/'
                return baseurl

            # local - prod
            if loc == 'prod.dev.bl'
                console.log 'BuzzLike local to PROD environment'
                baseurl = 'https://api.buzzlike.pro/'
                return baseurl

            # Beta
            if loc == 'beta.buzzlike.pro'
                console.log 'BuzzLike BETA environment'
                baseurl += '//api.buzzlike.pro/'
                return baseurl

            # Stage
            if loc == 'stage.buzzlike.pro'
                console.log 'BuzzLike STAGE environment'
                baseurl += '//api.buzzlike.pro/'
                return baseurl

            return baseurl

        baseurl = fetchServerUrl()

        if baseurl != null
            return {
                baseurl: baseurl

                version: baseurl + '/system/version'

                # Auth ctrl
                authStatus: baseurl + '/auth/status'
                authLogin: baseurl + '/auth/login'
                authLogout: baseurl + '/auth/logout'
                authConnect: baseurl + '/auth/connectWeb'
                addAccount: baseurl + '/auth/addAccount'
                register: baseurl + '/register'
                verify: baseurl + '/register/verify'
                update: baseurl + '/register/update'
                resend: baseurl + '/register/resend'
                checkLoginAvailable: baseurl + '/register/check/login'
                forgotPass: baseurl + '/register/recover/password'

                # Routs
                auth:
                    base: baseurl + '/auth'
                    acc: baseurl + '/settings/accounts'
                    login: baseurl + '/auth/snauth/login'
                    add: baseurl + '/auth/snauth/add'
                    update: baseurl + '/auth/snauth/update'

                upload:
                    base: 'upload.buzzlike.pro/upload'

                imageids:
                    base: baseurl + '/upload/images'

                imageUpload:
                    base: 'http://body.int.buzzlike.pro:5003/upload'

                groups:
                    base: baseurl + '/community/groups'

                feeds:
                    base: baseurl + '/community/list'
                    all: baseurl + '/community/list'

                commbyid:
                    base: baseurl + '/community/'

                schedule:
                    base: baseurl + '/schedule'
                    get: baseurl + '/schedule/get'
                    post: baseurl + '/schedule/post'
                    comb: baseurl + '/schedule/comb'

                comb:
                    base: baseurl + '/combs'

                post:
                    base: baseurl + '/posts'

                text:
                    base: baseurl + '/text'

                settings:
                    base: baseurl + '/settings'
                    migrationStatus: baseurl + '/settings/migrate/status'
                    migrationGo: baseurl + '/settings/migrate/go'

                payments:
                    account: baseurl + '/payments/account' #get


            }

        console.log 'Undefined environment'
        return null

    .factory 'res', (env, $http, $rootScope, contentService, postService, communityService) ->

        # AccountWork
        getAccounts: (cb) ->
            if env == null
                cb []
                return false

            $http({
                method: 'GET'
                url: env.auth.acc
                withCredentials: true
            })
            .success (data) ->
                if data.err == null
                    $rootScope.accounts = data.data
                    # tutorialService.setCourses()
                cb? data
