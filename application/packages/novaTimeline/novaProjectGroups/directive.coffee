*deps: groupService, updateService

elem = $ element
scope.moduleName = 'novaProjectGroups_title_single'

scope.channels = groupService.getByProjectId scope.session.item.id

scope.$watch 'channels', (nVal) ->
    if nVal.length == 0
        elem.addClass 'empty'
        return
    elem.removeClass 'empty'
    elem.removeClass 'single'

    if nVal.length == 1
        elem.addClass 'single'
        scope.moduleName = 'novaProjectGroups_title_single'
    else if nVal.length > 1
        scope.moduleName = 'novaProjectGroups_title_multi'
, true

scope.channelFilter = (channel) -> channel.deleted != true

scope.channelActive = (channel) ->
    scope.flow.currentCode == 'channelTimeline' + channel.id

scope.activateChannel = (channel, noFlush = false) ->
    scope.flow.addFrame
        title: 'channel'
        directive: 'novaTimelineFrame'
        item:
            id: channel.id
            type: 'group'
        data:
            groupId: channel.id
        code: 'channelTimeline' + channel.id
    , true, noFlush

scope.activateAll = ->
    if scope.channels.length == 1
        scope.activateChannel scope.channels[0]
    else
        for channel in scope.channels
            scope.activateChannel channel, true
        # Open all channels in flowBoxes
    true

scope.channelSettings = (channel, e) ->
    e.stopPropagation()
    e.preventDefault()

    scope.flow.addFrame
        title: 'channel'
        directive: 'novaChannelSettingsFrame'
        item:
            id: channel.id
            type: 'group'
