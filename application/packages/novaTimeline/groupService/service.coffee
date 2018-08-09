*deps: itemService, rpc, actionsService, desktopService, account, novaWizard

class classEntity extends itemService

    itemType: 'group'

    constructor: () ->
        super()

        actionsService.registerAction
            phrase: 'add_feed'
            contextType: 'timelineApp'
            action: ->
                desktopService.launchApp 'addFeed',
                    closeOnAdd: true

        novaWizard.register 'channel',
            standalone: true
            type: 'sequence'
            steps: [
                id: 'project'
                directive: 'novaWizardProjectPicker'
                provide: 'projectId'
                previewType: 'project'
            ,
                id: 'community'
                # directive: 'novaWizardCommunityPicker'
                series: [
                    id: 'account'
                    directive: 'novaWizardAccountPicker'
                    variable: 'accountPublicId'
                    multi: false
                ,
                    id: 'community'
                    directive: 'novaWizardCommunityPicker'
                    variable: 'communityIds'
                    multi: true
                ]
                provide: 'communityIds'
                previewType: 'community'
                multi: true
            ,
                id: 'final'
                directive: 'novaWizardGroupCreate'
                customNext: 'novaWizardAction_create'
            ]
            final: (data) =>
                feeds = []
                for communityId in data.communityIds
                    feeds.push
                        communityId: communityId
                @create
                    projectId: data.projectId
                    name: data.name
                    feeds: feeds

        novaWizard.register 'pick_channel',
            standalone: true
            type: 'sequence'
            steps: [
                id: 'project'
                directive: 'novaWizardProjectPicker'
                provide: 'projectId'
                previewType: 'project'
            ,
                id: 'channel'
                series: [
                    id: 'channel'
                    directive: 'novaWizardChannelPicker'
                    variable: 'channelIds'
                    multi: true
                ]
                provide: 'channelIds'
                previewType: 'group'
                customNext: 'novaWizardAction_add'
                multi: true
            ]
            final: (data) =>
                data.cb? data

        novaWizard.register 'channel_add_communities',
            type: 'sequence'
            steps: [
                id: 'community'
                # directive: 'novaWizardCommunityPicker'
                series: [
                    id: 'account'
                    directive: 'novaWizardAccountPicker'
                    variable: 'accountPublicId'
                    multi: false
                ,
                    id: 'community'
                    directive: 'novaWizardCommunityPicker'
                    variable: 'communityIds'
                    multi: true
                ]
                provide: 'communityIds'
                previewType: 'community'
                customNext: 'novaWizardAction_add'
                multi: true
            ]
            final: (data) =>
                @getById data.channelId, (group) =>
                    for communityId in data.communityIds
                        exists = false
                        for feed in group.feeds
                            if feed.communityId == communityId
                                exists = true
                                break
                        if !exists
                            group.feeds.push
                                communityId: communityId
                    @save
                        id: group.id
                        feeds: group.feeds

    get: (cb) ->
        rpc.call @itemType + '.get', (result) =>
            cb? @handleItems result
            true

    insertFeed: (data, cb) ->
        rpc.call @itemType + '.insertFeed', data, (result) =>
            cb? @handleItem result

    setOrder: (data, cb) ->
        rpc.call @itemType + '.setOrder', data, (result) ->
            cb? result

    # handleItem: (item) ->
    #     handled = super item
    #     # if account.user.id != item.userId and !item.teamId?
    #     #     @removeCache item.id

new classEntity()
