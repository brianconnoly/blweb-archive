*deps: loginService, stateManager, localization
*replace: true

elem = $ element
frames = elem.children '.modeFrame'

current = null

scope.$watch ->
    loginService.state.mode
, (nVal, oVal) ->
    elem.removeClass 'mode_' + oVal
    elem.addClass 'mode_' + nVal

    if nVal != current
        frames.addClass 'hidden'
        elem.children('.modeFrame.' + nVal).removeClass 'hidden'
        current = nVal

stateManager.applyState
    'enter': 'default'
    'escape': ->
        loginService.state.mode = scope.rulesFrom or 'default'

scope.rulesFrom = null
scope.showRules = ->
    scope.rulesFrom = loginService.state.mode
    scope.rulesFrom = null if scope.rulesFrom == 'loginRules'
    loginService.state.mode = 'loginRules'

# ===================
# Buzz.ru stuff
scope.goBuzz = ->
    loginService.state.mode = 'loginBuzzRu'

# Buzz helper
buzzHelpers = [1,2,3]
helperCnt = 0
helperItem = elem.find '.buzzHelper'
rotateHelper = ->
    helperItem.removeClass 'visible'
    setTimeout ->
        helperItem.html localization.translate 'buzzLoginHelper_' + buzzHelpers[helperCnt]
        helperCnt++
        if helperCnt > buzzHelpers.length - 1
            helperCnt = 0
        helperItem.addClass 'visible'
    , 500

setTimeout ->
    rotateHelper()
    interval = setInterval rotateHelper, 8000
    scope.$on '$destroy', ->
        clearInterval interval
, 2000