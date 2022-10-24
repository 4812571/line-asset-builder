local WeightedChoice = require(script.Parent.WeightedChoice)

local LineAssetJob = {}
LineAssetJob.__index = LineAssetJob

function LineAssetJob.new(startChoice, middleChoice, endChoice, assetCount)
	local self = setmetatable({}, LineAssetJob)

	-- State Management
	self._assetCount = assetCount
	self._previousModel = nil
	self._previousCFrame = nil

	-- Randomization
	self._startChoice = startChoice
	self._middleChoice = middleChoice
	self._endChoice = endChoice

	return self
end

function LineAssetJob:_selectModel(index)
	if index == 1 then
		return self._startChoice:Choose()
	end

	if index == self._assetCount then
		return self._endChoice:Choose()
	end

	return self._middleChoice:Choose()
end

function LineAssetJob:GetNextPivot(nextModel)
	local rootSize = if self._previousModel then self._previousModel.PrimaryPart.Size else Vector3.new(0, 0, 0)
	local rootCFrame = if self._previousCFrame then self._previousCFrame else CFrame.new()

	local offset = Vector3.new(0.5, 0, 0) * (rootSize + nextModel.PrimaryPart.Size)

	return rootCFrame * CFrame.new(offset)
end

function LineAssetJob:Build()
	local finalModel = Instance.new("Model")
	finalModel.Name = "LineAssetResult"

	local models = {}

	for i = 1, self._assetCount do
		local modelTemplate = self:_selectModel(i)
		local nextPivot = self:GetNextPivot(modelTemplate)

		local model = modelTemplate:Clone()
		model:PivotTo(nextPivot)
		table.insert(models, model)

		self._previousModel = model
		self._previousCFrame = model.PrimaryPart.CFrame
	end

	finalModel.WorldPivot = models[1].PrimaryPart.CFrame

	for _, model in ipairs(models) do
		model.Parent = finalModel
	end

	return finalModel
end

local LineAssetBuilder = {}
LineAssetBuilder.__index = LineAssetBuilder

function LineAssetBuilder:_buildChoice(models)
	local choice = WeightedChoice.new()

	for _, model in ipairs(models) do
		local weight = model:GetAttribute("Weight") or 1
		choice:AddChoice(model, weight)
	end

	return choice
end

function LineAssetBuilder.new(startModels, middleModels, endModels)
	local self = setmetatable({}, LineAssetBuilder)

	self._startChoice = self:_buildChoice(startModels)
	self._middleChoice = self:_buildChoice(middleModels)
	self._endChoice = self:_buildChoice(endModels)

	return self
end

function LineAssetBuilder:Build(assetCount)
	return LineAssetJob.new(self._startChoice, self._middleChoice, self._endChoice, assetCount):Build()
end

return LineAssetBuilder