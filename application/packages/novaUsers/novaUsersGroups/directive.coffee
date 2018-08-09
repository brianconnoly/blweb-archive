*deps: userService, projectService, contactListService
*replace: true

# User groups
scope.groups = []
scope.groupType = "roles"
scope.groupTypes = ['roles','name']
projectMembers = {}

recountGroups = scope.recountGroups = (members) ->
    if !members
        members = scope.context?.members

    scope.groups.length = 0
    emptyObject projectMembers
    groupMap = {}
    for member in members
        # Get flag
        flag = "default"
        switch scope.groupType
            when 'roles'
                flag = member.role
            when 'name'
                user = userService.getById member.userId
                if user.name?
                    flag = user.name[0].toLowerCase()
                else if user.login?
                    flag = user.login[0].toLowerCase()

        if !groupMap[flag]?
            groupMap[flag] = []
        groupMap[flag].push member
        projectMembers[member.userId] = true

    for k,v of groupMap
        scope.groups.push
            key: k
            realTitle: if scope.groupType == 'name' then k.toUpperCase() else undefined
            members: v

    scope.groups.sort (a,b) ->
        if a.key > b.key
            return -1
        if a.key < b.key
            return 1
        0

if scope.session.item.id?
    membersService = projectService
    scope.invitePhrase = 'novaProjectMembers_inviteMembers'
    scope.project = projectService.getById scope.session.item.id
    scope.context = scope.project
    unreg = scope.$watch 'project.members', (nVal) ->
        if nVal?.length > 0
            # unreg()
            recountGroups scope.project.members
    , true

else if scope.flowFrame.data.userId?
    membersService = contactListService
    scope.invitePhrase = 'novaProjectMembers_inviteContactList'
    #  = userService.getById scope.flowFrame.data.userId
    contactListService.getByUserId scope.flowFrame.data.userId, (item) ->
        scope.contactList = item
        scope.context = item

    unreg = scope.$watch 'contactList.members', (nVal) ->
        if nVal?.length > 0
            # unreg()
            recountGroups scope.contactList.members
    , true

# Search
scope.searchResults = []
scope.doSearch = ->
    if scope.searchResults.length > 0
        scope.searchResults.length = 0
        scope.filterBox = ""
        scope.searchMultiselect?.flush()
    else
        userService.call 'search', scope.filterBox, (users) ->
            scope.searchResults.length = 0
            if users != 'noUser'
                for user in users
                    scope.searchResults.push user if projectMembers[user.id] != true

scope.doInvite = ->
    for user in scope.searchMultiselect?.selected
        membersService.call 'addMember',
            id: scope.project?.id or scope.contactList?.id
            userId: user.id

    scope.doSearch()

scope.filterChanged = (e) ->
    if e.which == 13 and scope.filterBox.length > 0
        scope.doSearch()

    if scope.searchResults.length > 0
        scope.searchResults.length = 0

# Filter
scope.memberFilter = (member) ->
    user = userService.getById member.userId
    if !user.type? or !(scope.filterBox?.length > 0)
        return true

    if user.name.toLowerCase().indexOf(scope.filterBox) > -1
        return true
    if user.login.toLowerCase().indexOf(scope.filterBox) > -1
        return true
    for acc in user.accounts
        if acc.screenName.toLowerCase().indexOf(scope.filterBox) > -1
            return true
    false
