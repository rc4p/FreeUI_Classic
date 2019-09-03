local F, C = unpack(select(2, ...))
local ACTIONBAR = F:GetModule('Actionbar')


ACTIONBAR.fader = {
	fadeInAlpha = 1,
	fadeInDuration = 0.3,
	fadeInSmooth = 'OUT',
	fadeOutAlpha = 0,
	fadeOutDuration = 0.9,
	fadeOutSmooth = 'OUT',
	fadeOutDelay = 0,
}

ACTIONBAR.faderOnShow = {
	fadeInAlpha = 1,
	fadeInDuration = 0.3,
	fadeInSmooth = 'OUT',
	fadeOutAlpha = 0,
	fadeOutDuration = 0.9,
	fadeOutSmooth = 'OUT',
	fadeOutDelay = 0,
	trigger = 'OnShow',
}

local function FaderOnFinished(self)
	self.__owner:SetAlpha(self.finAlpha)
end

local function FaderOnUpdate(self)
	self.__owner:SetAlpha(self.__animFrame:GetAlpha())
end

local function CreateFaderAnimation(frame)
	if frame.fader then return end
	local animFrame = CreateFrame('Frame', nil, frame)
	animFrame.__owner = frame
	frame.fader = animFrame:CreateAnimationGroup()
	frame.fader.__owner = frame
	frame.fader.__animFrame = animFrame
	frame.fader.direction = nil
	frame.fader.setToFinalAlpha = false --test if this will NOT apply the alpha to all regions
	frame.fader.anim = frame.fader:CreateAnimation('Alpha')
	frame.fader:HookScript('OnFinished', FaderOnFinished)
	frame.fader:HookScript('OnUpdate', FaderOnUpdate)
end

local function StartFadeIn(frame)
	if frame.fader.direction == 'in' then return end
	frame.fader:Pause()
	frame.fader.anim:SetFromAlpha(frame.faderConfig.fadeOutAlpha or 0)
	frame.fader.anim:SetToAlpha(frame.faderConfig.fadeInAlpha or 1)
	frame.fader.anim:SetDuration(frame.faderConfig.fadeInDuration or 0.3)
	frame.fader.anim:SetSmoothing(frame.faderConfig.fadeInSmooth or 'OUT')
	--start right away
	frame.fader.anim:SetStartDelay(frame.faderConfig.fadeInDelay or 0)
	frame.fader.finAlpha = frame.faderConfig.fadeInAlpha
	frame.fader.direction = 'in'
	frame.fader:Play()
end

local function StartFadeOut(frame)
	if frame.fader.direction == 'out' then return end
	frame.fader:Pause()
	frame.fader.anim:SetFromAlpha(frame.faderConfig.fadeInAlpha or 1)
	frame.fader.anim:SetToAlpha(frame.faderConfig.fadeOutAlpha or 0)
	frame.fader.anim:SetDuration(frame.faderConfig.fadeOutDuration or 0.3)
	frame.fader.anim:SetSmoothing(frame.faderConfig.fadeOutSmooth or 'OUT')
	--wait for some time before starting the fadeout
	frame.fader.anim:SetStartDelay(frame.faderConfig.fadeOutDelay or 0)
	frame.fader.finAlpha = frame.faderConfig.fadeOutAlpha
	frame.fader.direction = 'out'
	frame.fader:Play()
end

local function IsMouseOverFrame(frame)
	if MouseIsOver(frame) then return true end
	return false
end

local function FrameHandler(frame)
	if IsMouseOverFrame(frame) then
		StartFadeIn(frame)
	else
		StartFadeOut(frame)
	end
end

local function OffFrameHandler(self)
	if not self.__faderParent then return end
	FrameHandler(self.__faderParent)
end

local function OnShow(self)
	if self.fader then
		StartFadeIn(self)
	end
end

local function OnHide(self)
	if self.fader then
		StartFadeOut(self)
	end
end

local function CreateFrameFader(frame, faderConfig)
	if frame.faderConfig then return end
	frame.faderConfig = faderConfig
	CreateFaderAnimation(frame)

	if faderConfig.trigger and faderConfig.trigger == 'OnShow' then
		frame:HookScript('OnShow', OnShow)
		frame:HookScript('OnHide', OnHide)
	else
		frame:EnableMouse(true)
		frame:HookScript('OnEnter', FrameHandler)
		frame:HookScript('OnLeave', FrameHandler)
		FrameHandler(frame)
	end
end

function ACTIONBAR:CreateButtonFrameFader(buttonList, faderConfig)
	CreateFrameFader(self, faderConfig)
	if faderConfig.trigger and faderConfig.trigger == 'OnShow' then
		return
	end
	for _, button in next, buttonList do
		if not button.__faderParent then
			button.__faderParent = self
			button:HookScript('OnEnter', OffFrameHandler)
			button:HookScript('OnLeave', OffFrameHandler)
		end
	end
end

-- fix blizzard cooldown flash
local function FixCooldownFlash(self)
	if not self then return end
	if self:GetEffectiveAlpha() > 0 then
		self:Show()
	else
		self:Hide()
	end
end
hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', FixCooldownFlash)