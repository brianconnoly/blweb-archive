*deps: postService
*replace: true

elem = $ element
scope.posts = []

currentPage = 0
loadInProgress = false
total = null
getPage = ->
    if loadInProgress
        return
    if total? and scope.posts.length > 0 and scope.posts.length >= total
        return
    loadInProgress = true

    query =
        limit: 20
        page: currentPage
        sortBy: 'lastUpdated'
        sortType: 'DESC'
        projectId: scope.postParams.projectId

    if scope.postParams.combId?
        query.combId = scope.postParams.combId

    postService.query query, (items, ttl) ->
        total = ttl
        currentPage++
        loadInProgress = false

        for item in items
            scope.posts.push item

getPage()

elem.on 'mousewheel', (e) ->
    if loadInProgress
        return

    if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
        getPage()
        scope.$apply()
