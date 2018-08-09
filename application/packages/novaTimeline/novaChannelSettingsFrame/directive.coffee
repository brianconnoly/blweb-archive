*deps: groupService, novaWizard, novaDesktop, ruleService

elem = $ element

# Frame params
scope.flowFrame.maxWidth = 320

scope.group = groupService.getById scope.flowFrame.item.id
scope.sendParams =
    fromCommunity: false
    useUserSign: false

scope.addCommunity = ->
    novaWizard.fire 'channel_add_communities',
        channelId: scope.flowFrame.item.id

scope.removeCommunity = (feed) ->
    removeElementFromArray feed, scope.group.feeds
    groupService.save
        id: scope.group.id
        feeds: scope.group.feeds

scope.saveGroup = ->
    groupService.save scope.group

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
scope.rules = ruleService.fetchByGroupId scope.flowFrame.item.id
scope.newRule =
    timestampStart: 0
    dayMask:[true,true,true,true,true,true,true]
    groupId: scope.flowFrame.item.id
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
scope.ruleFilter = (rule) -> rule.deleted != true and !rule.combId?
scope.deleteAllRules = ->
    novaDesktop.launchApp
        app: 'novaOptionsListApp'
        noSave: true
        data:
            text: 'novaChannelSettings_confirm_delete_rules'
            description: 'novaChannelSettings_confirm_delete_rules_description'
            onAccept: =>
                for rule in scope.rules
                    ruleService.delete
                        id: rule.id
                        type: rule.type
