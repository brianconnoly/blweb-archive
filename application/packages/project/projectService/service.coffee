*deps: itemService, account, rpc, novaWizard, localization, novaDesktop, groupService

class classEntity extends itemService
    itemType: 'project'

    init: () ->
        @projectStyles = {}
        super()

        novaWizard.register 'project',
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
                multi: true
                canSkip: true
            ,
                id: 'members'
                directive: 'novaWizardMembersPicker'
                provide: 'members'
                multi: true
                canSkip: true
            ,
                id: 'final'
                directive: 'novaWizardProjectCreate'
                customNext: 'novaWizardAction_create'
            ]
            final: (data) =>
                members = []
                if data.members?.length > 0
                    for userId in data.members
                        members.push
                            userId: userId
                            invited: true
                @create
                    members: members
                    name: data.name
                , (project) ->
                    if data.communityIds?.length > 0
                        feeds = []
                        for communityId in data.communityIds
                            feeds.push
                                communityId: communityId
                        groupService.create
                            projectId: project.id
                            name: data.name
                            feeds: feeds

                    novaDesktop.launchApp
                        app: 'novaProjectApp'
                        item:
                            type: 'project'
                            id: project.id

            # type: 'simple'
            # action: =>
            #     @create
            #         type: 'project'
            #         name: localization.translate('project_defaultTitle')
            #     , (project) ->
            #         novaDesktop.launchApp
            #             app: 'novaProjectApp'
            #             item:
            #                 type: 'project'
            #                 id: project.id

    updateStyles: () ->
        if !@styleItem?
            @styleItem = $ '<style>'
            @styleItem.appendTo 'head'
        styleData = ""
        for id,style of @projectStyles
            styleData += style + "\n"
        @styleItem.html styleData

    handleItem: (item) ->
        handled = super item

        for member in handled.members
            if member.userId == account.user.id
                @projectStyles[handled.id] = "
    .novaAppLauncher.active.#{'project_' + handled.id}, .novaAppLauncher.#{'project_' + handled.id}:hover {
        border-color: #{handled.appearance.background};
    }
    .novaApp.#{'project_' + handled.id} {
        background: #{handled.appearance.background};
        color: #{handled.appearance.color};
    }
                "
                launcher = novaDesktop.registerLauncher
                    dock: true
                    static: handled.profileUserId == account.user.id
                    order: if handled.profileUserId == account.user.id then 0 else undefined
                    item:
                        type: 'project'
                        id: handled.id
                    app: 'novaProjectApp'

                @updateStyles()

                if member.invited
                    if !launcher.session?
                        novaDesktop.launchApp launcher
                    else
                        novaDesktop.activate launcher.session
                return handled

        # Not a member
        # handled._notMember = true
        if handled.userId != account.user.id
            novaDesktop.unregisterLauncher
                item:
                    type: 'project'
                    id: handled.id
        handled

    pushModuleData: (projectId, moduleId, code, items) ->
        @getById projectId, (project) =>
            if !project.modules[moduleId]?
                project.modules[moduleId] = {}
            if !project.modules[moduleId][code]?
                project.modules[moduleId][code] = []

            for item in items
                project.modules[moduleId][code].push item if item not in project.modules[moduleId][code]

            @save project

    pullModuleData: (projectId, moduleId, code, items) ->
        @getById projectId, (project) =>
            if !project.modules[moduleId]?
                project.modules[moduleId] = {}
            if !project.modules[moduleId][code]?
                project.modules[moduleId][code] = []
                return true

            for item in items
                removeElementFromArray item, project.modules[moduleId][code]

            @save project


new classEntity()
