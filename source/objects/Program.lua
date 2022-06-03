local function Program(name)
    local base = Object(name)
    local objectType = "Program"
    base:setZIndex(5)
    local object

    local function createBasaltWindow(x, y, width, height)
        local xCursor, yCursor = 1, 1
        local bgColor, fgColor = colors.black, colors.white
        local cursorBlink = false
        local visible = false

        local cacheT = {}
        local cacheBG = {}
        local cacheFG = {}

        local tPalette = {}

        local emptySpaceLine
        local emptyColorLines = {}

        for i = 0, 15 do
            local c = 2 ^ i
            tPalette[c] = { parentTerminal.getPaletteColour(c) }
        end

        local function createEmptyLines()
            emptySpaceLine = (" "):rep(width)
            for n = 0, 15 do
                local nColor = 2 ^ n
                local sHex = tHex[nColor]
                emptyColorLines[nColor] = sHex:rep(width)
            end
        end

        local function recreateWindowArray()
            createEmptyLines()
            local emptyText = emptySpaceLine
            local emptyFG = emptyColorLines[colors.white]
            local emptyBG = emptyColorLines[colors.black]
            for n = 1, height do
                cacheT[n] = sub(cacheT[n] == nil and emptyText or cacheT[n] .. emptyText:sub(1, width - cacheT[n]:len()), 1, width)
                cacheFG[n] = sub(cacheFG[n] == nil and emptyFG or cacheFG[n] .. emptyFG:sub(1, width - cacheFG[n]:len()), 1, width)
                cacheBG[n] = sub(cacheBG[n] == nil and emptyBG or cacheBG[n] .. emptyBG:sub(1, width - cacheBG[n]:len()), 1, width)
            end
        end
        recreateWindowArray()

        local function updateCursor()
            if xCursor >= 1 and yCursor >= 1 and xCursor <= width and yCursor <= height then
                --parentTerminal.setCursorPos(xCursor + x - 1, yCursor + y - 1)
            else
                --parentTerminal.setCursorPos(0, 0)
            end
            --parentTerminal.setTextColor(fgColor)
        end

        local function internalBlit(sText, sTextColor, sBackgroundColor)
            -- copy pasti strikes again (cc: window.lua)
            local nStart = xCursor
            local nEnd = nStart + #sText - 1
            if yCursor >= 1 and yCursor <= height then
                if nStart <= width and nEnd >= 1 then
                    -- Modify line
                    if nStart == 1 and nEnd == width then
                        cacheT[yCursor] = sText
                        cacheFG[yCursor] = sTextColor
                        cacheBG[yCursor] = sBackgroundColor
                    else
                        local sClippedText, sClippedTextColor, sClippedBackgroundColor
                        if nStart < 1 then
                            local nClipStart = 1 - nStart + 1
                            local nClipEnd = width - nStart + 1
                            sClippedText = sub(sText, nClipStart, nClipEnd)
                            sClippedTextColor = sub(sTextColor, nClipStart, nClipEnd)
                            sClippedBackgroundColor = sub(sBackgroundColor, nClipStart, nClipEnd)
                        elseif nEnd > width then
                            local nClipEnd = width - nStart + 1
                            sClippedText = sub(sText, 1, nClipEnd)
                            sClippedTextColor = sub(sTextColor, 1, nClipEnd)
                            sClippedBackgroundColor = sub(sBackgroundColor, 1, nClipEnd)
                        else
                            sClippedText = sText
                            sClippedTextColor = sTextColor
                            sClippedBackgroundColor = sBackgroundColor
                        end

                        local sOldText = cacheT[yCursor]
                        local sOldTextColor = cacheFG[yCursor]
                        local sOldBackgroundColor = cacheBG[yCursor]
                        local sNewText, sNewTextColor, sNewBackgroundColor
                        if nStart > 1 then
                            local nOldEnd = nStart - 1
                            sNewText = sub(sOldText, 1, nOldEnd) .. sClippedText
                            sNewTextColor = sub(sOldTextColor, 1, nOldEnd) .. sClippedTextColor
                            sNewBackgroundColor = sub(sOldBackgroundColor, 1, nOldEnd) .. sClippedBackgroundColor
                        else
                            sNewText = sClippedText
                            sNewTextColor = sClippedTextColor
                            sNewBackgroundColor = sClippedBackgroundColor
                        end
                        if nEnd < width then
                            local nOldStart = nEnd + 1
                            sNewText = sNewText .. sub(sOldText, nOldStart, width)
                            sNewTextColor = sNewTextColor .. sub(sOldTextColor, nOldStart, width)
                            sNewBackgroundColor = sNewBackgroundColor .. sub(sOldBackgroundColor, nOldStart, width)
                        end

                        cacheT[yCursor] = sNewText
                        cacheFG[yCursor] = sNewTextColor
                        cacheBG[yCursor] = sNewBackgroundColor
                    end
                end
                xCursor = nEnd + 1
                if (visible) then
                    updateCursor()
                end
            end
        end

        local function setText(_x, _y, text)
            if (text ~= nil) then
                local gText = cacheT[_y]
                if (gText ~= nil) then
                    cacheT[_y] = sub(gText:sub(1, _x - 1) .. text .. gText:sub(_x + (text:len()), width), 1, width)
                end
            end
        end

        local function setBG(_x, _y, colorStr)
            if (colorStr ~= nil) then
                local gBG = cacheBG[_y]
                if (gBG ~= nil) then
                    cacheBG[_y] = sub(gBG:sub(1, _x - 1) .. colorStr .. gBG:sub(_x + (colorStr:len()), width), 1, width)
                end
            end
        end

        local function setFG(_x, _y, colorStr)
            if (colorStr ~= nil) then
                local gFG = cacheFG[_y]
                if (gFG ~= nil) then
                    cacheFG[_y] = sub(gFG:sub(1, _x - 1) .. colorStr .. gFG:sub(_x + (colorStr:len()), width), 1, width)
                end
            end
        end

        local setTextColor = function(color)
            if type(color) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(color) .. ")", 2)
            elseif tHex[color] == nil then
                error("Invalid color (got " .. color .. ")", 2)
            end
            fgColor = color
        end

        local setBackgroundColor = function(color)
            if type(color) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(color) .. ")", 2)
            elseif tHex[color] == nil then
                error("Invalid color (got " .. color .. ")", 2)
            end
            bgColor = color
        end

        local setPaletteColor = function(colour, r, g, b)
            -- have to work on
            if type(colour) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(colour) .. ")", 2)
            end

            if tHex[colour] == nil then
                error("Invalid color (got " .. colour .. ")", 2)
            end

            local tCol
            if type(r) == "number" and g == nil and b == nil then
                tCol = { colours.rgb8(r) }
                tPalette[colour] = tCol
            else
                if type(r) ~= "number" then
                    error("bad argument #2 (expected number, got " .. type(r) .. ")", 2)
                end
                if type(g) ~= "number" then
                    error("bad argument #3 (expected number, got " .. type(g) .. ")", 2)
                end
                if type(b) ~= "number" then
                    error("bad argument #4 (expected number, got " .. type(b) .. ")", 2)
                end

                tCol = tPalette[colour]
                tCol[1] = r
                tCol[2] = g
                tCol[3] = b
            end
        end

        local getPaletteColor = function(colour)
            if type(colour) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(colour) .. ")", 2)
            end
            if tHex[colour] == nil then
                error("Invalid color (got " .. colour .. ")", 2)
            end
            local tCol = tPalette[colour]
            return tCol[1], tCol[2], tCol[3]
        end

        local basaltwindow = {
            setCursorPos = function(_x, _y)
                if type(_x) ~= "number" then
                    error("bad argument #1 (expected number, got " .. type(_x) .. ")", 2)
                end
                if type(_y) ~= "number" then
                    error("bad argument #2 (expected number, got " .. type(_y) .. ")", 2)
                end
                xCursor = math.floor(_x)
                yCursor = math.floor(_y)
                if (visible) then
                    updateCursor()
                end
            end;

            getCursorPos = function()
                return xCursor, yCursor
            end;

            setCursorBlink = function(blink)
                if type(blink) ~= "boolean" then
                    error("bad argument #1 (expected boolean, got " .. type(blink) .. ")", 2)
                end
                cursorBlink = blink
            end;

            getCursorBlink = function()
                return cursorBlink
            end;


            getPaletteColor = getPaletteColor,
            getPaletteColour = getPaletteColor,

            setBackgroundColor = setBackgroundColor,
            setBackgroundColour = setBackgroundColor,

            setTextColor = setTextColor,
            setTextColour = setTextColor,

            setPaletteColor = setPaletteColor,
            setPaletteColour = setPaletteColor,

            getBackgroundColor = function()
                return bgColor
            end;
            getBackgroundColour = function()
                return bgColor
            end;

            getSize = function()
                return width, height
            end;

            getTextColor = function()
                return fgColor
            end;
            getTextColour = function()
                return fgColor
            end;

            basalt_resize = function(_width, _height)
                width, height = _width, _height
                recreateWindowArray()
            end;

            basalt_reposition = function(_x, _y)
                x, y = _x, _y
            end;

            basalt_setVisible = function(vis)
                visible = vis
            end;

            drawBackgroundBox = function(_x, _y, _width, _height, bgCol)
                for n = 1, _height do
                    setBG(_x, _y + (n - 1), tHex[bgCol]:rep(_width))
                end
            end;
            drawForegroundBox = function(_x, _y, _width, _height, fgCol)
                for n = 1, _height do
                    setFG(_x, _y + (n - 1), tHex[fgCol]:rep(_width))
                end
            end;
            drawTextBox = function(_x, _y, _width, _height, symbol)
                for n = 1, _height do
                    setText(_x, _y + (n - 1), symbol:rep(_width))
                end
            end;

            writeText = function(_x, _y, text, bgCol, fgCol)
                bgCol = bgCol or bgColor
                fgCol = fgCol or fgColor
                setText(x, _y, text)
                setBG(_x, _y, tHex[bgCol]:rep(text:len()))
                setFG(_x, _y, tHex[fgCol]:rep(text:len()))
            end;

            basalt_update = function()
                if (object.parent ~= nil) then
                    for n = 1, height do
                        object.parent:setText(x, y + (n - 1), cacheT[n])
                        object.parent:setBG(x, y + (n - 1), cacheBG[n])
                        object.parent:setFG(x, y + (n - 1), cacheFG[n])
                    end
                end
            end;

            scroll = function(offset)
                if type(offset) ~= "number" then
                    error("bad argument #1 (expected number, got " .. type(offset) .. ")", 2)
                end
                if offset ~= 0 then
                    local sEmptyText = emptySpaceLine
                    local sEmptyTextColor = emptyColorLines[fgColor]
                    local sEmptyBackgroundColor = emptyColorLines[bgColor]
                    for newY = 1, height do
                        local y = newY + offset
                        if y >= 1 and y <= height then
                            cacheT[newY] = cacheT[y]
                            cacheBG[newY] = cacheBG[y]
                            cacheFG[newY] = cacheFG[y]
                        else
                            cacheT[newY] = sEmptyText
                            cacheFG[newY] = sEmptyTextColor
                            cacheBG[newY] = sEmptyBackgroundColor
                        end
                    end
                end
                if (visible) then
                    updateCursor()
                end
            end;


            isColor = function()
                return parentTerminal.isColor()
            end;

            isColour = function()
                return parentTerminal.isColor()
            end;

            write = function(text)
                text = tostring(text)
                if (visible) then
                    internalBlit(text, tHex[fgColor]:rep(text:len()), tHex[bgColor]:rep(text:len()))
                end
            end;

            clearLine = function()
                if (visible) then
                    setText(1, yCursor, (" "):rep(width))
                    setBG(1, yCursor, tHex[bgColor]:rep(width))
                    setFG(1, yCursor, tHex[fgColor]:rep(width))
                end
                if (visible) then
                    updateCursor()
                end
            end;

            clear = function()
                for n = 1, height do
                    setText(1, n, (" "):rep(width))
                    setBG(1, n, tHex[bgColor]:rep(width))
                    setFG(1, n, tHex[fgColor]:rep(width))
                end
                if (visible) then
                    updateCursor()
                end
            end;

            blit = function(text, fgcol, bgcol)
                if type(text) ~= "string" then
                    error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
                end
                if type(fgcol) ~= "string" then
                    error("bad argument #2 (expected string, got " .. type(fgcol) .. ")", 2)
                end
                if type(bgcol) ~= "string" then
                    error("bad argument #3 (expected string, got " .. type(bgcol) .. ")", 2)
                end
                if #fgcol ~= #text or #bgcol ~= #text then
                    error("Arguments must be the same length", 2)
                end
                if (visible) then
                    --setText(xCursor, yCursor, text)
                    --setBG(xCursor, yCursor, bgcol)
                    --setFG(xCursor, yCursor, fgcol)
                    --xCursor = xCursor+text:len()
                    internalBlit(text, fgcol, bgcol)
                end
            end


        }

        return basaltwindow
    end

    base.width = 30
    base.height = 12
    local pWindow = createBasaltWindow(1, 1, base.width, base.height)
    local curProcess
    local paused = false
    local queuedEvent = {}

    object = {
        getType = function(self)
            return objectType
        end;

        show = function(self)
            base.show(self)
            pWindow.setBackgroundColor(self.bgColor)
            pWindow.setTextColor(self.fgColor)
            pWindow.basalt_setVisible(true)
            return self
        end;

        hide = function(self)
            base.hide(self)
            pWindow.basalt_setVisible(false)
            return self
        end;

        setPosition = function(self, x, y, rel)
            base.setPosition(self, x, y, rel)
            pWindow.basalt_reposition(self:getAnchorPosition())
            return self
        end;

        getBasaltWindow = function()
            return pWindow
        end;

        getBasaltProcess = function()
            return curProcess
        end;

        setSize = function(self, width, height)
            base.setSize(self, width, height)
            pWindow.basalt_resize(self.width, self.height)
            return self
        end;

        getStatus = function(self)
            if (curProcess ~= nil) then
                return curProcess:getStatus()
            end
            return "inactive"
        end;

        execute = function(self, path, ...)
            curProcess = process:new(path, pWindow, ...)
            pWindow.setBackgroundColor(colors.black)
            pWindow.setTextColor(colors.white)
            pWindow.clear()
            pWindow.setCursorPos(1, 1)
            curProcess:resume()
            paused = false
            return self
        end;

        stop = function(self)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    curProcess:resume("terminate")
                    if (curProcess:isDead()) then
                        if (self.parent ~= nil) then
                            self.parent:setCursor(false)
                        end
                    end
                end
            end
            return self
        end;

        pause = function(self, p)
            paused = p or (not paused)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    if not (paused) then
                        self:injectEvents(queuedEvent)
                        queuedEvent = {}
                    end
                end
            end
            return self
        end;

        isPaused = function(self)
            return paused
        end;

        injectEvent = function(self, event, p1, p2, p3, p4, ign)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    if (paused == false) or (ign) then
                        curProcess:resume(event, p1, p2, p3, p4)
                    else
                        table.insert(queuedEvent, { event = event, args = { p1, p2, p3, p4 } })
                    end
                end
            end
            return self
        end;

        getQueuedEvents = function(self)
            return queuedEvent
        end;

        updateQueuedEvents = function(self, events)
            queuedEvent = events or queuedEvent
            return self
        end;

        injectEvents = function(self, events)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    for _, value in pairs(events) do
                        curProcess:resume(value.event, table.unpack(value.args))
                    end
                end
            end
            return self
        end;

        mouseClickHandler = function(self, event, button, x, y)
            if (base.mouseClickHandler(self, event, button, x, y)) then
                if (curProcess == nil) then
                    return false
                end
                if not (curProcess:isDead()) then
                    if not (paused) then
                        local absX, absY = self:getAbsolutePosition(self:getAnchorPosition(nil, nil, true))
                        curProcess:resume(event, button, x - absX + 1, y - absY + 1)
                    end
                end
                return true
            end
        end;

        keyHandler = function(self, event, key)
            base.keyHandler(self, event, key)
            if (self:isFocused()) then
                if (curProcess == nil) then
                    return false
                end
                if not (curProcess:isDead()) then
                    if not (paused) then
                        if (self.draw) then
                            curProcess:resume(event, key)
                        end
                    end
                end
            end
        end;

        getFocusHandler = function(self)
            base.getFocusHandler(self)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    if not (paused) then
                        if (self.parent ~= nil) then
                            local xCur, yCur = pWindow.getCursorPos()
                            local obx, oby = self:getAnchorPosition()
                            if (self.parent ~= nil) then
                                if (obx + xCur - 1 >= 1 and obx + xCur - 1 <= obx + self.width - 1 and yCur + oby - 1 >= 1 and yCur + oby - 1 <= oby + self.height - 1) then
                                    self.parent:setCursor(pWindow.getCursorBlink(), obx + xCur - 1, yCur + oby - 1, pWindow.getTextColor())
                                end
                            end
                        end
                    end
                end
            end
        end;

        loseFocusHandler = function(self)
            base.loseFocusHandler(self)
            if (curProcess ~= nil) then
                if not (curProcess:isDead()) then
                    if (self.parent ~= nil) then
                        self.parent:setCursor(false)
                    end
                end
            end
        end;

        eventHandler = function(self, event, p1, p2, p3, p4)
            if (curProcess == nil) then
                return
            end
            if not (curProcess:isDead()) then
                if not (paused) then
                    if (event ~= "mouse_click") and (event ~= "monitor_touch") and (event ~= "mouse_up") and (event ~= "mouse_scroll") and (event ~= "mouse_drag") and (event ~= "key_up") and (event ~= "key") and (event ~= "char") and (event ~= "terminate") then
                        curProcess:resume(event, p1, p2, p3, p4)
                    end
                    if (self:isFocused()) then
                        local obx, oby = self:getAnchorPosition()
                        local xCur, yCur = pWindow.getCursorPos()
                        if (self.parent ~= nil) then
                            if (obx + xCur - 1 >= 1 and obx + xCur - 1 <= obx + self.width - 1 and yCur + oby - 1 >= 1 and yCur + oby - 1 <= oby + self.height - 1) then
                                self.parent:setCursor(pWindow.getCursorBlink(), obx + xCur - 1, yCur + oby - 1, pWindow.getTextColor())
                            end
                        end

                        if (event == "terminate") and (self:isFocused()) then
                            self:stop()
                        end
                    end
                else
                    if (event ~= "mouse_click") and (event ~= "monitor_touch") and (event ~= "mouse_up") and (event ~= "mouse_scroll") and (event ~= "mouse_drag") and (event ~= "key_up") and (event ~= "key") and (event ~= "char") and (event ~= "terminate") then
                        table.insert(queuedEvent, { event = event, args = { p1, p2, p3, p4 } })
                    end
                end
            end
        end;

        draw = function(self)
            if (base.draw(self)) then
                if (self.parent ~= nil) then
                    local obx, oby = self:getAnchorPosition()
                    pWindow.basalt_reposition(obx, oby)
                    self.parent:drawBackgroundBox(obx, oby, self.width, self.height, self.bgColor)
                    pWindow.basalt_update()
                end
            end
        end;

    }

    return setmetatable(object, base)
end