local AceOO = AceLibrary("AceOO-2.0")
local BarManager = AceOO.Class()

function BarManager.prototype:init(mainFrame, stateManager)
    BarManager.super.prototype.init(self)

    self.mainFrame = mainFrame
    self.stateManager = stateManager
    self.barFrames = {}
end

function BarManager.prototype:Update()
    local newData = self.stateManager:GetBarData()

    -- Create bars that don't already exist for tracked items
    -- eg. On Initial setup, on going from item count 0 to > 0, on enabling of an item in settings
    self:CreateMissingBars(newData)

    -- Remove bars for tracked items that should no longer be shown
    -- eg. On going from item count > 0 to 0, on disabling of an item in settings
    self:RemoveStaleBars(newData)

    -- Sort bars based on current cooldowns and priorities
    self:SortBars()

    -- Update current bar positioning, labels, etc.
    self:UpdateBars(newData)
end

function BarManager.prototype:CreateMissingBars(newData)
    for index, newBar in ipairs(newData) do
        if not self:IsBarInArray(self.barFrames, newBar.key) then
            table.insert(self.barFrames, self:CreateBar(newBar))
        end
    end
end

function BarManager.prototype:IsBarInArray(array, key)
    for index, bar in ipairs(array) do
        -- Handle either an array of bar data objects, or BarFrame objects
        local barKey = bar.data and bar.data.key or bar.key
        if barKey == key then
            return true
        end
    end
    return false
end

function BarManager.prototype:CreateBar(data)
    local bar = ManaMinder.BarFrame:new(self.mainFrame.frame, data)
    return bar
end

function BarManager.prototype:RemoveStaleBars(newData)
    for i = table.getn(self.barFrames), 1, -1 do
        if not self:IsBarInArray(newData, self.barFrames[i].data.key) then
            self.barFrames[i]:Hide()
            table.remove(self.barFrames, i)
        end
    end
end

function BarManager.prototype:SortBars()
    table.sort(self.barFrames, function(barA, barB)
        if barA.data.cooldown == barB.data.cooldown then
            return barA.data.priority < barB.data.priority
        end
        return barA.data.cooldown < barB.data.cooldown
    end)
end

function BarManager.prototype:UpdateBars(newData)
    for i = 1, table.getn(self.barFrames), 1 do
        local bar = self.barFrames[i]
        for index, data in ipairs(newData) do
            if bar.data.key == data.key then
                bar.data = data
                bar:Update(i)
            end
        end
    end
end

ManaMinder.BarManager = BarManager