buzzlike.service 'actionsService', () ->

    handlers = {}
    parsers = {}

    getContextTypes = (code, context, separator = '_') ->
        res = [code + separator + context.type]
        if parsers[context?.type]?
            types = parsers[context?.type]?(context)
            for type in types
                res.push code + separator + type
        res

    getCodes = (type, items, data) ->
        code = type
        pre_codes = []
        codes = []

        if data.targetOnly
            pre_codes.push code
            pre_codes.push code + '_1'    if items.items.length == 1
            pre_codes.push code + '_many' if items.items.length >  1
        else
            codes.push code
            codes.push code + '_1'    if items.items.length == 1
            codes.push code + '_many' if items.items.length >  1

        if data.sourceContext?.type?
            addPre = []
            for code in pre_codes
                addPre = addPre.concat getContextTypes code, data.sourceContext, '&'
            pre_codes = pre_codes.concat addPre

            for code in codes
                codes = codes.concat getContextTypes code, data.sourceContext, '&'

        if data.target?.type?
            addCodes = []
            for code in codes
                addCodes = addCodes.concat getContextTypes code, data.target
            codes = codes.concat addCodes

            for code in pre_codes
                codes = codes.concat getContextTypes code, data.target

        if data.context?.type?
            for code in codes
                codes = codes.concat getContextTypes code, data.context, '@'

        codes


    getPhrases = () ->
        phrases = []
        for code, codeHandlers of handlers
            for handler in codeHandlers
                phrases.push 'entityAction_' + handler.phrase if 'entityAction_' + handler.phrase not in phrases

        phrases

    getActions = (data) -> # (items, context, contextOnly = false, actionsType) ->
        types = {}
        actions = []
        usedHandlers = []

        if !data.source?
            data.source = []

        for item in data.source
            if item == data.target
                continue
            types[item.type] = {items:[],ids:[]} if !types[item.type]?
            types[item.type].items.push item
            types[item.type].ids.push item.id

            if parsers[item.type]?
                additionalTypes = parsers[item.type](item)
                for type in additionalTypes
                    types[type] = {items:[],ids:[]} if !types[type]?
                    types[type].items.push item
                    types[type].ids.push item.id

        if data.source.length == 0 and !data.targetOnly
            types[''] =
                ids: []
                items: []

        for type,items of types
            codes = []
            code  = type

            codes = getCodes type, items, data

            for code in codes
                if handlers[code]?
                    for handler in handlers[code]
                        if data.actionsType? and handler.restrict == data.actionsType
                            continue
                        if handler.only? and handler.only != data.actionsType
                            continue

                        if handler.check?
                            if !handler.check(items.ids, items.items, data.target, data.context)
                                continue

                        if handler.check2?
                            if !handler.check2(
                                    items: items.items
                                    item: items.items[0]
                                    ids: items.ids
                                    target: data.target
                                    context: data.context
                                    sourceContext: data.sourceContext
                                    scope: data.scope
                                )
                                continue

                        do (code, items, handler) ->
                            actions.push
                                category: handler.category
                                order: handler.order
                                phrase: 'entityAction_' + handler.phrase if handler.phrase?
                                realText: handler.realText
                                leaveItems: handler.leaveItems
                                restrict: handler.restrict
                                priority: handler.priority or 0
                                action: (e, _items, _ids) ->
                                    handler.action
                                        items: _items or items.items
                                        item: _items?[0] or items.items[0]
                                        ids: _ids or items.ids
                                        target: data.target
                                        context: data.context
                                        sourceContext: data.sourceContext
                                        e: e
                                        scope: data.scope
                                    items.items
        actions

    # sourceType / entity type
    # sourceNumber / 1(one) or 0(many)
    # targetType
    registerAction = (data) ->
        if data.sourceType?
            types = data.sourceType.split('/')
        else
            types = ['']

        codes = []

        for type in types
            code  = type
            code += '_' + data.sourceNumber if data.sourceNumber+'' in ['1','many']
            code += '&' + data.sourceContext if data.sourceContext

            if data.targetType?
                targetTypes = data.targetType.split '/'
                for targetType in targetTypes
                    targetCode  = code + '_' + targetType
                    targetCode += '@' + data.contextType if data.contextType?

                    codes.push targetCode

            else
                code += '@' + data.contextType if data.contextType?
                codes.push code


        for code in codes
            handlers[code] = [] if !handlers[code]?
            handlers[code].push data
        true

    registerParser = (type, parser) ->
        types = type.split '/'
        for type in types
            parsers[type] = parser

    {
        getActions
        getPhrases

        registerAction
        registerParser
    }
