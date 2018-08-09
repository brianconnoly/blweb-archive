*deps: rpc, account, contentService, postService, socketAuth, socketService, loginService, localization, $rootScope, $compile, uploadService, tableImport

elem = $ element
loginContainer = elem.children('.loginContainer')
desktopContainer = elem.children('.desktopContainer')
current = null

# Watch connection status
scope.$watch ->
    socketService.state.connected
, (nVal, oVal) ->
    if nVal == false and oVal == true
        elem.addClass 'disconnected'

    if nVal == true
        elem.removeClass 'disconnected'

loginScope = null
buildLogin = (cb) ->
    loginScope = $rootScope.$new()
    loginElem = $compile('<div class="loginScreen"></div>')(loginScope)
    loginContainer.append loginElem
    setTimeout ->
        cb true
    , 0
destroyLogin = ->
    if loginScope?
        loginScope.$destroy()
        loginScope = null
        loginContainer.empty()

desktopScope = null
buildDesktop = (cb) ->
    desktopScope = $rootScope.$new()
    desktopElem = $ '<div class="desktop"></div>'
    desktopContainer.append desktopElem
    $compile(desktopElem)(desktopScope)
    setTimeout ->
        cb true
    , 0

buildNova = (cb) ->
    desktopScope = $rootScope.$new()
    desktopElem = $ '<div class="nova"></div>'
    desktopContainer.append desktopElem
    $compile(desktopElem)(desktopScope)
    setTimeout ->
        cb true
    , 0
destroyDesktop = ->
    if desktopScope?
        desktopScope.$destroy()
        desktopScope = null
        desktopContainer.empty()

window.goNova = ->
    if current != 'desktop'
        return

    desktopContainer.removeClass 'active'
    setTimeout ->
        destroyDesktop()
        buildNova ->
            setTimeout ->
                desktopContainer.addClass 'active'
            , 800
    , 800

window.goDesktop = ->
    if current != 'desktop'
        return

    desktopContainer.removeClass 'active'
    setTimeout ->
        destroyDesktop()
        buildDesktop ->
            setTimeout ->
                desktopContainer.addClass 'active'
            , 800
    , 800

# Watch session authed
startSessionWatcher = ->
    scope.$watch ->
        # socketAuth.session.authed
        account.user.id
    , (nVal, oVal) ->
        loginService.state.mode = 'wait'

        if nVal? and nVal != -1 # == true
            if current != 'desktop'
                # deskFunc = buildDesktop
                # if socketAuth.session.user_id == "5442412ddff4f59a207a0414"
                deskFunc = buildNova

                deskFunc ->
                    # Show desktop
                    desktopContainer.addClass 'visible'

                    if current == 'login'
                        # Hide login
                        loginContainer.removeClass 'active'
                        setTimeout ->
                            loginContainer.addClass 'left'
                            desktopContainer.removeClass 'right'

                            setTimeout ->
                                desktopContainer.addClass 'active'
                                loginContainer.removeClass 'visible'
                                destroyLogin()
                            , 800
                        , 500
                    else
                        loginContainer.addClass 'left'
                        desktopContainer.addClass 'noAnim'
                        setTimeout ->
                            desktopContainer.removeClass 'right'
                        , 0
                        setTimeout ->
                            desktopContainer.addClass 'active'
                            desktopContainer.removeClass 'noAnim'
                        , 500

                    current = 'desktop'
                true
        else
            loginService.state.mode = 'default'

            if current != 'login'
                desktopContainer.removeClass 'active'
                buildLogin ->
                    # Show login
                    loginContainer.addClass 'visible'

                    if current == 'desktop'
                        # Hide login
                        setTimeout ->
                            desktopContainer.addClass 'right'
                            loginContainer.removeClass 'left'

                            setTimeout ->
                                loginContainer.addClass 'active'
                                desktopContainer.removeClass 'visible'
                                destroyDesktop()
                            , 800
                        , 500
                    else
                        setTimeout ->
                            loginContainer.removeClass 'left'
                            loginContainer.addClass 'active'
                        , 500

                    current = 'login'
                true

seq = new Sequence
    name: 'Bootloader'

seq.addStep
    name: 'Legacy init'
    action: (next) ->
        contentService.initDeps()
        postService.initDeps()
        next true

seq.addStep
    name: 'Init language'
    async: true
    action: (next) ->
        localization.getLang()
        localization.getFreshList()
        next true

seq.addStep
    name: 'Init socket'
    async: true
    action: (next) ->
        $('#loadingStatus').html 'Получение сессии'
        $('#loadingProgress').css 'width', '20%'
        socketAuth.init next

seq.addStep
    name: 'Auth token'
    check: -> authHash?.length > 10
    action: (next) ->
        rpc.call 'auth.authToken', authHash, socketAuth.processSession
        next true

seq.addStep
    name: 'Load config'
    retry: 5
    var: 'settings'
    action: (next) ->
        $('#loadingProgress').css 'width', '30%'
        $('#loadingStatus').html 'Загрузка конфигурации'
        rpc.call
            method: 'settings.get'
            anyway: next

seq.addStep
    name: 'Store core settings'
    action: (next) ->
        $rootScope.coreSettings = seq.settings
        next true

seq.addStep
    name: 'Init login providers'
    retry: 5
    action: (next) ->
        $('#loadingProgress').css 'width', '50%'
        $('#loadingStatus').html 'Загрузка конфигурации'
        loginService.init next

seq.addStep
    name: 'Wait localization'
    action: (next) ->
        $('#loadingProgress').css 'width', '80%'
        $('#loadingStatus').html 'Подготовка локализации'
        localization.onLangLoaded next

seq.addStep
    name: 'Complete initialization'
    action: (next) ->
        $('#loadingProgress').addClass 'full'
        $('#loadingStatus').html ''

        $('body').addClass 'noBigLoading'
        setTimeout ->
            $('#big_loading').remove()
        , 5000

        next true

seq.fire ->
    startSessionWatcher()
    true

# Multi file uploader by dialog
$('.uploadHelper input').on 'change', (e) ->
    uploadService.upload @, true
    $(@).val ''

# CSV / XLS import
$('#importFullHelper').on 'change', (e) ->
    tableImport.uploadFull @
    $(@).val ''

$('#importCommunityHelper').on 'change', (e) ->
    tableImport.uploadCommunity @
    $(@).val ''
