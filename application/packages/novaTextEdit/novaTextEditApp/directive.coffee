*deps: contentService

elem = $ element
textContents = elem.children '.textBody'

scope.session.noItem = true
scope.session.size =
    width: 550
    height: 600

sessionCode = Date.now() + getRandomInt(10000, 100000)

mode = 'full'
textContents.on 'mousewheel', (e, delta) ->
    if textContents[0].scrollTop > 10 and mode == 'full'
        elem.addClass 'simple'
        mode = 'simple'
        return

    if textContents[0].scrollTop <= 10 and mode == 'simple'
        elem.removeClass 'simple'
        mode = 'full'
        return

contentService.getById scope.session.item.id, (textItem) ->
    scope.originalItem = textItem

    scope.editableItem =
        name: textItem.name
        value: textItem.value

    scope.$watch 'originalItem', (nVal) ->
        if nVal.lastEditSession != sessionCode
            scope.editableItem.name = nVal.name if scope.editableItem.name != nVal.name
            scope.editableItem.value = nVal.value if scope.editableItem.value != nVal.value
    , true

scope.saveText = () ->
    contentService.save
        id: scope.originalItem.id
        type: 'text'
        value: scope.editableItem.value
        name: scope.editableItem.name
        lastEditSession: sessionCode
