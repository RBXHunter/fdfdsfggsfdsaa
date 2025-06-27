local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 5)

-- Проверка доступности PlayerGui
if not playerGui then
    warn("PlayerGui не найден!")
    return
end

-- Единый интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterExploitGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 120, 0, 40)
button.Position = UDim2.new(0, 10, 0, 10)
button.Text = "Kill Script"
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 16
button.Parent = screenGui

-- Глобальный флаг для управления скриптами
_G.isScriptEnabled = true

-- Список соединений для очистки
local connections = {}

-- Список скриптов (код включен напрямую для тестирования)
local scripts = {
    -- Скрипт 1: Телепортация (1skill_sonicteleport.lua с задержкой 0.2 сек и ориентацией в сторону игрока)
    [[
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local FREEZE_ANIM_IDS = { ["13376869471"]=true, ["13309500827"]=true }

        local connections = {}
        local currentTarget = nil
        local lookAtTargetUntil = 0

        local function createTargetIndicator(target)
            if not target or not target:FindFirstChild("Head") then return end
            if target:FindFirstChild("TargetGui") then return end

            local bb = Instance.new("BillboardGui", target)
            bb.Name = "TargetGui"
            bb.Size = UDim2.new(4, 0, 4, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = target.Head

            local frame = Instance.new("Frame", bb)
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundTransparency = 0.5
            frame.BackgroundColor3 = Color3.new(1, 0, 0)
            frame.BorderSizePixel = 0
        end

        local function clearIndicators()
            local liveFolder = workspace:FindFirstChild("Live")
            if liveFolder then
                for _, model in pairs(liveFolder:GetChildren()) do
                    if model:FindFirstChild("TargetGui") then
                        model.TargetGui:Destroy()
                    end
                end
            end
        end

        local function findTarget()
            local cam = workspace.CurrentCamera
            if not cam then return nil end

            local origin = cam.CFrame.Position
            local dir = cam.CFrame.LookVector

            local best, bestDot = nil, -1
            for _, model in pairs(workspace.Live:GetChildren()) do
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if model ~= player.Character and hrp then
                    local to = (hrp.Position - origin)
                    local dist = to.Magnitude
                    if dist <= 100 then
                        local dot = dir:Dot(to.Unit)
                        if dot >= 0.86 and dot > bestDot then
                            bestDot = dot
                            best = model
                        end
                    end
                end
            end

            clearIndicators()
            if best then createTargetIndicator(best) end
            return best
        end

        local isFrozen = false
        local freezePos = nil

        local function setup(char)
            local humanoid = char:WaitForChild("Humanoid", 5)
            local root = char:WaitForChild("HumanoidRootPart", 5)
            local animator = humanoid:FindFirstChildWhichIsA("Animator")

            if not (humanoid and root and animator) then
                warn("Ошибка инициализации телепортации")
                return
            end

            local animConnection = animator.AnimationPlayed:Connect(function(tr)
                if not _G.isScriptEnabled then return end
                local id = tr.Animation.AnimationId:match("%d+")
                if FREEZE_ANIM_IDS[id] then
                    isFrozen = true
                    currentTarget = findTarget()
                    if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
                        local hrp = currentTarget.HumanoidRootPart
                        local back = -hrp.CFrame.LookVector * 3
                        local pos = hrp.Position + back + Vector3.new(0, 2, 0)
                        local targetPos = hrp.Position -- Смотрим в сторону игрока

                        local newCFrame = CFrame.new(pos, targetPos)
                        task.wait(0.2) -- Задержка 0.2 секунды перед телепортацией
                        if not _G.isScriptEnabled then return end
                        root.CFrame = newCFrame
                        root.Velocity = Vector3.new(0, root.Velocity.Y, 0)

                        local cam = workspace.CurrentCamera
                        if cam then cam.CFrame = newCFrame end

                        freezePos = pos
                    else
                        freezePos = root.Position
                        currentTarget = nil
                    end

                    local stopConnection = tr.Stopped:Connect(function()
                        if not _G.isScriptEnabled then
                            isFrozen = false
                            freezePos = nil
                            currentTarget = nil
                            clearIndicators()
                            return
                        end
                        -- Продолжаем смотреть в сторону игрока еще 0.1 секунды
                        lookAtTargetUntil = tick() + 0.1
                        task.delay(0.1, function()
                            if not _G.isScriptEnabled then return end
                            isFrozen = false
                            freezePos = nil
                            currentTarget = nil
                            clearIndicators()
                        end)
                    end)
                    table.insert(connections, stopConnection)
                end
            end)
            table.insert(connections, animConnection)

            local heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not _G.isScriptEnabled then
                    isFrozen = false
                    freezePos = nil
                    currentTarget = nil
                    return
                end
                if not isFrozen and tick() > lookAtTargetUntil then return end
                if not char:IsDescendantOf(workspace) then return end
                if not currentTarget or not currentTarget:FindFirstChild("HumanoidRootPart") then return end

                local hrp = currentTarget.HumanoidRootPart
                local pos = root.Position
                local targetPos = hrp.Position -- Смотрим в сторону игрока
                root.CFrame = CFrame.new(Vector3.new(freezePos.X, pos.Y, freezePos.Z), targetPos)
                root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
            end)
            table.insert(connections, heartbeatConnection)

            local renderConnection = RunService.RenderStepped:Connect(function()
                if not _G.isScriptEnabled then return end
                findTarget()
            end)
            table.insert(connections, renderConnection)
        end

        if player.Character then task.spawn(setup, player.Character) end
        local charConnection = player.CharacterAdded:Connect(function(char)
            if not _G.isScriptEnabled then return end
            setup(char)
        end)
        table.insert(connections, charConnection)
    ]],
    -- Скрипт 2: Замена анимации (2skill_sonic.txt)
    [[
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local OLD_ANIMATION_ID = "rbxassetid://13294790250"
        local NEW_ANIMATION_ID = "rbxassetid://12467789963"

        local connections = {}

        local function setup()
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local animator = humanoid:WaitForChild("Animator")

            local animationConnection = animator.AnimationPlayed:Connect(function(animationTrack)
                if not _G.isScriptEnabled then return end
                if animationTrack.Animation.AnimationId == OLD_ANIMATION_ID then
                    animationTrack:Stop()
                    local newAnimation = Instance.new("Animation")
                    newAnimation.AnimationId = NEW_ANIMATION_ID
                    local newTrack = animator:LoadAnimation(newAnimation)
                    newTrack:Play()
                    task.wait(1.5)
                    if newTrack.IsPlaying and _G.isScriptEnabled then
                        newTrack:Stop()
                    end
                end
            end)
            table.insert(connections, animationConnection)
        end

        if player.Character then
            task.spawn(setup)
        end

        local characterConnection = player.CharacterAdded:Connect(function()
            if not _G.isScriptEnabled then return end
            setup()
        end)
        table.insert(connections, characterConnection)
    ]],
    -- Скрипт 3: Полет (3skill_sonic.txt, исправленная версия)
    [[
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local task = task

        local player = Players.LocalPlayer
        if not player then
            player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
        end

        local FLY_ANIM_IDS = {
            ["13376962659"] = true,
            ["13362587853"] = true,
        }
        local FLY_DELAY = 0.3
        local FLY_DURATION = 1.5
        local FLY_SPEED = 150

        local isFlying = false
        local flyEndTime = 0
        local connections = {}

        local function setupCharacter(char)
            print("[FlightScript] Инициализация персонажа:", char.Name)
            local humanoid = char:WaitForChild("Humanoid", 5)
            local rootPart = char:WaitForChild("HumanoidRootPart", 5)
            if not (humanoid and rootPart) then
                warn("[FlightScript] Ошибка: Humanoid или HumanoidRootPart не найдены")
                return
            end

            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
                print("[FlightScript] Создан новый Animator")
            end

            local animConnection = animator.AnimationPlayed:Connect(function(track)
                if not _G.isScriptEnabled then
                    print("[FlightScript] Скрипт отключен, игнорируем анимацию")
                    return
                end
                local animId = track.Animation.AnimationId:gsub("rbxassetid://", "")
                print("[FlightScript] Обнаружена анимация:", animId)

                if FLY_ANIM_IDS[animId] then
                    if isFlying then
                        print("[FlightScript] Полет уже активен, игнорируем")
                        return
                    end
                    print("[FlightScript] Анимация полета обнаружена, старт через", FLY_DELAY, "сек")
                    task.delay(FLY_DELAY, function()
                        if not _G.isScriptEnabled or isFlying then
                            print("[FlightScript] Полет отменен: скрипт отключен или уже летим")
                            return
                        end
                        print("[FlightScript] Старт полета на", FLY_DURATION, "сек")
                        isFlying = true
                        flyEndTime = tick() + FLY_DURATION
                    end)
                end
            end)
            table.insert(connections, animConnection)

            local heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not _G.isScriptEnabled then
                    if isFlying then
                        isFlying = false
                        if rootPart then
                            rootPart.Velocity = Vector3.new(0, 0, 0)
                            print("[FlightScript] Полет остановлен: скрипт отключен")
                        end
                    end
                    return
                end
                if not isFlying then return end
                if not humanoid or not rootPart or not char:IsDescendantOf(workspace) then
                    isFlying = false
                    print("[FlightScript] Полет остановлен: персонаж недоступен")
                    return
                end

                if tick() > flyEndTime then
                    isFlying = false
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                    print("[FlightScript] Полет завершен по времени")
                    return
                end

                local cam = workspace.CurrentCamera
                if not cam then
                    print("[FlightScript] Камера недоступна")
                    return
                end

                local look = cam.CFrame.LookVector
                local velocity = look * FLY_SPEED
                rootPart.Velocity = velocity
                print("[FlightScript] Установлена скорость полета:", velocity)
            end)
            table.insert(connections, heartbeatConnection)
        end

        if player.Character then
            task.spawn(function()
                setupCharacter(player.Character)
            end)
        end
        local charConnection = player.CharacterAdded:Connect(function(char)
            if not _G.isScriptEnabled then
                print("[FlightScript] Скрипт отключен, пропуск инициализации персонажа")
                return
            end
            setupCharacter(char)
        end)
        table.insert(connections, charConnection)
    ]],
    -- Скрипт 4: Удар в землю (4_и_удар_в_землю.txt)
    [[
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer

        local targetAnimations = {
            ["13378708199"] = {newId = "rbxassetid://18897624255", startTime = 1.7, stopAfter = true},
            ["10470104242"] = {newId = "rbxassetid://129651400898906", startTime = 0.2, stopAfter = false}
        }

        local humanoid
        local currentNewTrack = nil
        local isReplacing = false
        local connections = {}

        local function fadeOutAnimation(track, fadeTime)
            local steps = 20
            local stepTime = fadeTime / steps
            for i = 1, steps do
                if not track.IsPlaying or not _G.isScriptEnabled then return end
                local weight = 1 * (1 - (i / steps))
                track:AdjustWeight(weight, 0)
                task.wait(stepTime)
            end
            if track.IsPlaying then
                track:Stop()
            end
        end

        local function stopCurrentAnimation()
            if not _G.isScriptEnabled then return end
            if currentNewTrack and currentNewTrack.IsPlaying then
                local animId = string.gsub(currentNewTrack.Animation.AnimationId, "rbxassetid://", "")
                local animConfig = nil
                for _, v in pairs(targetAnimations) do
                    if v.newId == currentNewTrack.Animation.AnimationId then
                        animConfig = v
                        break
                    end
                end
                if animConfig and animConfig.stopAfter then
                    fadeOutAnimation(currentNewTrack, 0.3)
                end
                currentNewTrack = nil
                isReplacing = false
            end
        end

        local function replaceAnimation(trackToStop, targetId)
            if not _G.isScriptEnabled or isReplacing or not humanoid then return end
            isReplacing = true

            if trackToStop and trackToStop.IsPlaying then
                trackToStop:Stop()
            end
            stopCurrentAnimation()

            local animData = targetAnimations[targetId]
            if not animData then
                isReplacing = false
                return
            end

            local newAnimation = Instance.new("Animation")
            newAnimation.AnimationId = animData.newId
            local newTrack = humanoid:LoadAnimation(newAnimation)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0, 1, 2)
            currentNewTrack = newTrack

            task.delay(0.05, function()
                if newTrack.IsPlaying and _G.isScriptEnabled then
                    newTrack.TimePosition = animData.startTime
                end
            end)

            if animData.stopAfter then
                task.delay(0.25, function()
                    if newTrack.IsPlaying and _G.isScriptEnabled then
                        fadeOutAnimation(newTrack, 0.3)
                        currentNewTrack = nil
                        isReplacing = false
                    end
                end)
            else
                task.delay(0.5, function()
                    isReplacing = false
                end)
            end
        end

        local function setupHumanoid(newHumanoid)
            humanoid = newHumanoid
            currentNewTrack = nil
            isReplacing = false

            local animationConnection = humanoid.AnimationPlayed:Connect(function(track)
                if not _G.isScriptEnabled then return end
                local id = string.gsub(track.Animation.AnimationId, "rbxassetid://", "")
                if targetAnimations[id] then
                    replaceAnimation(track, id)
                elseif currentNewTrack and id ~= string.gsub(currentNewTrack.Animation.AnimationId, "rbxassetid://", "") then
                    stopCurrentAnimation()
                end
            end)
            table.insert(connections, animationConnection)

            local heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not _G.isScriptEnabled or not humanoid then return end
                local foundTarget = false
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    local id = string.gsub(track.Animation.AnimationId, "rbxassetid://", "")
                    if targetAnimations[id] then
                        replaceAnimation(track, id)
                        foundTarget = true
                        break
                    end
                end
                if not foundTarget and humanoid.MoveDirection.Magnitude > 0 then
                    stopCurrentAnimation()
                end
            end)
            table.insert(connections, heartbeatConnection)
        end

        local function onCharacterAdded(character)
            if not _G.isScriptEnabled then return end
            local newHumanoid = character:WaitForChild("Humanoid")
            setupHumanoid(newHumanoid)
        end

        if player.Character then
            onCharacterAdded(player.Character)
        end
        local charConnection = player.CharacterAdded:Connect(onCharacterAdded)
        table.insert(connections, charConnection)
    ]],
    -- Скрипт 5: Замена анимации (4skill_sonic.txt)
    [[
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local OLD_ANIMATION_ID = "rbxassetid://13501296372"
        local NEW_ANIMATION_ID = "rbxassetid://16746824621"

        local connections = {}

        local function handleAnimations(character)
            local humanoid = character:WaitForChild("Humanoid")
            local animator = humanoid:WaitForChild("Animator")

            local animationConnection = animator.AnimationPlayed:Connect(function(animationTrack)
                if not _G.isScriptEnabled then return end
                if animationTrack.Animation.AnimationId == OLD_ANIMATION_ID then
                    animationTrack:Stop()
                    local newAnimation = Instance.new("Animation")
                    newAnimation.AnimationId = NEW_ANIMATION_ID
                    local newTrack = animator:LoadAnimation(newAnimation)
                    newTrack:Play(0, 1, 4)
                end
            end)
            table.insert(connections, animationConnection)
        end

        if player.Character then
            handleAnimations(player.Character)
        end
        local characterConnection = player.CharacterAdded:Connect(function(character)
            if not _G.isScriptEnabled then return end
            handleAnimations(character)
        end)
        table.insert(connections, characterConnection)
    ]]
}

