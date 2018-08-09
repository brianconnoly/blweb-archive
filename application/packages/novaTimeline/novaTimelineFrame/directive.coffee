*deps: novaTimelineScroller, account, communityService, groupService, updateService, ruleService, $compile
*replace: true

# DEV ====================================
# scope.calendarActive = true
# DEV ====================================

elem = $ element
scroller_elem = $ elem.children('.scroller')[0]
createPost_wrapper = $ elem.find('.novaPostCreateContainer')[0]

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
                parent: 'null'
            startFrom: scope.scrollerParams.cursor
            pageHeight: elem.height()
            rules: scope.rules
            apply: ->
                scope.$applyAsync()
        , scope, scroller_elem

        # scope.scroller.addPage
        #     query:
        #         from: Date.now()

        scroller_elem.on 'mousewheel', (e, delta) ->
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
    scope.rules = ruleService.fetchByGroupId scope.flowFrame.item.id
    groupService.getById scope.flowFrame.item.id, (group) ->
        query =
            ids: []
        for feed in group.feeds
            query.ids.push feed.communityId if feed.communityId not in query.ids

        fetchCommunities()

# Update stuff
# Rules update
scope.$watch 'rules', (nVal) ->
    # console.log 'Group rules', nVal
    if nVal?
        scope.scroller?.updatePlaceholders nVal
, true

# Update schedules
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

# Create post inFrame
launched = false
createPostScope = null
scope.launchPostCreate = (e, ts) ->
    if launched
        createPostScope.postParams.timestamp = ts
    else
        launched = true
        createElem = $ '<div>',
            class: 'novaPostCreate'

        createPostScope = scope.$new()
        createPostScope.session =
            data:
                timestamp: ts
                projectId: scope.appItem.projectId or scope.appItem.id
                channelId: scope.flowFrame.item.id

        createElem = $compile(createElem)(createPostScope)

        createPost_wrapper.append createElem
    true

scope.closePostCreate = ->
    if launched
        createPostScope.$destroy()
        createPost_wrapper.empty()
        launched = false
