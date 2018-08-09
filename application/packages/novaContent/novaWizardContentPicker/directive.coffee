*deps: contentService, projectService, $filter

elem = $ element
scrollElem = elem.parent()
breadCrombs = elem.find('.breadCrombs')[0]

scope.items = []
scope.wizard.data.contentIds = []

scope.isLoading = false

currentPage = 0
totalItems = null
fetching = false
lastCromb = null
getPage = ->
    if scope.isLoading
        return false
    scope.isLoading = true

    if lastCromb != scope.currentCromb
        scope.items.length = 0
        currentPage = 0
        totalItems = null
        lastCromb = scope.currentCromb

    if totalItems and scope.items.length >= totalItems
        return false

    contentService.query
        projectId: scope.wizard.data.projectId
        parent: scope.currentCromb.parent
        limit: 40
        page: currentPage
        sortBy: 'created'
        sortType: 'DESC'
    , (items, total) ->
        totalItems = total
        currentPage++
        for item in items
            scope.items.push item if item not in scope.items
        scope.isLoading = false
    true

# Crombs
scope.crombs = []
scope.currentCromb = null

scope.goCromb = (cromb) ->
    if cromb == scope.currentCromb
        return

    index = scope.crombs.indexOf cromb
    if index > -1
        scope.crombs.length = index + 1
    else
        scope.crombs.push cromb
    scope.currentCromb = cromb

    setTimeout ->
        breadCrombs.scrollLeft = breadCrombs.scrollWidth
    , 0

    getPage()

scope.activateItem = (item) ->
    if item.type != 'folder'
        return

    scope.goCromb
        name: item.name or $filter('timestampMask')(ts, 'Папка от DD.M.YY')
        image: item.contentIds[0]
        cover: contentService.getById item.contentIds[0]
        parent: item.id
    true

# Init
currentProject = projectService.getById scope.wizard.data.projectId, (item) ->
    if !item.profileUserId?
        scope.goCromb
            name: item.name
            image: item.appearance.cover
            cover: contentService.getById item.appearance.cover
            parent: 'null'
    else
        scope.goCromb
            name: scope.user.name
            cover: scope.user
            parent: 'null'

    elem.on 'mousewheel', (e, delta) ->
        if scrollElem[0].scrollTop + scrollElem.height() > scrollElem[0].scrollHeight - 200
            # console.log 'Get page?', scrollElem[0].scrollTop, scrollElem.height(), scrollElem[0].scrollHeight
            if getPage()
                scope.$apply()
