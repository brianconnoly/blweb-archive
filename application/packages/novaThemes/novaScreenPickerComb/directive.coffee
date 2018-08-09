*deps: combService
*replace: true

elem = $ element
scope.combs = []

currentPage = 0
loadInProgress = false
total = null
getPage = ->
    if loadInProgress
        return
    if total? and scope.combs.length > 0 and scope.combs.length >= total
        return
    loadInProgress = true

    combService.query
        limit: 20
        page: currentPage
        sortBy: 'lastUpdated'
        sortType: 'DESC'
        projectId: scope.postParams.projectId
    , (items, ttl) ->
        total = ttl
        currentPage++
        loadInProgress = false

        for item in items
            scope.combs.push item

getPage()

elem.on 'mousewheel', (e) ->
    if loadInProgress
        return

    if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
        getPage()
        scope.$apply()
