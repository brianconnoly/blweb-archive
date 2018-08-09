buzzlike.directive 'stripeColor', (communityService) ->
    restrict: 'A'
    link: (scope, element, attrs) ->

        snColors =
            vk: '#EFF7FE'
            fb: '#F7FAFC'
            ok: '#FFFCF4'
            yt: '#FFF6F0' # '#FFF4EE'
            mm: '#F5FFFF'

        if scope.feed?
            communityService.getById scope.feed.communityId, (community) ->
                element.css
                    'background': snColors[community.socialNetwork]
        else if scope.lineId?
            communityService.getById scope.lineId, (community) ->
                element.css
                    'background': snColors[community.socialNetwork]

        true