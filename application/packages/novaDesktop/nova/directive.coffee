*deps: account, streamService, novaDragHelper, stateManager, uploadService
elem = $ element
scope.user = account.user

body = $ 'body'
helper = $ '<div>',
    class: 'dropHoverHelper'

currentTarget = null
setTarget = (target, e) ->
    if target == currentTarget
        return true
    currentTarget = target

    elmScope = angular.element(target).scope()
    actions = currentTarget.novaDrop.getActions(items, null, e)

    if actions.length > 0
        # Got some target
        novaDragHelper.show []
        novaDragHelper.setActions actions
        novaDragHelper.showHighLighter target
        return true
    else
        novaDragHelper.setActions []
        novaDragHelper.hide()
        novaDragHelper.flushHighlighter()
        return false

enterCnt = 0
leaveCnt = 0

getFileList = (transferObject) ->
    result = {}
    if transferObject.items
        for item in transferObject.items
            if item.type == '' then result.folder = true

            if item.type in ['image/png','image/jpeg','image/gif']
                result.image = 0 if !result.image
                result.image++
            if item.type == 'text/plain'
                result.text = 0 if !result.text
                result.text++

    res = []
    if result.image > 0
        res.push
            type: 'image'
        if result.image > 1
            res.push
                type: 'image'
    if result.text > 0
        res.push
            type: 'text'
        if result.text > 1
            res.push
                type: 'text'
    if result.folder
        res.push
            type: 'folder'

    res

items = []
dragEnter = (e) ->
    enterCnt++

    if e.dataTransfer.types.indexOf("Files") < 0
        return false

    items = getFileList e.dataTransfer

    if !(stateManager.getCurrentState()?.name == 'dropUpload')
        stateManager.applyState
            name: 'dropUpload'
            escape: ->
                removeEvents()
                stateManager.goBack()

    origE = e.originalEvent
    posHelper e

    # elem.off 'dragenter'

    # elem.append helper
    e.stopPropagation()
    e.preventDefault()

    # elem.on 'drag', (e) ->
        # console.log 'mouse move!!!'
        # Drop target
    dropTarget = e.target #document.elementFromPoint e.pageX, e.pageY
    foundTarget = false
    while dropTarget
        if dropTarget.novaDrop
            if setTarget dropTarget, origE
                foundTarget = true
                break
        dropTarget = dropTarget.parentNode

    # if !foundTarget
    #     # helper.detach()
    #     true
    # else
    #     # $(dropTarget).append helper

    scope.$apply()

elem
.on 'dragenter', dragEnter
.on 'dragleave', (e) ->
    leaveCnt++
    if enterCnt == leaveCnt
        removeEvents()

.on 'dragover', (e) ->
    posHelper e
    e.stopPropagation()
    e.preventDefault()
.on 'drop', (e) ->
    e.stopPropagation()
    e.preventDefault()
    removeEvents true

    cbData =
        action: null
        e: null
        items: null
        ids: null

    uploadService.upload e.dataTransfer, (items, ids) ->
        cbData.items = items
        cbData.ids = ids

        if cbData.action?
            cbData.action cbData.e, items, ids

    novaDragHelper.preAction = (action, e2) ->
        cbData.action = action
        cbData.e = e2

        if cbData.items?
            action e2, cbData.items, cbData.ids

    novaDragHelper.activate e
.on 'dragend', (e) ->
    true

posHelper = (e) ->
    origE = e.originalEvent

    bodyWid = body.width()
    bodyHei = body.height()

    helperPos =
        x: origE.pageX
        y: origE.pageY

    # Positionate helper
    if origE.pageX > bodyWid - 210 - 20
        helperPos.x = origE.pageX - 20 #- 210
        novaDragHelper.elem.addClass 'lefty'
    else
        helperPos.x = origE.pageX + 20
        novaDragHelper.elem.removeClass 'lefty'

    if origE.pageY > bodyHei - 120
        helperPos.y = bodyHei - 100
    else
        helperPos.y = origE.pageY + 20

    novaDragHelper.elem.css 'transform', "translate3d(#{helperPos.x}px,#{helperPos.y}px, 0)"
    true

removeEvents = (leaveHelepr = false) ->
    # elem.on 'dragenter', dragEnter
    # elem.off 'drag'
    if stateManager.getCurrentState()?.name == 'dropUpload'
        stateManager.goBack()
    enterCnt = leaveCnt = 0
    currentTarget = null
    helper.detach()
    novaDragHelper.hide() if !leaveHelepr
