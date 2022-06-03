local function Dropdown(name)
    local base = Object(name)
    local objectType = "Dropdown"
    base.width = 12
    base.height = 1
    base.bgColor = theme.dropdownBG
    base.fgColor = theme.dropdownFG
    base:setZIndex(6)

    local list = {}
    local itemSelectedBG = theme.selectionBG
    local itemSelectedFG = theme.selectionFG
    local selectionColorActive = true
    local align = "left"
    local yOffset = 0

    local dropdownW = 16
    local dropdownH = 6
    local closedSymbol = "\16"
    local openedSymbol = "\31"
    local state = 1

    local object = {
        getType = function(self)
            return objectType
        end;

        setIndexOffset = function(self, yOff)
            yOffset = yOff
            return self
        end;

        getIndexOffset = function(self)
            return yOffset
        end;

        addItem = function(self, text, bgCol, fgCol, ...)
            table.insert(list, { text = text, bgCol = bgCol or self.bgColor, fgCol = fgCol or self.fgColor, args = { ... } })
            return self
        end;

        getAll = function(self)
            return list
        end;

        removeItem = function(self, index)
            table.remove(list, index)
            return self
        end;

        getItem = function(self, index)
            return list[index]
        end;

        getItemIndex = function(self)
            local selected = self:getValue()
            for key, value in pairs(list) do
                if (value == selected) then
                    return key
                end
            end
        end;

        clear = function(self)
            list = {}
            self:setValue({})
            return self
        end;

        getItemCount = function(self)
            return #list
        end;

        editItem = function(self, index, text, bgCol, fgCol, ...)
            table.remove(list, index)
            table.insert(list, index, { text = text, bgCol = bgCol or self.bgColor, fgCol = fgCol or self.fgColor, args = { ... } })
            return self
        end;

        selectItem = function(self, index)
            self:setValue(list[index] or {})
            return self
        end;

        setSelectedItem = function(self, bgCol, fgCol, active)
            itemSelectedBG = bgCol or self.bgColor
            itemSelectedFG = fgCol or self.fgColor
            selectionColorActive = active
            return self
        end;

        setDropdownSize = function(self, width, height)
            dropdownW, dropdownH = width, height
            return self
        end;

        mouseClickHandler = function(self, event, button, x, y)
            if (state == 2) then
                local obx, oby = self:getAbsolutePosition(self:getAnchorPosition())
                if ((event == "mouse_click") and (button == 1)) or (event == "monitor_touch") then

                    if (#list > 0) then
                        for n = 1, dropdownH do
                            if (list[n + yOffset] ~= nil) then
                                if (obx <= x) and (obx + dropdownW > x) and (oby + n == y) then
                                    self:setValue(list[n + yOffset])
                                    return true
                                end
                            end
                        end
                    end
                end

                if (event == "mouse_scroll") then
                    yOffset = yOffset + button
                    if (yOffset < 0) then
                        yOffset = 0
                    end
                    if (button == 1) then
                        if (#list > dropdownH) then
                            if (yOffset > #list - dropdownH) then
                                yOffset = #list - dropdownH
                            end
                        else
                            yOffset = list - 1
                        end
                    end
                    return true
                end
                self:setVisualChanged()
            end
            if (base.mouseClickHandler(self, event, button, x, y)) then
                state = 2
            else
                state = 1
            end
        end;

        draw = function(self)
            if (base.draw(self)) then
                local obx, oby = self:getAnchorPosition()
                if (self.parent ~= nil) then
                    self.parent:drawBackgroundBox(obx, oby, self.width, self.height, self.bgColor)
                    if (#list >= 1) then
                        if (self:getValue() ~= nil) then
                            if (self:getValue().text ~= nil) then
                                if (state == 1) then
                                    self.parent:writeText(obx, oby, getTextHorizontalAlign(self:getValue().text, self.width, align):sub(1, self.width - 1) .. closedSymbol, self.bgColor, self.fgColor)
                                else
                                    self.parent:writeText(obx, oby, getTextHorizontalAlign(self:getValue().text, self.width, align):sub(1, self.width - 1) .. openedSymbol, self.bgColor, self.fgColor)
                                end
                            end
                        end
                        if (state == 2) then
                            for n = 1, dropdownH do
                                if (list[n + yOffset] ~= nil) then
                                    if (list[n + yOffset] == self:getValue()) then
                                        if (selectionColorActive) then
                                            self.parent:writeText(obx, oby + n, getTextHorizontalAlign(list[n + yOffset].text, dropdownW, align), itemSelectedBG, itemSelectedFG)
                                        else
                                            self.parent:writeText(obx, oby + n, getTextHorizontalAlign(list[n + yOffset].text, dropdownW, align), list[n + yOffset].bgCol, list[n + yOffset].fgCol)
                                        end
                                    else
                                        self.parent:writeText(obx, oby + n, getTextHorizontalAlign(list[n + yOffset].text, dropdownW, align), list[n + yOffset].bgCol, list[n + yOffset].fgCol)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end;
    }

    return setmetatable(object, base)
end