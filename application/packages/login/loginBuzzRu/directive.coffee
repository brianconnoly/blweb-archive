*deps: ugcService, loginService

elem = $ element
scope.ugcItems = []

ugcService.query {
    # featured: true
}
, (items) ->
    if items.length > 9
        items.length = 9

    for item in items
        scope.ugcItems.push item

    hei = Math.ceil(items.length / 5) * 150 + 150
    elem.css
        height: hei
        marginTop: -hei / 2

scope.backToSocial = ->
    loginService.state.mode = 'default'

scope.goUgc = (ugc) ->
    window.open 'https://buzz.ru/' + ugc.link
    true