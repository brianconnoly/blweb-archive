buzzlike.directive 'feedGroupDropable', (dragMaster, dropHelper, communityService, groupService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        new dragMaster.dropTarget element[0],
            enter: (elem) ->
                true
            leave: (elem) ->
                true
            canAccept: (elem, e) ->

                drop_action = null

                if elem.dragObject.dragMulti.length == 1 and elem.dragObject.dragMulti[0].item.type == 'team'
                    drop_action = 'bind_team_to_group'

                if drop_action?
                    dropHelper.setAction drop_action, e
                    return true
                false
                
            drop: (elem) ->
                if elem.dragObject.dragMulti.length == 1 and elem.dragObject.dragMulti[0].item.type == 'team'
                    groupService.save
                        id: scope.group.id
                        teamId: elem.dragObject.dragMulti[0].item.id
                    , -> true

        true