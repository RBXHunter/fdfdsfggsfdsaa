local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CONFIG = {
    -- Бедра и тяга
    TargetHipHeight = 100,
    ResetHipHeight = 0,
    HipHeightResetBeforeEnd = 1,
    TransitionTime = 0.5,
    TransitionTime2 = 0,
    InitialWait = 0,
    StopWait = 1,
    DisableBeforeEnd = 0.3,
    ForceDisableBeforeEnd = 0.3,
    ForceSpeedHip = 150,
    ForceSpeedPull = 200,
    DisableBeforeEndPull = 0.8,
    TeleportY = 441,
    EnableWarnings = true,

    -- Первая замена анимации
    OriginalAnimToReplace = "rbxassetid://12351854556",
    ReplacementAnim = "rbxassetid://17140902079",
    ReplacementTime = 2,

    -- Вторая замена (рывок)
    OriginalAnimToReplace2 = "rbxassetid://13813955149",
    ReplacementAnim2 = "rbxassetid://79761806706382",
    ReplacementTime2 = 2,

    -- Третья замена (на 1 секунду)
    OriginalAnimToReplace3 = "rbxassetid://13814919604",
    ReplacementAnim3 = "rbxassetid://79761806706382",
    ReplacementTime3 = 1,
    ReplacementSpeed3 = 1.0,

    -- После телепорта
    AnimAfterTeleport = "rbxassetid://17141153099",
    AnimAfterTeleportTime = 2,
}

-- Ускоренный бег
local RUN_ANIM_ID = "rbxassetid://17354976067"
local ANIM_START_TIME = 4
local ANIM_SPEED = 1.5
local LAST_SEC_SKIP = 2.3
local RUN_SPEED_BOOST = 150
local BOOST_INTERVAL = 0.1

local holding = false
local runAnimTrack = nil
local monitorConnection = nil
local boostConnection = nil
local character, humanoid

local function optionalWarn(msg)
    if CONFIG.EnableWarnings then warn(msg) end
end

local function isFalling(h)
    local s = h:GetState()
    return s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.FallingDown
end

local function transitionHipHeight(h, target, duration)
    local start = h.HipHeight
    local elapsed = 0
    while elapsed < duration do
        elapsed += RunService.Heartbeat:Wait()
        local alpha = elapsed / duration
        if not isFalling(h) then
            h.HipHeight = start + (target - start) * alpha
        end
    end
    if not isFalling(h) then
        h.HipHeight = target
    end
end

local function applyPull(track, h)
    local root = h.Parent:FindFirstChild("HumanoidRootPart")
    if not root then optionalWarn("No HumanoidRootPart") return end
    local alive = true
    h.Died:Connect(function() alive = false end)
    local startTime = tick()
    local len = track.Length or 0
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not alive or not track.IsPlaying then
            root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
            conn:Disconnect()
            return
        end
        if tick() - startTime >= len - CONFIG.DisableBeforeEndPull then
            root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
            conn:Disconnect()
            return
        end
        local look = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or Vector3.new()
        local dir = Vector3.new(look.X, 0, look.Z).Unit
        root.Velocity = dir * CONFIG.ForceSpeedPull + Vector3.new(0, root.Velocity.Y, 0)
    end)
end

local function stopMonitor()
    if monitorConnection then monitorConnection:Disconnect() monitorConnection = nil end
end

local function stopBoostLoop()
    if boostConnection then boostConnection:Disconnect() boostConnection = nil end
end

