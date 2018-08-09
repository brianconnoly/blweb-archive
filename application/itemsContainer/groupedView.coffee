buzzlike.directive 'groupedView', () ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        scope.groups = []

        exclude = null

        generateGroups = ->
            scope.groups.length = 0

            types = []
            for key,val of scope.currentStep.filterTypes
                if val == true
                    types.push key

            # if types.length > 0
            #     types.push 'folder'

            if scope.currentStep.sortBy == 'type'

                widgets = [
                        translateTitle: 'group_by_type_folder'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs 
                            entityType: 'content'
                            contentType: 'folder'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                    ,
                        translateTitle: 'group_by_type_image'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs
                            entityType: 'content'
                            contentType: 'image'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                    ,
                        translateTitle: 'group_by_type_text'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs 
                            entityType: 'content'
                            contentType: 'text'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                    ,
                        translateTitle: 'group_by_type_video'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs 
                            entityType: 'content'
                            contentType: 'video'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                    ,
                        translateTitle: 'group_by_type_audio'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs 
                            entityType: 'content'
                            contentType: 'audio'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                    ,
                        translateTitle: 'group_by_type_url'
                        query:
                            hideAllSent: scope.currentStep.query.hideAllSent
                            hideAllScheduled: scope.currentStep.query.hideAllScheduled
                            notInCombs: scope.currentStep.query.notInCombs 
                            entityType: 'content'
                            contentType: 'url'
                            sortBy: 'created'
                            sortType: scope.currentStep.sortType or 'desc'
                        screens: 3
                        lines: 3
                ]

                for widget in widgets
                    if types.length > 0 and widget.query.contentType not in types
                        continue
                    scope.groups.push widget

            if scope.currentStep.sortBy.indexOf('lastU') > -1 || scope.currentStep.sortBy == 'created'
                # Today
                dateObj = new Date()
                startDay = new Date dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()
                startYear = new Date dateObj.getFullYear(), 0, 1
                date = dateObj.getDate()
                day = dateObj.getDay()
                day -= 1
                if day < 0 then day = 7

                startDayTS = startDay.getTime()
                scope.groups.push
                    translateTitle: 'group_by_today'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterGreater: startDayTS - 1

                scope.groups.push
                    translateTitle: 'group_by_yesterday'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startDayTS
                        filterGreater: startDayTS - DAY - 1

                scope.groups.push
                    translateTitle: 'group_by_currentWeek'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startDayTS - DAY
                        filterGreater: startDayTS - DAY * day - 1

                scope.groups.push
                    translateTitle: 'group_by_lastWeek'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startDayTS - DAY * day
                        filterGreater: startDayTS - DAY * (day + 7) - 1

                scope.groups.push
                    translateTitle: 'group_by_lastMonth'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startDayTS - DAY * (day + 7)
                        filterGreater: new Date dateObj.getFullYear(), dateObj.getMonth(), 1 #startDayTS - DAY * date - 1

                scope.groups.push
                    translateTitle: 'group_by_thisYear'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startDayTS - DAY * date
                        filterGreater: startYear.getTime() - 1

                scope.groups.push
                    translateTitle: 'group_by_laterThenEver'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterLower: startYear.getTime()
                        filterGreater: 1

                scope.groups.push
                    translateTitle: 'group_by_other'
                    screens: 3
                    lines: 3
                    query: 
                        hideAllSent: scope.currentStep.query.hideAllSent
                        hideAllScheduled: scope.currentStep.query.hideAllScheduled
                        notInCombs: scope.currentStep.query.notInCombs
                        entityType: 'content'
                        contentType: if types.length > 0 then {
                            '$in': types
                        }
                        sortBy: scope.currentStep.sortBy
                        sortType: scope.currentStep.sortType or 'desc'
                        filterBy: scope.currentStep.sortBy
                        filterEquals: 
                            $in: [null, 0]
            # else

            #     scope.groups.push
            #         translateTitle: 'group_by_noUses'
            #         screens: 3
            #         lines: 3
            #         query:
            #             hideAllSent: scope.currentStep.query.hideAllSent
            #             hideAllScheduled: scope.currentStep.query.hideAllScheduled
            #             notInCombs: scope.currentStep.query.notInCombs
            #             entityType: 'content'
            #             contentType: if types.length > 0 then {
            #                 '$in': types
            #             }
            #             sortBy: scope.currentStep.sortBy
            #             sortType: scope.currentStep.sortType or 'desc'
            #             filterBy: scope.currentStep.sortBy
            #             filterEquals: 0

            #     scope.groups.push
            #         translateTitle: 'group_by_littleUses'
            #         screens: 3
            #         lines: 3
            #         query:
            #             hideAllSent: scope.currentStep.query.hideAllSent
            #             hideAllScheduled: scope.currentStep.query.hideAllScheduled
            #             notInCombs: scope.currentStep.query.notInCombs
            #             entityType: 'content'
            #             contentType: if types.length > 0 then {
            #                 '$in': types
            #             }
            #             sortBy: scope.currentStep.sortBy
            #             sortType: scope.currentStep.sortType or 'desc'
            #             filterBy: scope.currentStep.sortBy
            #             filterLower: 3
            #             filterGreater: 0

            #     scope.groups.push
            #         translateTitle: 'group_by_moreUses'
            #         screens: 3
            #         lines: 3
            #         query:
            #             hideAllSent: scope.currentStep.query.hideAllSent
            #             hideAllScheduled: scope.currentStep.query.hideAllScheduled
            #             notInCombs: scope.currentStep.query.notInCombs
            #             entityType: 'content'
            #             contentType: if types.length > 0 then {
            #                 '$in': types
            #             }
            #             sortBy: scope.currentStep.sortBy
            #             sortType: scope.currentStep.sortType or 'desc'
            #             filterBy: scope.currentStep.sortBy
            #             filterLower: 6
            #             filterGreater: 2

            #     scope.groups.push
            #         translateTitle: 'group_by_muchUses'
            #         screens: 3
            #         lines: 3
            #         query:
            #             hideAllSent: scope.currentStep.query.hideAllSent
            #             hideAllScheduled: scope.currentStep.query.hideAllScheduled
            #             notInCombs: scope.currentStep.query.notInCombs
            #             entityType: 'content'
            #             contentType: if types.length > 0 then {
            #                 '$in': types
            #             }
            #             sortBy: scope.currentStep.sortBy
            #             sortType: scope.currentStep.sortType or 'desc'
            #             filterBy: scope.currentStep.sortBy
            #             filterLower: 11
            #             filterGreater: 5

            #     scope.groups.push
            #         translateTitle: 'group_by_veryMuchUses'
            #         screens: 3
            #         lines: 3
            #         query:
            #             hideAllSent: scope.currentStep.query.hideAllSent
            #             hideAllScheduled: scope.currentStep.query.hideAllScheduled
            #             notInCombs: scope.currentStep.query.notInCombs
            #             entityType: 'content'
            #             contentType: if types.length > 0 then {
            #                 '$in': types
            #             }
            #             sortBy: scope.currentStep.sortBy
            #             sortType: scope.currentStep.sortType or 'desc'
            #             filterBy: scope.currentStep.sortBy
            #             filterGreater: 10
            true

        scope.$watch 'currentStep', (nVal) ->
            if nVal?
                if scope.getGroups?
                    scope.getGroups (list) ->
                        scope.groups.length = 0
                        for item in list
                            scope.groups.push item
                else
                    generateGroups()
        , true
        true