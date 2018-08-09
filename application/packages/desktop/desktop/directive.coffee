*deps: account, appsService, desktopService, buffer, notificationCenter, uploadService, tableImport, confirmBox, socketAuth, localization, stateManager

scope.sessions = appsService.sessions
scope.appsService = appsService
scope.desktopService = desktopService

scope.user = account.user

scope.notificationStatus = notificationCenter.status

appsService.setDesktopService desktopService

scope.apps = [
        app: 'help'
        name: 'Help'
        icon: '/resources/images/desktop/dock/white/help.svg'
        size:
            width: 900
            height: 600
            minWidth: 700
            minHeight: 300
    ,
        app: 'addFeed'
        name: 'Add feed'
        icon: '/resources/images/desktop/white/header-button-addTimeline.svg'
        noSave: true
        size:
            width: 682
            height: 600
            minWidth: 670
    ,
        app: 'socialImport'
        name: 'Social import'
        icon: '/resources/images/desktop/dock/white/import.svg'
        size:
            width: 800
            height: 600
    ,
        app: 'searchMedia'
        name: 'Search media'
        icon: '/resources/images/desktop/dock/white/search.svg'
        size:
            width: 688
            height: 600
    ,
        app: 'timeline'
        name: 'Timeline'
        icon: '/resources/images/desktop/dock/white/timelines.svg'
        size:
            width: 800
            height: 600
    ,
        app: 'content'
        name: 'Content'
        icon: '/resources/images/desktop/dock/white/materials.svg'
        size:
            width: 540
            height: 600
    ,
        app: 'combs'
        name: 'Combs'
        icon: '/resources/images/desktop/dock/white/themes.svg'
        size:
            width: 540
            height: 600
    ,
        app: 'market'
        name: 'Market'
        icon: '/resources/images/desktop/dock/white/market.svg'
        size:
            width: 624
            height: 730
            minWidth: 624
            minHeight: 560
    ,
        app: 'teamManager'
        name: 'Team manager'
        icon: '/resources/images/desktop/dock/white/teams.svg'
        size:
            width: 865
            height: 600
            minWidth: 865
            maxWidth: 865
    ,
        app: 'lotManager'
        name: 'Lot manager'
        icon: '/resources/images/desktop/dock/white/marketRequests.svg'
        size:
            width: 783
            height: 600
            minWidth: 783
            maxWidth: 783
            minHeight: 343
    ,
        app: 'ugcManager'
        name: 'UGC manager'
        icon: '/resources/images/desktop/dock/white/marketRequests.svg'
        size:
            width: 1000
            height: 600
            minWidth: 1000
            maxWidth: 1000
            minHeight: 343
    ,
        app: 'textEditor'
        name: 'Text editor'
        icon: '/resources/images/desktop/dock/white/text.svg'
        size:
            width: 400
            height: 500
    ,
        app: 'pollEdit'
        name: 'Poll editor'
        size:
            width: 400
            minWidth: 400
            maxWidth: 400
            height: 500
    ,
        app: 'importXLS'
        name: 'Import XLS'
        icon: '/resources/images/desktop/dock/white/xls.svg'
        startPosition: 'center'
        size:
            width: 380
            height: 170
            maxWidth: 380
            minWidth: 380
            minHeight: 170
            maxHeight: 170
    ,
        app: 'exportXLS'
        name: 'Export XLS'
        icon: '/resources/images/desktop/dock/white/xls.svg'
        startPosition: 'center'
        noSave: true
        size:
            width: 480
            height: 280
            maxWidth: 380
            minWidth: 380
            minHeight: 280
            maxHeight: 280
    ,
        app: 'moderation'
        name: 'Market moderation'
        size:
            width: 600
            height: 400
    ,
        app: 'callApi'
        name: 'Api testing tool'
        size:
            width: 600
            height: 500
    ,
        app: 'svgTunner'
        name: 'Svg tunner'
        size:
            width: 600
            height: 500
    ,
        app: 'notificationViewer'
        name: 'Notification viewer'
        icon: '/resources/images/desktop/dock/white/notify.svg'
        startPosition: 'center'
        size:
            width: 470
            height: 520
            maxWidth: 470
            minWidth: 470
            minHeight: 355
        noSnap: true
    ,
        app: 'settings'
        name: 'Buzzlike settings'
        icon: '/resources/images/desktop/actions/white/header-button-settings.svg'
        startPosition: 'center'
        size:
            width: 581
            height: 422
            minWidth: 501
            maxWidth: 742
            minHeight: 300
            maxHeight: 860
]

