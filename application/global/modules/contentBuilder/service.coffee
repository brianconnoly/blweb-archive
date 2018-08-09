buzzlike.factory 'contentBuilder', ($compile, $rootScope, stateManager) ->
    elem = null
    container = null
    scope = null
    originalImage = new Image()

    canvas = null
    objects = null

    scale = 1

    maxWidth = 1200
    maxHeight = maxWidth * 9 / 16

    Interface = {}
    selected = []

    # define defaulte params
    fillColor = '#ffffff'
    strokeColor = '#ffffff'

    init = (img) ->
        #if img.type != 'image' then return true

        show()
        window.canvas = canvas = new fabric.Canvas('canvas')
        fabric.Object.prototype.cornerSize = 9
        fabric.Object.prototype.cornerColor = '#ffffff'
        fabric.Object.prototype.borderColor = '#3facef'
        fabric.Object.prototype.transparentCorners = false
        objects = canvas._objects
        setEvents()

        # objects.nullObj = new fabric.Square() # get ready to keep always in target (fabric's bug)

        # Нужно создать Image заново, т.к. повторно хром ругается на CORS
        # Грузим картинку повторно, т.к. загруженная скорее всего уже сжата браузером
        originalImage = new Image()
        originalImage.src = img.src

        container = elem.find('.canvas-container')
        objects.original = new fabric.Image originalImage #, {width: originalImage.width, height: originalImage.height}

        if !originalImage.onload then originalImage.onload = ->
            calculateImageSizeToWindow(this)

            canvas.add objects.original
            canvas.calcOffset() #Включаем редактор, возможность двигать и ресайзить

    calculateImageSizeToWindow = (img, width, height) ->
        w = img.width
        h = img.height
        scale = 1

        #Сначала уменьшаем картинку до максимально доступного размера
        if w > maxWidth then W = maxWidth
        if h > maxHeight then H = maxHeight

        kw = W/w
        kh = H/h

        scale = kh if scale>kh
        scale = kw if scale>kw

        w = img.width *= scale
        h = img.height *= scale

        #Затем уменьшаем полотно
        scale = 1

        W = width  || window.innerWidth
        H = height || window.innerHeight - 42

        if W > maxWidth then W = maxWidth
        if H > maxHeight then H = maxHeight

        kw = W/w
        kh = H/h

        scale = kh if scale>kh
        scale = kw if scale>kw

        canvas.setWidth  w * scale
        canvas.setHeight h * scale

        objects.original.scaleToWidth canvas.width
        objects.original.visible = false

        #objects.original.borderColor = '#3facef'
        #objects.original.cornerColor = '#ffffff'
        #objects.original.transparentCorners = false
        #objects.original.cornerSize = 9


        container.css({
            position: "absolute"
            top: "50%"
            left: "50%"
            marginTop: -canvas.height/2 + 'px'
            marginLeft: -canvas.width/2 + 'px'
            background: "url("+img.src+") no-repeat"
            backgroundSize: canvas.width+"px "+canvas.height+"px"
            #transform: "scale("+scale+")" #ни в коем случае не использовать!
        })


        #img.width = w*scale
        #img.height = h*scale


    show = ->
        if !elem
            state = {
                noMenu: true
                delete: removeSelected
            }
            scope = $rootScope.$new()
            elem = $compile('<div class="shader contentBuilder"></div>')(scope)
            $('.nwflw_view').append elem
            elem = $ elem
            stateManager.applyState state

    hide = ->
        scope.$destroy()
        elem.remove()

        elem = scope = canvas = null
        stateManager.goBack()

    addObject = (name) ->
        ->
            switch name
                when 'Circle'
                    obj = createCircle.apply this, arguments
                when 'Triangle'
                    obj = createTriangle.apply this, arguments
                when 'Rect'
                    obj = createRect.apply this, arguments
                when 'Line'
                    obj = createLine.apply this, arguments
                else
                    obj = null

            if !obj then return false

            obj.id = objects.length
            canvas.add obj
            canvas.setActiveObject obj
            #obj.center()

            #blog "created", name, arguments?, objects, obj


    createCircle = (prop) ->
        prop = prop || {
            top: 0
            left: 0
            radius: 50
            fill: fillColor
            type: "Circle"
            perPixelTargetFind: true
        }
        obj = new fabric.Circle prop


    createTriangle = (prop) ->
        prop = prop || {
            top: 0
            left: 0
            width: 100
            height: 100
            fill: fillColor
            type: "Triangle"
            perPixelTargetFind: true
        }
        obj = new fabric.Triangle prop

    createRect = (prop) ->
        prop = prop || {
            top: 0
            left: 0
            width: 80
            height: 80
            fill: fillColor
            type: "Rect"
            perPixelTargetFind: true
        }
        obj = new fabric.Rect prop

    createLine = (coords, prop) ->
        # coords: [x1, y1, x2, y2]
        coords = coords || [100, 0, 0, 100]
        prop = prop || {
            #top: 0
            #left: 0
            stroke: strokeColor
            strokeWidth: 3
            type: "Line"
            originX: 'center'
            originY: 'center'
            hasControls: false
            hasRotatingPoint: false
            perPixelTargetFind: true
        }
        obj = new fabric.Line coords, prop


    addFreeControls = (obj) ->
        #created for lines, polylines, curves and polygons
        controls = []
        if obj.type == 'Line'
            controls.push
                x: obj.x1
                y: obj.y1
                properties: ['x1', 'y1']
            controls.push
                x: obj.x2
                y: obj.y2
                properties: ['x2', 'y2']

            ltPoint = obj.getPointByOrigin('left', 'top')
            for i in controls
                control = new fabric.Circle
                    type: 'FreeControl'
                    properties: i.properties
                    left: i.x + ltPoint.x
                    top:  i.y + ltPoint.y
                    radius: 5
                    stroke: '#000000'
                    fill: '#ffffff'
                    hasBorders: false
                    hasControls: false
                    originX: 'center'
                    originY: 'center'

                canvas.add control
                controls[_i] = control
            obj.freeControls = controls

        obj.set "angle", 0
        canvas.calcOffset()
        controls

    drawFreeControls = (obj) ->
        if obj.type == 'Line'
            if obj.active
                ltPoint = obj.getPointByOrigin('left', 'top')
                for i in obj.freeControls
                    left = ltPoint.x + obj[i.properties[0]]
                    top  = ltPoint.y + obj[i.properties[1]]
                    if i.left != left or i.top != top
                        i.set
                            left: left
                            top: top
            else
                newCoords = {}
                ltPoint = {}
                for i in obj.freeControls
                    #blog "moving", i
                    x = i.left
                    y = i.top

                    newCoords[i.properties[0]] = x
                    newCoords[i.properties[1]] = y
                    blog 'coords set', i.properties, newCoords, obj, left, top

                    ltPoint.x = x if x < ltPoint.x or !ltPoint.x
                    ltPoint.y = y if y < ltPoint.y or !ltPoint.y

                for i of newCoords
                    newCoords[i] -= ltPoint.x if i.indexOf('x')+1
                    newCoords[i] -= ltPoint.y if i.indexOf('y')+1

                obj.set newCoords
                obj.setPositionByOrigin new fabric.Point(ltPoint.x, ltPoint.y), 'left', 'top'

        canvas.calcOffset()
        canvas.renderAll()
        true

    renewActiveBorders = (obj) ->
        group = new fabric.Group([obj], {})
        canvas.setActiveGroup group
        canvas.deactivateAll()
        group = null
        canvas.setActiveObject obj

    #events
    setEvents = ->
        canvas
            .on "object:selected", (props) ->
                #Если щёлкаем по FreeControl или FreeCenter, ничего не меняем
                if canvas._activeObject?.type?.indexOf('Free')+1
                    #canvas.setActiveObject selected[0] if selected[0].freeControls
                    blog 'free control selected'
                    return true

                Interface.slideMenu('.properties', 'left')
                selected = props.target._objects ||  [props.target]

                properties = {}
                propertyList = selected[0].stateProperties
                #blog 'property list:', propertyList
                for i in propertyList
                    properties[i] = selected[0].get i

                Interface.updateObjectProperties properties

                #удаляем все наши кастомные указатели перед прорисовкой новых
                toRemove = []
                for i in objects
                    if i.freeControls then i.freeControls = null
                    if i.type.indexOf('Free')+1 then toRemove.push i
                for i in toRemove
                    i.remove()
                #а тут рисуем новые
                object = selected[0]
                if selected.length == 1 and !object.freeControls
                    controls = addFreeControls object


            .on "selection:cleared", ->
                blog 'select'
                Interface.slideMenu('.menu', 'right')
                selected.length = 0

                #удаляем контролы
                toRemove = []
                for i in objects
                    if i.freeControls then i.freeControls = null
                    if i.type.indexOf('Free')+1 then toRemove.push i
                for i in toRemove
                    i.remove()

                true

            .on "object:moving", (props) ->
                object = selected[0]
                if selected.length == 1 and object.freeControls
                    drawFreeControls object

                true

            .on "after:render", (props) ->
                true

            .on "mouse:up", ->
                object = selected[0]
                if selected.length == 1 and object.freeControls
                    renewActiveBorders object


    updateSelected = (props) ->
        for i in selected
            for p of props
                i[p] = props[p]
        canvas.renderAll()

    setInterfaceFunctions = (funcs) ->
        for f of funcs
            Interface[f] = funcs[f]

    removeSelected = ->
        for i in selected
            i.remove()
        canvas.discardActiveGroup().renderAll()


    # utils
    getObjectById = (id) ->
        for i in objects
            if i.id == id then return i
        true

    {
        init
        show
        hide

        addObject
        updateSelected
        removeSelected

        setInterfaceFunctions
    }