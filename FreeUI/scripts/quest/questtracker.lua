local F, C, L = unpack(select(2, ...))
local QUEST = F:GetModule('Quest')


local pairs = pairs
local LE_QUEST_FREQUENCY_DAILY = LE_QUEST_FREQUENCY_DAILY or 2

function QUEST:QuestTracker()
	-- Mover for quest tracker
	local frame = CreateFrame('Frame', 'FreeUIQuestTrackerMover', UIParent)
	frame:SetSize(240, 50)
	F.Mover(frame, L['MOVER_OBJECTIVE_TRACKER'], 'QuestTracker', {'TOPRIGHT', UIParent, 'TOPRIGHT', -50, -300})

	local tracker = QuestWatchFrame
	tracker:SetHeight(GetScreenHeight()*.65)
	tracker:SetClampedToScreen(false)
	tracker:SetMovable(true)
	if tracker:IsMovable() then tracker:SetUserPlaced(true) end

	hooksecurefunc(tracker, 'SetPoint', function(self, _, parent)
		if parent == 'MinimapCluster' or parent == _G.MinimapCluster then
			self:ClearAllPoints()
			self:SetPoint('TOPLEFT', frame, 5, -5)
		end
	end)

	local header = CreateFrame('Frame', nil, frame)
	header:SetAllPoints(frame)
	header:Hide()
	header.text = F.CreateFS(header, {C.font.header, 14}, QUEST_LOG, 'yellow', true, 'TOPLEFT', 0, 15)

	local bg = header:CreateTexture(nil, 'ARTWORK')
	bg:SetTexture('Interface\\LFGFrame\\UI-LFG-SEPARATOR')
	bg:SetTexCoord(0, .66, 0, .31)
	bg:SetVertexColor(C.r, C.g, C.b, .8)
	bg:SetPoint('TOPLEFT', 0, 20)
	bg:SetSize(120, 30)

	-- Show quest color and level
	local function Showlevel(self)
		local numEntries, numQuests = GetNumQuestLogEntries()

		header.text:SetText(QUEST_LOG..' '..numQuests..'/'..MAX_QUESTLOG_QUESTS)

		for i = 1, QUESTS_DISPLAYED, 1 do
			local questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
			local questLogTitle = _G['QuestLogTitle'..i]
			local questCheck = _G['QuestLogTitle'..i..'Check']

			if questIndex <= numEntries then
				local questLogTitleText, level, _, isHeader, _, isComplete, frequency = GetQuestLogTitle(questIndex)

				if not isHeader then
					questLogTitleText = '['..level..'] '..questLogTitleText
					if isComplete then
						questLogTitleText = '|cffff78ff'..questLogTitleText
					elseif frequency == LE_QUEST_FREQUENCY_DAILY then
						questLogTitleText = '|cff3399ff'..questLogTitleText
					end

					questLogTitle:SetText(questLogTitleText)
					questCheck:SetPoint('LEFT', questLogTitle, questLogTitle:GetWidth()-22, 0)
				end
			end
		end
	end
	hooksecurefunc('QuestLog_Update', Showlevel)


	

	for i = 1, 30 do
		local Line = _G["QuestWatchLine"..i]

		F.SetFS(Line, {C.font.normal, 14}, nil, nil, {0, 0, 0, 1, 2, -2})
		Line:SetHeight(16)
	end

	-- ModernQuestWatch, Ketho
	local function onMouseUp(self)
		if IsShiftKeyDown() then -- untrack quest
			local questID = GetQuestIDFromLogIndex(self.questIndex)
			for index, value in ipairs(QUEST_WATCH_LIST) do
				if value.id == questID then
					tremove(QUEST_WATCH_LIST, index)
				end
			end
			RemoveQuestWatch(self.questIndex)
			QuestWatch_Update()
		else -- open to quest log
			if QuestLogEx then -- https://www.wowinterface.com/downloads/info24980-QuestLogEx.html
				ShowUIPanel(QuestLogExFrame)
				QuestLogEx:QuestLog_SetSelection(self.questIndex)
				QuestLogEx:Maximize()
			elseif ClassicQuestLog then -- https://www.wowinterface.com/downloads/info24937-ClassicQuestLogforClassic.html
				ShowUIPanel(ClassicQuestLog)
				QuestLog_SetSelection(self.questIndex)
			else
				ShowUIPanel(QuestLogFrame)
				QuestLog_SetSelection(self.questIndex)
				local valueStep = QuestLogListScrollFrame.ScrollBar:GetValueStep()
				QuestLogListScrollFrame.ScrollBar:SetValue(self.questIndex*valueStep/2)
			end
		end
		QuestLog_Update()
	end

	local function onEnter(self)
		if self.completed then
			-- use normal colors instead as highlight
			self.headerText:SetTextColor(.75, .61, 0)
			for _, text in ipairs(self.objectiveTexts) do
				text:SetTextColor(.8, .8, .8)
			end
		else
			self.headerText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b) -- 1, .82, 0
			for _, text in ipairs(self.objectiveTexts) do
				text:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b) -- 1, 1, 1
			end
		end
	end

	local ClickFrames = {}
	local function SetClickFrame(watchIndex, questIndex, headerText, objectiveTexts, completed)
		if not ClickFrames[watchIndex] then
			ClickFrames[watchIndex] = CreateFrame('Frame')
			ClickFrames[watchIndex]:SetScript('OnMouseUp', onMouseUp)
			ClickFrames[watchIndex]:SetScript('OnEnter', onEnter)
			ClickFrames[watchIndex]:SetScript('OnLeave', QuestWatch_Update)
		end

		local f = ClickFrames[watchIndex]
		f:SetAllPoints(headerText)
		f.watchIndex = watchIndex
		f.questIndex = questIndex
		f.headerText = headerText
		f.objectiveTexts = objectiveTexts
		f.completed = completed
	end

	hooksecurefunc('QuestWatch_Update', function()
		header:SetShown(tracker:IsShown())

		local watchTextIndex = 1
		for i = 1, GetNumQuestWatches() do
			local questIndex = GetQuestIndexForWatch(i)
			if questIndex then
				local numObjectives = GetNumQuestLeaderBoards(questIndex)
				if numObjectives > 0 then
					local headerText = _G['QuestWatchLine'..watchTextIndex]
					--F.SetFS(headerText, {C.font.normal, 14}, nil, nil, nil, true)
					if watchTextIndex > 1 then
						headerText:SetPoint('TOPLEFT', 'QuestWatchLine'..(watchTextIndex - 1), 'BOTTOMLEFT', 0, -10)
					end
					watchTextIndex = watchTextIndex + 1
					local objectivesGroup = {}
					local objectivesCompleted = 0
					for j = 1, numObjectives do
						local finished = select(3, GetQuestLogLeaderBoard(j, questIndex))
						if finished then
							objectivesCompleted = objectivesCompleted + 1
						end
						_G['QuestWatchLine'..watchTextIndex]:SetPoint('TOPLEFT', 'QuestWatchLine'..(watchTextIndex - 1), 'BOTTOMLEFT', 0, -5)
						tinsert(objectivesGroup, _G['QuestWatchLine'..watchTextIndex])
						watchTextIndex = watchTextIndex + 1
					end
					SetClickFrame(i, questIndex, headerText, objectivesGroup, objectivesCompleted == numObjectives)
				end
			end
		end
		-- hide/show frames so it doesnt eat clicks, since we cant parent to a FontString
		for _, frame in pairs(ClickFrames) do
			frame[GetQuestIndexForWatch(frame.watchIndex) and 'Show' or 'Hide'](frame)
		end
	end)

	local function autoQuestWatch(_, questIndex)
		-- tracking otherwise untrackable quests (without any objectives) would still count against the watch limit
		-- calling AddQuestWatch() while on the max watch limit silently fails
		if GetCVarBool('autoQuestWatch') and GetNumQuestLeaderBoards(questIndex) ~= 0 and GetNumQuestWatches() < MAX_WATCHABLE_QUESTS then
			AutoQuestWatch_Insert(questIndex, QUEST_WATCH_NO_EXPIRE)
		end
	end
	F:RegisterEvent('QUEST_ACCEPTED', autoQuestWatch)
end