local function playAnimation()
    for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do t:Stop() end
    if runAnimTrack then runAnimTrack:Stop() runAnimTrack:Destroy() runAnimTrack = nil end

    local anim = Instance.new("Animation")
    anim.AnimationId = RUN_ANIM_ID
    runAnimTrack = humanoid:LoadAnimation(anim)
    runAnimTrack.Looped = true
    runAnimTrack:Play()
    runAnimTrack.TimePosition = ANIM_START_TIME
    runAnimTrack:AdjustSpeed(ANIM_SPEED)

    local maxWait = 2
    local startTime = tick()
    while runAnimTrack.Length == 0 and tick() - startTime < maxWait do task.wait(0.1) end

    local len = runAnimTrack.Length
    if len == 0 then warn("Анимация не загрузилась или имеет нулевую длину.") return end

    stopMonitor()
    monitorConnection = RunService.Heartbeat:Connect(function()
        if not runAnimTrack or not runAnimTrack.IsPlaying then stopMonitor() return end
        if runAnimTrack.TimePosition >= len - LAST_SEC_SKIP then
            runAnimTrack.TimePosition = ANIM_START_TIME
        end
    end)
end

local function startRunning()
    playAnimation()
    stopBoostLoop()
    boostConnection = RunService.Heartbeat:Connect(function()
        if holding then
            humanoid.WalkSpeed = 16 + RUN_SPEED_BOOST
        end
    end)
end

local function stopRunning()
    stopMonitor()
    stopBoostLoop()
    if runAnimTrack then runAnimTrack:Stop() runAnimTrack:Destroy() runAnimTrack = nil end
    humanoid.WalkSpeed = 16
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Z and not holding then
        holding = true
        startRunning()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Z then
        holding = false
        stopRunning()
    end
end)

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    stopRunning()

    humanoid.AnimationPlayed:Connect(function(track)
        local animId = track.Animation.AnimationId

        if animId == CONFIG.OriginalAnimToReplace then
            track:Stop()
            local new = Instance.new("Animation")
            new.AnimationId = CONFIG.ReplacementAnim
            local t = animator:LoadAnimation(new)
            t:Play()
            task.delay(CONFIG.ReplacementTime, function() if t.IsPlaying then t:Stop() end new:Destroy() end)

        elseif animId == CONFIG.OriginalAnimToReplace2 then
            track:Stop()
            local new2 = Instance.new("Animation")
            new2.AnimationId = CONFIG.ReplacementAnim2
            local t2 = animator:LoadAnimation(new2)
            t2:Play()
            t2:AdjustSpeed(0)
            local waitStart = tick()
            while t2.Length == 0 and tick() - waitStart < 2 do task.wait(0.1) end
            t2.TimePosition = math.max(0, t2.Length - 1)
            t2:AdjustSpeed(1)
            task.delay(CONFIG.ReplacementTime2, function() if t2.IsPlaying then t2:Stop() end new2:Destroy() end)

        elseif animId == CONFIG.OriginalAnimToReplace3 then
            track:Stop()
            local new3 = Instance.new("Animation")
            new3.AnimationId = CONFIG.ReplacementAnim3
            local t3 = animator:LoadAnimation(new3)
            t3:Play()
            t3:AdjustSpeed(CONFIG.ReplacementSpeed3 or 1)
            task.delay(CONFIG.ReplacementTime3, function() if t3.IsPlaying then t3:Stop() end new3:Destroy() end)

        elseif animId:match("12296113986") then
            while isFalling(humanoid) do task.wait(0.1) end
            transitionHipHeight(humanoid, CONFIG.TargetHipHeight, CONFIG.TransitionTime)
            local resetTime = CONFIG.HipHeightResetBeforeEnd or CONFIG.DisableBeforeEnd
            task.delay(track.Length - resetTime, function()
                transitionHipHeight(humanoid, CONFIG.ResetHipHeight, CONFIG.TransitionTime2)
                task.wait(resetTime)
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos = root.Position
                    root.CFrame = CFrame.new(pos.X, CONFIG.TeleportY, pos.Z)
                    local postAnim = Instance.new("Animation")
                    postAnim.AnimationId = CONFIG.AnimAfterTeleport
                    local t = humanoid:LoadAnimation(postAnim)
                    t:Play()
                    task.delay(CONFIG.AnimAfterTeleportTime, function() if t.IsPlaying then t:Stop() end postAnim:Destroy() end)
                end
            end)

        elseif animId:match("12273188754") then
            applyPull(track, humanoid)
        end
    end)
end

-- Инициализация
task.wait(CONFIG.InitialWait)
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
