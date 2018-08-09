*deps: $compile, novaAppStateSaver, operationsService, novaMenu
*replace: true

# ===================
# Globals
elem = $ element
domElem = elem[0]
elem.addClass 'black'
scope.stateSaver = new novaAppStateSaver scope.session.id
elem.on 'click', (e) ->
    novaMenu.hide()
    
# ===================
# Store app item
# scope.stateSaver.register 'item',
#     save: ->
#         type: scope.session.item.type
#         id: scope.session.item.id
#     load: (data) ->
#         scope.session.item = data
if scope.session.item?
    elem.addClass scope.session.item.type + '_' + scope.session.item.id
    scope.appItem = operationsService.get scope.session.item.type, scope.session.item.id
# ===================
# App methods
scope.closeApp = ->
    scope.session.closing = true
    elem.addClass('hideAnimationStart')
    setTimeout =>
        elem[0].style.transform += ' scale(0.9)'
        elem.addClass('hideAnimation')
        setTimeout =>
            scope.desktop.closeApp scope.session
            scope.$applyAsync()
        , 500
    , 0
    checkMaximized()

scope.setWidth = (wid, noSave = false) ->
    if scope.session.maxWidth? and wid > scope.session.maxWidth
        wid = scope.session.maxWidth
    if scope.session.minWidth? and wid < scope.session.minWidth
        wid = scope.session.minWidth
    scope.session.size.width = wid if wid?
    #elem.css 'width', scope.session.size.width
    if !scope.session.maximize
        domElem.style.width = scope.session.size.width + 'px'
    if !noSave
        scope.stateSaver.save 'size'

scope.setHeight = (hei, noSave = false) ->
    if scope.session.maxHeight? and hei > scope.session.maxHeight
        hei = scope.session.maxHeight
    if scope.session.minHeight? and hei < scope.session.minHeight
        hei = scope.session.minHeight
    scope.session.size.height = hei if hei?
    #elem.css 'height', scope.session.size.height
    if !scope.session.maximize
        domElem.style.height = scope.session.size.height + 'px'
    if !noSave
        scope.stateSaver.save 'size'

scope.setSize = (wid, hei, noSave = false) ->
    scope.setWidth wid, true
    scope.setHeight hei, true
    if !noSave
        scope.stateSaver.save 'size'

scope.setPosition = (x, y, noSave = false) ->
    y = -10 if y? and y < -10
    scope.session.position.x = x if x?
    scope.session.position.y = y if y?
    if !scope.session.maximize
        elem.css 'transform', 'translate3d(' + scope.session.position.x + 'px,' + scope.session.position.y + 'px, 0)'
    if !noSave
        scope.stateSaver.save 'position'

checkMaximized = ->
    found = false
    for app in scope.desktop.apps
        found = true if app.maximize == true and app.minimize != true and app.closing != true

    if found
        $('body').addClass 'maximized'
    else
        $('body').removeClass 'maximized'

    true

scope.minimize = (data, noSave) ->
    if !data?
        data = true
    scope.session.minimize = data
    if data
        elem.css 'display', 'none'
    else
        elem.css 'display', 'block'
        scope.resized elem.width(), elem.height()

    if !noSave
        scope.stateSaver.save 'minimize'

    checkMaximized()

scope.noMaximize = ->
    elem.find('.maximizeControl').remove()
scope.maximize = (data, noSave = false) ->
    if !data?
        data = !scope.session.maximize

    scope.session.maximize = data
    if data
        elem.css
            'transform': 'none'
            'top': -2
            'left': -2
            'bottom': 0
            'right': -2
            'width': 'auto'
            'height': 'auto'
        .addClass 'maximized'
    else
        elem.css
            'transform': 'translate3d(' + scope.session.position.x + 'px,' + scope.session.position.y + 'px, 0)'
            'top': 'auto'
            'left': 'auto'
            'bottom': 'auto'
            'right': 'auto'
            'width': scope.session.size.width
            'height': scope.session.size.height
        .removeClass 'maximized'

    if !noSave
        scope.stateSaver.save 'maximize'

    checkMaximized()

    scope.resized elem.width(), elem.height()
    true

# ===================
# Window resize
resizeHandlers = []
scope.onResize = (handler, fire = true) ->
    if fire == true
        handler scope.session.size.width, scope.session.size.height
    resizeHandlers.push handler

scope.resized = (wid, hei) ->
    for handler in resizeHandlers
        handler wid, hei

# App focus
focusHandlers = []
scope.onFocus = (handler) ->
    focusHandlers.push handler
scope.session.activated = ->
    if scope.session.minimize == true
        scope.minimize false

    for handler in focusHandlers
        handler()

resizeProgressHandlers = []
scope.progressHandlers = []
scope.onResizeProgress = (handler, fire = true, onlyProgress = false, name) ->
    if fire == true
        handler scope.session.size.width, scope.session.size.height
    resizeProgressHandlers.push handler
    scope.progressHandlers.push
        name: name
        active: true

    if !onlyProgress
        resizeHandlers.push handler

scope.resizeInProgress = (wid, hei) ->
    for handler,i in resizeProgressHandlers
        if scope.progressHandlers[i].active == false
            continue
        handler wid, hei

# ===================
# Defaults
defaults =
    maximize: false
    minimize: false
    position:
        x: 0
        y: 0
    size:
        width: 300
        height: 200
for k,v of defaults
    scope.session[k] = v if !scope.session[k]?

# ====================
# Compile directive
appDirective = $ '<div>',
    class: scope.session.app + ' novaAppFrame'

if scope.appItem?.id?
    appDirective.addClass 'novaItem'
    appDirective.attr 'nova-item-object', 'appItem'
    appDirective.addClass 'novaItemDroppable'

elem.append appDirective
$compile(appDirective)(scope)

# ====================
# Find free position
if scope.session.startPosition == 'center'
    hei = scope.session.size.height
    if hei == 'auto'
        hei = 300
    scope.setPosition Math.ceil(($('.novaDesktop').width() - scope.session.size.width) / 2), Math.ceil(($('.novaDesktop').height() - hei) / 2), true
else
    scope.desktop.getFreePosition scope.session

# ====================
# Load app state
scope.stateSaver.register 'position',
    save: ->
        scope.session.position
    load: (data) ->
        scope.setPosition data.x, data.y

scope.stateSaver.register 'size',
    save: ->
        scope.session.size
    load: (data) ->
        scope.setSize data.width, data.height

scope.stateSaver.register 'maximize',
    save: ->
        scope.session.maximize
    load: (data) ->
        scope.maximize data

scope.stateSaver.register 'minimize',
    save: ->
        scope.session.minimize
    load: (data) ->
        scope.minimize data

# ====================
# Apply directive params
scope.setPosition()
scope.setSize()
scope.resized()

# ====================
# Init app
scope.init?()
scope.session.run = (data) ->
    scope.reInit?(data)
    for handler in focusHandlers
        handler()

# ====================
# Show animation
elem[0].style.transform += ' scale(0.9)'
setTimeout ->
    if !scope.session.maximize
        elem.css 'transform', 'translate3d(' + scope.session.position.x + 'px,' + scope.session.position.y + 'px, 0)'
    else
        elem.css 'transform', 'none'
    elem.addClass 'created'
    setTimeout ->
        elem.removeClass 'justCreated'
        elem.removeClass 'created'
    , 500
, 100
