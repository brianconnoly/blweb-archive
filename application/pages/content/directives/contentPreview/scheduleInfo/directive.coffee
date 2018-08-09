buzzlike
    .directive "scheduleInfo", (contentService, communityService, scheduleService, $filter, $compile) ->
        restrict: "C"
        scope:
            post: "="
        template: tC['/pages/content/directives/contentPreview/scheduleInfo']
        link: (scope, element, attrs) ->
            scheduleService.getOriginalByPostId scope.post.id, (sched) ->
                elem = $ element
                
                if !sched then return true

                communityService.getById sched.communityId, (community) ->
                    elem.find('img')[0].src = community.photo
                    #выравнивание аватарки в блоке
                    elem.find('img')[0].onload = ->
                        # size = elem.height()
                        # imageIn @, size, size
                        if @.width > @.height
                            $(@).css 'height', '100%'
                        else
                            $(@).css 'width', '100%'

                    elem.find('.info').html('<div class="time">'+$filter('timestampMask')(sched.timestamp, "time")+'</div>
                        <div class="date">'+$filter('timestampMask')(sched.timestamp, "date")+'</div>')
                    if !elem.parent().find('.shield').length
                        elem.parent().append $compile("<div class='shield'><img src='#{proxyPrefix}#{community.image}' class='communityIcon picPreload'></div>")(scope)

            true


    .directive "requestInfo", (requestService, contentService, communityService, scheduleService, postService, localization, $filter) ->
        template: tC['/pages/content/directives/contentPreview/scheduleInfo']
        link: (scope, element, attrs) ->
            id = attrs.requestInfo
            post = postService.getById id
            requests = requestService.getOutcomingByLotId(post.lotId) or []
            elem = $ element

            if !requests.length
                elem.html('').addClass 'invisible'
                return true

            else if requests.length == 1
                scheduleService.getSchedulesByPostId id, (sched) ->
                    sched = sched[0]
                    if !sched then return true

                    if sched.requestStatus
                        elem.parent().find('.requestStatus').addClass sched.requestStatus

                    communityService.loadCommunityById sched.communityId, () ->
                        setTimeout ->
                            community = communityService.getById sched.communityId
                            elem.find('img')[0].src = community.image

                            elem.find('img')[0].onload = ->
                                size = elem.height()
                                imageIn @, size, size

                            elem.find('.info').html('<div class="time">'+$filter('timestampMask')(sched.timestamp, "hh:mm")+'</div>
                                <div class="date">'+$filter('timestampMask')(sched.timestamp, "DD.MM.YYYY")+'</div>')
                            if !elem.parent().find('.shield').length
                                elem.parent().append("<div class='shield'><img src='#{proxyPrefix}#{community.image}' class='communityIcon'></div>")
                        , 0

            else if requests.length > 1
                elem.find('.info')
                    .css({left: 0})
                    .html('<div class="requests">'+requests.length+' '+localization.declension(requests.length, localization.translate("requestInfo_request"))+'</div>')

            true
