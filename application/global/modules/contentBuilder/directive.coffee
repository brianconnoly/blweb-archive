buzzlike.directive 'contentBuilder', (contentBuilder) ->
    restrict: "C"
    template: tC['/global/modules/contentBuilder']
    link: (scope, element, attrs) ->
        elem = $ element

        elem.find('.topbar').click contentBuilder.hide

        scope.add = contentBuilder.addObject

        scope.slideMenu = (tab, direction) ->
            elem.find('.tab.visible').removeClass('visible').addClass(direction)
            elem.find('.tab'+tab).removeClass('left').removeClass('right').addClass 'visible'

        scope.objectProperties = {
            #type: 'canvas'
            stroke: null
            fill: null
            opacity: null
        }

        scope.updateObjectProperties = (props) ->
            props.opacity *= 100 if props.opacity <= 1
            for i of props
                scope.objectProperties[i] = props[i]
            scope.objectProperties

        scope.getObjectProperties = () ->
            scope.objectProperties

        scope.updateSelected = (prop) ->
            props = {}
            if !prop
                for i of scope.objectProperties
                    props[i] = scope.objectProperties[i]
            else
                props[prop] = scope.objectProperties[prop]

            props.opacity /= 100 if props.opacity >= 1
            contentBuilder.updateSelected props
            #blog "changed", scope.objectProperties


        #scope.$watch "objectProperties", scope.updateSelected

        contentBuilder.setInterfaceFunctions {
            slideMenu             : scope.slideMenu
            getObjectProperties   : scope.getObjectProperties
            updateObjectProperties: scope.updateObjectProperties
        }