-- Функция для очистки индикаторов
local function clearIndicators()
    local liveFolder = workspace:FindFirstChild("Live")
    if liveFolder then
        for _, model in pairs(liveFolder:GetChildren()) do
            if model:FindFirstChild("TargetGui") then
                model.TargetGui:Destroy()
            end
        end
    end
end

-- Функция для остановки всех анимаций
local function stopAllAnimations()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                if track.IsPlaying then
                    track:Stop()
                end
            end
        end
    end
end

-- Функция для остановки движения
local function stopMovement()
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.Anchored = false
        end
    end
end

-- Загрузка и выполнение скриптов
local function loadScripts()
    for i, scriptCode in ipairs(scripts) do
        if not _G.isScriptEnabled then
            warn("Загрузка скриптов прервана: isScriptEnabled = false")
            break
        end

        local success, result = pcall(function()
            local func = loadstring(scriptCode)
            if func then
                func()
                print("Успешно выполнен скрипт #" .. i)
            else
                warn("Не удалось создать функцию для скрипта #" .. i)
            end
        end)

        if not success then
            warn("Ошибка выполнения скрипта #" .. i .. ": " .. tostring(result))
        end
        task.wait(0.2)
    end
end

-- Отслеживание новых персонажей для очистки при возрождении
local characterConnection = player.CharacterAdded:Connect(function(character)
    if not _G.isScriptEnabled then return end
    clearIndicators()
    stopAllAnimations()
    stopMovement()
end)
table.insert(connections, characterConnection)

-- Запуск скриптов
task.spawn(function()
    local success, err = pcall(loadScripts)
    if not success then
        warn("Ошибка при запуске loadScripts: " .. tostring(err))
    end
end)

-- Обработка кнопки "Kill Script"
button.MouseButton1Click:Connect(function()
    _G.isScriptEnabled = false
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    clearIndicators()
    stopAllAnimations()
    stopMovement()
    if screenGui then
        screenGui:Destroy()
    end
    print("Все скрипты остановлены")
end)

-- Очистка при выходе игрока
game:BindToClose(function()
    _G.isScriptEnabled = false
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    clearIndicators()
    stopAllAnimations()
    stopMovement()
    if screenGui then
        screenGui:Destroy()
    end
end)
