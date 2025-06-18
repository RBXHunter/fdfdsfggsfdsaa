local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterLoaderGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 120, 0, 40)
button.Position = UDim2.new(0, 10, 0, 10)
button.Text = "Kill Script"
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 16
button.Parent = screenGui

-- Глобальный флаг для отключения
_G.isScriptEnabled = true

-- Список скриптов (замени ссылки на реальные)
local scripts = {
    "https://raw.githubusercontent.com/yourUser/yourRepo/main/script1.lua",
    "https://raw.githubusercontent.com/yourUser/yourRepo/main/script2.lua",
    "https://raw.githubusercontent.com/yourUser/yourRepo/main/script3.lua",
    "https://raw.githubusercontent.com/yourUser/yourRepo/main/script4.lua",
}

-- Загрузка скриптов
local function loadScripts()
    for i, url in ipairs(scripts) do
        if not _G.isScriptEnabled then break end

        local success, result = pcall(function()
            local code = game:HttpGet(url)
            local func = loadstring(code)
            return func()
        end)

        if success then
            print("✅ Loaded scripts")
        else
            warn("⚠️ Failed to load scripts")
        end

        task.wait(0.2)
    end
end

-- Запуск скриптов
task.spawn(loadScripts)

-- Обработка кнопки "Kill Script"
button.MouseButton1Click:Connect(function()
    _G.isScriptEnabled = false
    if screenGui then screenGui:Destroy() end
    print("🛑 All scripts disabled and UI removed")
end)
