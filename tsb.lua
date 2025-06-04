local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CONFIG = {
    TargetHipHeight = 100,
    ResetHipHeight = 0,
    HipHeightResetBeforeEnd = 1,
    DelayBeforeHipHeightChange = 2,
    TransitionTime = 0.5,
    TransitionTime2 = 0.5,
    EnableWarnings = true,
    
    OriginalAnimToReplace = "rbxassetid://12351854556",
    ReplacementAnim = "rbxassetid://17140902079",
    ReplacementTime = 2,

    OriginalAnimToReplace2 = "rbxassetid://13813955149",
    ReplacementAnim2 = "rbxassetid://79761806706382",
    ReplacementTime2 = 2,

    OriginalAnimToReplace3 = "rbxassetid://13814919604",
    ReplacementAnim3 = "rbxassetid://79761806706382",
    ReplacementTime3 = 1,
    ReplacementSpeed3 = 1.0,
}

local function optionalWarn(message)
    if CONFIG.EnableWarnings then
        warn(message)
    end
end

local function isFalling(h)
    local state = h:GetState()
    return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.FallingDown
end

local function transitionHipHeight(h, target, duration)
    local initial = h.HipHeight
    local elapsed = 0
    while elapsed < duration do
        elapsed += RunService.Heartbeat:Wait()
        local alpha = elapsed / duration
        if not isFalling(h) then
            h.HipHeight = initial + (target - initial) * alpha
        end
    end
    if not isFalling(h) then
        h.HipHeight = target
    end
end

local function setupCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    humanoid.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId
        
        if animId == CONFIG.OriginalAnimToReplace then
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = CONFIG.ReplacementAnim
            local animTrack = animator:LoadAnimation(newAnim)
            animTrack:Play()
            task.delay(CONFIG.ReplacementTime, function()
                if animTrack.IsPlaying then animTrack:Stop() end
                newAnim:Destroy()
            end)

        elseif animId == CONFIG.OriginalAnimToReplace2 then
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = CONFIG.ReplacementAnim2
            local animTrack = animator:LoadAnimation(newAnim)
            animTrack:Play()
            animTrack:AdjustSpeed(0)
            local waitStart = tick()
            while animTrack.Length == 0 and tick() - waitStart < 2 do task.wait(0.1) end
            animTrack.TimePosition = math.max(0, animTrack.Length - 1)
            animTrack:AdjustSpeed(1)
            task.delay(CONFIG.ReplacementTime2, function()
                if animTrack.IsPlaying then animTrack:Stop() end
                newAnim:Destroy()
            end)

        elseif animId == CONFIG.OriginalAnimToReplace3 then
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = CONFIG.ReplacementAnim3
            local animTrack = animator:LoadAnimation(newAnim)
            animTrack:Play()
            animTrack:AdjustSpeed(CONFIG.ReplacementSpeed3 or 1)
            task.delay(CONFIG.ReplacementTime3, function()
                if animTrack.IsPlaying then animTrack:Stop() end
                newAnim:Destroy()
            end)

        elseif animId:match("12296113986") then
            -- Функция проверки живости анимации
            local function isTrackPlaying()
                return track and track.IsPlaying
            end

            -- Задержка перед поднятием бедер
            task.delay(CONFIG.DelayBeforeHipHeightChange, function()
                if humanoid and humanoid.Parent and isTrackPlaying() and not isFalling(humanoid) then
                    transitionHipHeight(humanoid, CONFIG.TargetHipHeight, CONFIG.TransitionTime)
                end
            end)

            -- Время начала сброса HipHeight
            local totalLength = track.Length or 0
            local resetStart = totalLength - CONFIG.HipHeightResetBeforeEnd
            if resetStart < CONFIG.DelayBeforeHipHeightChange then
                resetStart = CONFIG.DelayBeforeHipHeightChange
            end

            -- Задержка перед сбросом бедер
            task.delay(resetStart, function()
                if humanoid and humanoid.Parent and isTrackPlaying() and not isFalling(humanoid) then
                    transitionHipHeight(humanoid, CONFIG.ResetHipHeight, CONFIG.TransitionTime2)
                end
            end)
        end
    end)
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)
