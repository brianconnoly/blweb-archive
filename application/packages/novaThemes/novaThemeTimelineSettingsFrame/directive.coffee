*deps: combService, groupService, novaWizard, novaDesktop, ruleService
*replace: true

elem = $ element

# Frame params
scope.flowFrame.maxWidth = 320

scope.groupIds = []
scope.comb = combService.getById scope.appItem.id
scope.combRules = ruleService.getByCombId scope.appItem.id
scope.addedChannels = []

scope.$watch 'combRules', (nVal) ->
    scope.groupIds.length = 0
    if nVal?.length > 0
        for rule in nVal
            scope.groupIds.push rule.groupId if rule.groupId not in scope.groupIds
        for ruleId in scope.addedChannels
            scope.groupIds.push ruleId if ruleId not in scope.groupIds
, true

scope.addChannel = ->
    novaWizard.fire 'pick_channel',
        projectId: scope.comb.projectId
        cb: (data) ->
            for id in data.channelIds
                scope.addedChannels.push id
                scope.groupIds.push id if id not in scope.groupIds

scope.removeChannel = (groupId) ->
    novaDesktop.launchApp
        app: 'novaOptionsListApp'
        noSave: true
        data:
            text: 'novaThemeTimelineSettings_confirm_remove_channel'
            description: 'novaThemeTimelineSettings_confirm_remove_channel_description'
            onAccept: =>
                removeElementFromArray groupId, scope.addedChannels
                removeElementFromArray groupId, scope.groupIds
                ruleService.call 'deleteByCombId', scope.appItem.id

scope.deleteGroup = ->
    novaDesktop.launchApp
        app: 'novaOptionsListApp'
        noSave: true
        data:
            text: 'novaChannelSettings_confirm_delete'
            description: 'popup_community_delete_subtitle'
            onAccept: =>
                groupService.delete
                    id: scope.group.id
                    type: scope.group.type
                , ->
                    scope.flowBox.closeFlowFrame scope.flowFrame

# Mediaplan
# scope.newRule =
#     timestampStart: 0
#     dayMask:[true,true,true,true,true,true,true]
#     groupId: scope.flowFrame.item.id
scope.hasRules = (groupId) ->
    for rule in scope.combRules
        if rule.groupId == groupId
            return true
    false
scope.rulesOrder = (rule) ->
    dateObj = new Date rule.timestampStart
    dateObj.getHours() * HOUR + dateObj.getMinutes() * MIN
scope.createRule = () ->
    ruleService.create scope.newRule
    scope.newRule.timestampStart = 0
    scope.newRule.dayMask = [true,true,true,true,true,true,true]
scope.deleteRule = (rule) ->
    ruleService.delete
        id: rule.id
        type: rule.type
scope.ruleFilter = (rule) -> rule.deleted != true
scope.deleteAllRules = (groupId) ->
    novaDesktop.launchApp
        app: 'novaOptionsListApp'
        noSave: true
        data:
            text: 'novaChannelSettings_confirm_delete_rules'
            description: 'novaChannelSettings_confirm_delete_rules_description'
            onAccept: =>
                for rule in scope.combRules
                    if rule.groupId == groupId
                        ruleService.delete
                            id: rule.id
                            type: rule.type
