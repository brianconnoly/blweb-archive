*deps: novaWizard, localStorageService, rpc
*replace: true

elem = $ element
progressBar = $ elem.find('.progressBar')[0]
statusMessage = $ elem.find('.statusMessage')[0]
canvas = elem.find('.socialCanvas')[0]
# jCanvas = $ canvas

# newId = 'novaSocialCanvas' + getRandomInt(0,9999)
# jCanvas.attr 'id', newId
# sigma.renderers.def = sigma.renderers.canvas
# s = new sigma
#     type: 'canvas'
#     container: canvas
#
# dragListener = new sigma.plugins.dragNodes(s, s.renderers[0])

network = null
networkOptions =
    nodes:
        shape: 'dot'
        size: 16
    physics:
        forceAtlas2Based:
            gravitationalConstant: -26
            centralGravity: 0.005
            springLength: 230
            springConstant: 0.18
        maxVelocity: 146
        solver: 'forceAtlas2Based'
        timestep: 0.35
        stabilization:
            iterations: 150
    interaction:
        multiselect: true
        keyboard:
            enabled: true


adjust = ->
    s.startForceAtlas2
        adjustSizes: true
        strongGravityMode: true
    setTimeout ->
        s.stopForceAtlas2()
    , 2 * SEC

scope.paints = JSON.parse(localStorageService.get('socialCanvas'+scope.appItem.id)) or []

scope.addPaint = ->
    novaWizard.fire 'socialPaintPicker',
        cb: (result) ->
            switch result.type
                when 'vkUsers', 'vkGroups'
                    arr = result.value.split("\n")
                    resArr = []
                    for item in arr
                        if $.trim(item).length > 0
                            resArr.push
                                value: $.trim(item)

                    scope.paints.push
                        active: true
                        type: result.type
                        items: resArr

colors = [
    '#CC0033'
    '#FF6600'
    '#FFCC00'
    '#339900'
    '#3FA9F5'
    '#2D51BD'
    '#F53FAE'
]
colorCursor = -1
currentColor = null
nextColor = ->
    colorCursor++
    if colorCursor > colors.length - 1
        colorCursor = 0
    currentColor = colors[colorCursor]

updateInProgress = false
updateAll = ->
    if updateInProgress
        updateAgain = true
        return
    updateInProgress = true

    network?.destroy?()
    network = null
    # s.graph.clear()
    localStorageService.add 'socialCanvas'+scope.appItem.id, JSON.stringify(scope.paints)

    if scope.paints?.length > 0
        g =
            nodes: []
            edges: []

        userIds = []
        publicIds = []

        for paint,i in scope.paints
            if !paint.active
                continue
            switch paint.type
                when 'vkUsers'
                    nextColor()
                    for item in paint.items
                        userIds.push item.value | 0
                        g.nodes.push
                            id: 'id' + item.value
                            label: 'id' + item.value
                            group: i
                            value: 0.1
                            # x: Math.random() * 10
                            # y: Math.random() * 10
                            # size: 0.1
                            # color: currentColor # '#777'

                when 'vkGroups'
                    for item in paint.items
                        publicIds.push item.value
                        g.nodes.push
                            id: 'club' + item.value
                            label: 'club' + item.value
                            group: i
                            value: 0.2
                            # x: Math.random() * 10
                            # y: Math.random() * 10
                            # size: 0.2
                            # color: '#ccc'

        if userIds.length > 0
            rpc.call
                method: 'socialCanvas.getEdges'
                data:
                    userIds: userIds
                    publicIds: publicIds
                progress: (status, perc) ->
                    statusMessage.html status

                    progressBar.css
                        'width': perc + '%'

                    if perc == 100
                        statusMessage.html ""
                        progressBar.css
                            'width': 0

                error: () ->
                    updateInProgress = false
                    if updateAgain
                        updateAll()

                success: (res) ->
                    if res?.length > 0
                        for edge,i in res
                            g.edges.push
                                # id: 'e' + i
                                from: edge.source
                                to: edge.target
                                # color: if edge.userToUser then '#f00' else '#66f'

                        # s.graph.clear()
                        # s.graph.read g
                        # s.refresh()
                        # adjust()

                        network = new vis.Network canvas,
                            nodes: g.nodes
                            edges: g.edges
                        , networkOptions

                    updateInProgress = false
                    if updateAgain
                        updateAll()
        else
            network = new vis.Network canvas,
                nodes: g.nodes
                edges: g.edges
            , networkOptions

            updateInProgress = false
            if updateAgain
                updateAll()

        # s.graph.read g
    else
        updateInProgress = false
    # s.refresh()
    # adjust()

handler = null
updateAgain = false
scope.$watch 'paints', (nVal) ->
    if !handler?
        handler = setTimeout ->
            updateAll()
            handler = null
        , 1000
, true

# console.log s
# setTimeout ->
#     s.renderers[0].resize()
#     s.refresh()
#     adjust()
# , 500

scope.refresh = ->
    s.renderers[0].resize()
    s.refresh()
    adjust()

scope.analyse = ->
