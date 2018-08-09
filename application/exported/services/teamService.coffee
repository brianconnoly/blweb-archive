buzzlike.service 'teamService', (itemService,rpc,contextMenu,account,confirmBox,localization,actionsService,desktopService) ->
    class classEntity extends itemService
        itemType: 'team'

        init: () ->
            super()
            
            actionsService.registerParser 'team', (item) ->
                types = []
                
                # teamMy
                if item.userId == account.user.id
                    types.push 'teamMy'
                    types.push 'teamAdmin'
                else
                    for user in item.members
                        if user.userId == account.user.id 
                            if user.roles?.mainEditor == true
                                types.push 'teamAdmin'
                            break
                    
                types
                
            actionsService.registerAction
                targetType: 'team'
                sourceType: 'image'
                sourceNumber: 1
                phrase: 'set_cover'
                action: (data) =>
                    @save 
                        id: data.target.id
                        cover: data.ids[0]
                    , ->
                        true
                
            actionsService.registerAction 
                sourceType: 'teamAdmin'
                sourceNumber: 1
                phrase: 'team_invite'
                action: (data) =>
                    desktopService.launchApp 'inviteUser',
                        api:
                            pickUser: (user, role) =>
                                @call 'invite', 
                                    teamId: data.item.id
                                    userId: user.id
                                    role: role
                    
            actionsService.registerAction
                sourceType: 'teamMy'
                phrase: 'delete'
                priority: -15
                action: (data) =>
                    cnt = data.ids.length
                    confirmBox.init
                        realText: localization.translate('teamManager_confirm_team_delete') + ' ' + cnt + ' ' + localization.declensionPhrase(cnt, 'teamManager_confirm_team_delete_declension') + '?'
                        description: 'teamManager_confirm_team_delete_description'
                    , =>
                        @deleteByIds data.ids
                        true
                    , ->
                        true
                    
                    
    new classEntity()
