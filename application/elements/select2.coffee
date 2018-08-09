buzzlike.value("uiSelect2Config", {}).directive "uiSelect2", [
    "uiSelect2Config"
    "$timeout"
    "localization"
    (uiSelect2Config, $timeout, localization) ->
        options = {}
        angular.extend options, uiSelect2Config    if uiSelect2Config
        return (
            require: "ngModel"
            priority: 1
            compile: (tElm, tAttrs) ->
                tElm = $(tElm)
                watch = undefined
                repeatOption = undefined
                repeatAttr = undefined
                isSelect = tElm.is("select")
                isMultiple = angular.isDefined(tAttrs.multiple)
                
                # Enable watching of the options dataset if in use
                if tElm.is("select")
                    repeatOption = tElm.find("option[ng-repeat], option[data-ng-repeat]")
                    if repeatOption.length
                        repeatAttr = repeatOption.attr("ng-repeat") or repeatOption.attr("data-ng-repeat")
                        watch = jQuery.trim(repeatAttr.split("|")[0]).split(" ").pop()
                (scope, elm, attrs, controller) ->
                    
                    # instance-specific options
                    elm = $(elm)
                    opts = angular.extend({}, options, scope.$eval(attrs.uiSelect2))
                    
                    #
                    #        Convert from Select2 view-model to Angular view-model.
                    #        
                    convertToAngularModel = (select2_data) ->
                        model = undefined
                        if opts.simple_tags
                            model = []
                            angular.forEach select2_data, (value, index) ->
                                model.push value.id
                                return

                        else
                            model = select2_data
                        model

                    
                    #
                    #        Convert from Angular view-model to Select2 view-model.
                    #        
                    convertToSelect2Model = (angular_data) ->
                        model = []
                        return model    unless angular_data
                        if opts.simple_tags
                            model = []
                            angular.forEach angular_data, (value, index) ->
                                model.push
                                    id: value
                                    text: value

                                return

                        else
                            model = angular_data
                        model

                    if isSelect
                        
                        # Use <select multiple> instead
                        delete opts.multiple

                        delete opts.initSelection
                    else opts.multiple = true    if isMultiple
                    if controller
                        
                        # Watch the model for programmatic changes
                        scope.$watch tAttrs.ngModel, ((current, old) ->
                            return    unless current
                            return    if current is old
                            controller.$render()
                            return
                        ), true
                        controller.$render = ->
                            if isSelect
                                elm.select2 "val", controller.$viewValue
                            else
                                if opts.multiple
                                    viewValue = controller.$viewValue
                                    viewValue = viewValue.split(",")    if angular.isString(viewValue)
                                    elm.select2 "data", convertToSelect2Model(viewValue)
                                else
                                    if angular.isObject(controller.$viewValue)
                                        elm.select2 "data", controller.$viewValue
                                    else unless controller.$viewValue
                                        elm.select2 "data", null
                                    else
                                        elm.select2 "val", controller.$viewValue
                            return

                        
                        # Watch the options dataset for changes
                        if watch
                            scope.$watch watch, (newVal, oldVal, scope) ->
                                return    if angular.equals(newVal, oldVal)
                                controller.$render()
                                
                                # Delayed so that the options have time to be rendered
                                $timeout ->
                                    elm.select2 "val", controller.$viewValue
                                    
                                    # Refresh angular to remove the superfluous option
                                    elm.trigger "change"
                                    controller.$setPristine true    if newVal and not oldVal and controller.$setPristine
                                    return

                                return

                        
                        # Update valid and dirty statuses
                        controller.$parsers.push (value) ->
                            div = elm.prev()
                            div.toggleClass("ng-invalid", not controller.$valid).toggleClass("ng-valid", controller.$valid).toggleClass("ng-invalid-required", not controller.$valid).toggleClass("ng-valid-required", controller.$valid).toggleClass("ng-dirty", controller.$dirty).toggleClass "ng-pristine", controller.$pristine
                            value

                        unless isSelect
                            
                            # Set the view and model value and update the angular template manually for the ajax/multiple select2.
                            elm.bind "change", (e) ->
                                e.stopImmediatePropagation()
                                return    if scope.$$phase or scope.$root.$$phase
                                scope.$apply ->
                                    controller.$setViewValue convertToAngularModel(elm.select2("data"))
                                    return

                                return

                            if opts.initSelection
                                initSelection = opts.initSelection
                                opts.initSelection = (element, callback) ->
                                    initSelection element, (value) ->
                                        controller.$setViewValue convertToAngularModel(value)
                                        callback value
                                        return

                                    return
                    
                    # else {
                    #   elm.bind("change", function (e) {
                    #     e.stopImmediatePropagation();
                    #     console.log('sdfsdfsd');
                    #     controller.$setViewValue('123123');
                    #   })
                    # }
                    elm.bind "$destroy", ->
                        elm.select2 "destroy"
                        return

                    attrs.$observe "disabled", (value) ->
                        elm.select2 "enable", not value
                        return

                    attrs.$observe "readonly", (value) ->
                        elm.select2 "readonly", !!value
                        return

                    if attrs.ngMultiple
                        scope.$watch attrs.ngMultiple, (newVal) ->
                            attrs.$set "multiple", !!newVal
                            elm.select2 opts
                            return

                    
                    # Initialize the plugin late so that the injected DOM does not disrupt the template compiler
                    $timeout ->
                        elm.select2 opts
                        
                        # Set initial value - I'm not sure about this but it seems to need to be there
                        elm.val controller.$viewValue
                        
                        # important!
                        controller.$render()
                        
                        # Not sure if I should just check for !isSelect OR if I should check for 'tags' key
                        controller.$setViewValue convertToAngularModel(elm.select2("data"))    if not opts.initSelection and not isSelect
                        return

                    return
        )
]