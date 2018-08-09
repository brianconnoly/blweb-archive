*deps: groupService, updateService, channelMonitorService

elem = $ element
scope.moduleName = 'novaProjectChannelMonitor_title_single'

scope.monitors = channelMonitorService.getByProjectId scope.session.item.id

scope.moduleName = 'novaProjectChannelMonitor_title_single'

scope.channelFilter = (channel) -> channel.deleted != true

scope.channelActive = (channel) ->
    scope.flow.currentCode == 'channelMonitor' + channel.id

scope.activateChannel = (monitor) ->
    scope.flow.addFrame
        title: 'channelMonitor'
        directive: 'novaChannelMonitorFrame'
        item:
            id: monitor.id
            type: 'group'
        data:
            groupId: monitor.id
        code: 'channelTimeline' + monitor.id
    , true

scope.openCanvas = () ->
    scope.flow.addFrame
        title: 'socialCanvas'
        translateTitle: 'novaSocialCanvas_title'
        directive: 'novaSocialCanvasFrame'
        code: 'novaSocialCanvas'
    , true

scope.activateAll = ->
    if scope.channels.length == 1
        scope.activateChannel scope.channels[0]
    else
        for channel in scope.channels
            scope.activateChannel channel, true
        # Open all channels in flowBoxes
    true

scope.channelSettings = (monitor, e) ->
    e.stopPropagation()
    e.preventDefault()

    scope.flow.addFrame
        title: 'channelMonitor'
        directive: 'novaChannelMonitorSettingsFrame'
        item:
            id: monitor.id
            type: 'group'
