*deps: novaTimelineScroller, account, communityService, groupService, updateService
*replace: true

# DEV ====================================
# scope.calendarActive = true
# DEV ====================================

elem = $ element
scroller_elem = $ elem.children('.scroller')[0]

# Frame params
scope.flowFrame.maxWidth = 320

# Cursor stuff
now = new Date()
scope.cursorTime = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
scope.scrollerParams =
    cursor: scope.cursorTime
scope.cursorChanged = ->
    scope.scroller.params.startFrom = scope.scrollerParams.cursor - MIN - DAY
    scope.scroller.rebuild true

scope.communityIds = [] #['54421db0181887781860660f','5460bbb86d34a36c1b642e52','54421db0181887781860660e']

fetchCommunities = ->
    communityService.query query, (items) ->
        for item in items
            scope.communityIds.push item.id

        scope.scroller = new novaTimelineScroller
            query:
                communityIds: scope.communityIds
            startFrom: scope.scrollerParams.cursor
            pageHeight: elem.height()
            apply: ->
                scope.$applyAsync()
        , scope, scroller_elem

        # scope.scroller.addPage
        #     query:
        #         from: Date.now()

        elem.on 'mousewheel', (e, delta) ->
            e.stopPropagation()
            e.preventDefault()

            scope.scroller.scroll delta

if scope.appItem.profileUserId?
    publicIds = []
    for acc in account.user.accounts
        publicIds.push acc.publicId

    query =
        socialNetworkId:
            $in: publicIds

    fetchCommunities()
else
    groupService.getById scope.flowFrame.item.id, (group) ->
        query =
            ids: []
        for feed in group.feeds
            query.ids.push feed.communityId if feed.communityId not in query.ids

        fetchCommunities()

updateId = updateService.registerUpdateHandler (data, action, items) ->

    if action in ['update','create','delete']
        if data['schedule']?
            affected = []
            for item in items
                if item.type == 'schedule'
                    affected.push item

            if affected.length > 0
                scope.scroller.updated affected, action

scope.$on '$destroy', ->
    updateService.unRegisterUpdateHandler updateId

# Zoom stuff
scope.maxZoom = 3
scope.currentZoom = 3
scope.setZoom = (zoom) ->
    scope.currentZoom = zoom
    scope.scroller.rebuild()
    setTimeout ->
        scope.scroller.scroll 0
    , 100
