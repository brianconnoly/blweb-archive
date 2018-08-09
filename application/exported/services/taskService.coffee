buzzlike.service 'taskService', (itemService,rpc,contextMenu,teamService,socketAuth,account,localization,confirmBox,actionsService) ->
    class classEntity extends itemService
        itemType: 'task'

        constructor: () ->
            super()
            @byTeamId = {}
            @byParentId = {}

            @requestedParent = {}
            socketAuth.onAuth =>
                for k,v of @requestedParent
                    delete @requestedParent[k]

        handleItem: (item) ->
            saved = super item
            
            if saved._storedParent? and @byParentId[saved._storedParent]? and saved._storedParent != saved.parent
                removeElementFromArray saved, @byParentId[saved._storedParent]

            if !saved.parent?
                @byTeamId[saved.teamId] = [] if !@byTeamId[saved.teamId]?
                @byTeamId[saved.teamId].push saved if saved not in @byTeamId[saved.teamId]
            else
                saved._storedParent = saved.parent
                @byParentId[saved.parent] = [] if !@byParentId[saved.parent]?
                @byParentId[saved.parent].push saved if saved not in @byParentId[saved.parent]
            saved
        removeCache: (id) ->
            # console.log 'remove cache', id
            item = @storage[id]
            if !item?
                return

            if !item.parent?
                if @byTeamId[item.teamId]?
                    removeElementFromArray item, @byTeamId[item.teamId]
            else
                if @byParentId[item.parent]?
                    removeElementFromArray item, @byParentId[item.parent]
            super id
        getStorageByTeam: (id) ->
            @byTeamId[id] = [] if !@byTeamId[id]?
            @byTeamId[id]
        getStorageByParent: (id, cb) ->
            if !@byParentId[id]?
                @byParentId[id] = []

            if @requestedParent[id] != true
                @requestedParent[id] = true
                @query
                    parent: id
                , cb
            @byParentId[id]

        init: () ->
            super()

            actionsService.registerParser 'task', (item) ->
                types = []

                types.push 'task' + item.status?.capitalizeFirstLetter()

                # taskAdmin
                if item.userId == account.user.id
                    types.push 'taskAdmin'
                    types.push 'taskMy'
                else if item.teamId
                    team = teamService.getById item.teamId
                    if team?.userId?
                        if team.userId == account.user.id
                            types.push 'taskAdmin'
                        else
                            for user in team.members
                                if user.userId == account.user.id
                                    if user.roles?.editor == true or user.roles?.mainEditor == true
                                        types.push 'taskAdmin'
                                    break

                types

            actionsService.registerAction
                sourceType: 'task'
                targetType: 'project'
                phrase: 'move_to_project'
                check2: (data) ->
                    for item in data.items
                        if item.projectId != data.target.id
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        @call 'moveToProject',
                            taskId: item.id
                            projectId: data.target.id

            actionsService.registerAction
                sourceType: 'task'
                phrase: 'move_to_root'
                check2: (data) ->
                    for item in data.items
                        if item.parent? and item.projectId?
                            return true
                    false
                action: (data) =>
                    for item in data.items
                        if item.parent? and item.projectId? then @call 'unsetParent',
                            taskId: item.id
                            # parent: '_null'

        taskOrder: (item, short = false) ->
            multiply = '2'
            if item.status == 'started' # and item.toUserId == account.user.id
                multiply = '5'
                if account.user.id in item.users
                    multiply = '8'
            if item.status == 'rejected'
                multiply = '4'
                if account.user.id in item.users
                    multiply = '9'
            if item.status == 'created'
                multiply = '3'
                if account.user.id in item.users
                    multiply = '7'
            if item.status == 'finished'
                multiply = '6'
                if account.user.id == item.userId
                    multiply = '9'
            if item.status == 'accepted' # and item.fromUserId == account.user.id
                multiply = '1'

            if short
                multiply #+ ( (item.lastUpdated or item.created) / 1000 | 0 )
            else
                multiply + item.created

    new classEntity()
