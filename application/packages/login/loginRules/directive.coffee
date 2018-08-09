*deps: loginService

elem = $ element
textElem = elem.children '.text'
textElem.empty()
textElem.append $(tC['/static/terms_ru'])[3]

scope.backToSocial = ->
    loginService.state.mode = 'default'
true