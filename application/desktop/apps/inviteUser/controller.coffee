buzzlike
    .controller 'inviteUserCtrl', ($scope, userService, rpc) ->

        $scope.stateTree.applyState
            'escape': $scope.closeApp

        $scope.session.expandedHeader = false

        $scope.searchField = ""
        $scope.searchUser = null

        $scope.canAddNew = false
        $scope.newUser = false

        $scope.params = 
            userRole: null

        $scope.switchInviteNew = ->
            $scope.newUser = true
            $scope.canAddNew = false
            $scope.searchUser = 
                photo: 'https://www.buzzlike.pro/resources/images/desktop/black/avatar.svg'
            $scope.setHeight 390

        $scope.searchUsers = () ->
            userService.call 'search', $scope.searchField, (user) ->
                if user == 'nouser'
                    $scope.setHeight 162
                    $scope.searchUser = null

                    if $scope.searchField.indexOf('@') > -1
                        $scope.canAddNew = true
                else
                    $scope.setHeight 390
                    $scope.searchUser = user
                    $scope.canAddNew = false

        roles = ['invite','mainEditor','editor','conetntManager','timeManager','postManager','client']
        $scope.roles = []
        for role in roles
            $scope.roles.push 
                value: role
                phrase: 'invite_member_role_' + role
        $scope.params.userRole = $scope.roles[0].value

        $scope.doInvite = () ->
            if !$scope.newUser and $scope.searchUser?
                $scope.session.api.pickUser $scope.searchUser, $scope.params.userRole
                $scope.closeApp()

            if $scope.newUser
                rpc.call 'auth.registerSimple',
                    name: $scope.searchField
                    firstName: $scope.searchField
                    login: $scope.searchField
                    settings:
                        simpleMode: true
                        takeUploadToRight: true
                , (userItem) ->
                    $scope.session.api.pickUser userItem, $scope.params.userRole
                    $scope.closeApp()

        $scope.keyDown = (e) ->
            if e.which == 13
                e.stopPropagation()
                e.preventDefault()
                
                $scope.doInvite()

        true

    .directive 'inviteFocus', () ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $ element
            setTimeout ->
                elem.focus()