for app in scope.apps
    appsService.registerApp app

appsService.registerApp 
    app: 'combEdit'
    name: 'Тема'
    size:
        width: 800
        height: 600

appsService.registerApp 
    app: 'lotPreview'
    name: 'Лот'
    startPosition: 'center'
    noResize: true
    size:
        width: 568
        maxWidth: 568
        minWidth: 568
        height: 'auto'

appsService.registerApp 
    app: 'graph'
    name: 'Динамика'
    startPosition: 'cursor'
    # noResize: true
    size:
        width: 568
        minWidth: 568
        height: 400
        minHeight: 400

appsService.registerApp 
    app: 'mediaPreview'
    name: 'Просмотр'
    startPosition: 'center'
    size:
        width: 600
        height: 400

appsService.registerApp
    app: 'requestMaster'
    name: 'Заявка'
    startPosition: 'center'
    noResize: true
    noSave: true
    alwaysOnTop: true
    hideFromDock: true
    size:
        width: 590
        height: 540

appsService.registerApp
    app: 'postPicker'
    name: 'Post picker'
    startPosition: 'cursor'
    alwaysOnTop: true
    hideFromDock: true
    size:
        width: 263
        height: 420
        maxWidth: 263
        minWidth: 263
        minHeight: 210

appsService.registerApp
    app: 'calendar'
    name: 'Calendar'
    startPosition: 'cursor'
    noSave: true
    alwaysOnTop: true
    hideFromDock: true
    size:
        width: 228
        height: 310
        maxWidth: 228
        minWidth: 228
        maxHeight: 310
        minHeight: 310

appsService.registerApp
    app: 'ruleInspector'
    name: 'Rule inspector'
    startPosition: 'cursor'
    noSave: true
    alwaysOnTop: true
    hideFromDock: true
    size:
        width: 380
        height: 460
        maxWidth: 380
        minWidth: 380
        maxHeight: 460
        minHeight: 460

appsService.registerApp
    app: 'optionsList'
    name: 'Options list'
    noSave: true
    startPosition: 'center'
    alwaysOnTop: true
    hideFromDock: true
    size:
        width: 510
        height: 'auto'

appsService.registerApp
    app: 'paymentOffer'
    name: 'Payment offer'
    noSave: true
    startPosition: 'center'
    alwaysOnTop: true
    hideFromDock: true
    size: 
        width: 700
        height: 600

appsService.registerApp
    app: 'inviteUser'
    name: 'Invite user'
    noSave: true
    noResize: true
    startPosition: 'center'
    alwaysOnTop: true
    hideFromDock: true
    size: 
        width: 378
        height: 162
        maxHeight: 390

appsService.registerApp
    app: 'sendLogViewer'
    name: 'Send log viewer'
    startPosition: 'cursor'
    size: 
        width: 378
        height: 562

scope.menuClick = (e) ->
    if !desktopService.showMenu
        e?.stopPropagation?()
        desktopService.showMenu = true
        desktopService.subMenu = null

scope.launchApp = (app) ->
    desktopService.showMenu = false
    desktopService.subMenu = null
    desktopService.launchApp app

scope.newDesktop = () ->
    desktopService.showMenu = false
    desktopService.subMenu = null
    desktopService.newDesktop()

scope.activate = (desktop, session) ->
    if desktop != desktopService.currentDesktop
        desktopService.selectDesktop desktop

    if session?
        if session == appsService.activeSession and session.minimized != true
            appsService.hide session
        else
            appsService.activate session
    true

scope.logout = ->
    desktopService.showMenu = false
    desktopService.subMenu = null
    confirmBox.init
        phrase: 'popup_exit_title'
        description: 'popup_exit_subtitle'
        yes: localization.translate('popup_exit_confirm')
        no: localization.translate('morework')
    , () ->
        socketAuth.logout()

scope.isTiger = ->
    account.user.login.indexOf('tigermilk') > -1 or account.user.login.indexOf('socialist.pro') > -1 or account.user.login.indexOf('engagency.ru') > -1

# ======
scope.bufferWidth = 176
scope.showRight = ->
    buffer.toggleShow()
    true

scope.buffed = buffer

desktopService.init()

#
# Hot actions
#
scope.hotUpload = ->
    # uploadService.requestUpload()
    stateManager.callAction 'U',
        cmd: true
    true

scope.hotText = ->
    # desktopService.launchApp 'textEditor'
    stateManager.callAction 'V',
        cmd: true
    true

true