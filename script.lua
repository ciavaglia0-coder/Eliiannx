-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ⚙️ CONFIGURACIÓN DE COLORES Y TAMAÑOS
local PLAYER_COLOR = Color3.fromRGB(0, 255, 255) -- Azul (Jugadores)
local BOT_COLOR = Color3.fromRGB(255, 0, 0)      -- Rojo (Bots)
local HEAD_SIZE = Vector3.new(6, 6, 6)           -- Tamaño de la cabeza gigante

local espEnabled = false -- Empieza apagado

-- ==========================================
-- FUNCIONES DEL ESP (COLORES)
-- ==========================================
local function clearAllESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Highlight") and obj.Name == "ColorESP_Highlight" then
            obj:Destroy()
        end
    end
end

local function applyHighlight(char, color)
    local highlight = char:FindFirstChild("ColorESP_Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ColorESP_Highlight"
        highlight.Adornee = char
        highlight.Parent = char
    end
    
    highlight.FillColor = color
    highlight.FillTransparency = 0.1      
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) 
    highlight.OutlineTransparency = 0     
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- ==========================================
-- FUNCIONES DEL BIG HEAD
-- ==========================================
local function resetHead(char)
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local originalSize = head:GetAttribute("OriginalSize")
        local originalTransparency = head:GetAttribute("OriginalTransparency")
        local originalMassless = head:GetAttribute("OriginalMassless")
        
        if originalSize then head.Size = originalSize end
        if originalTransparency then head.Transparency = originalTransparency else head.Transparency = 0 end
        if originalMassless then head.Massless = originalMassless end
    end
end

local function expandHead(char)
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        if not head:GetAttribute("OriginalSize") then
            head:SetAttribute("OriginalSize", head.Size)
            head:SetAttribute("OriginalTransparency", head.Transparency)
            head:SetAttribute("OriginalMassless", head.Massless)
        end
        
        head.Size = HEAD_SIZE
        head.Transparency = 0 
        head.Massless = true 
    end
end

-- ==========================================
-- BUCLE PRINCIPAL (Aplica ESP y Big Head)
-- ==========================================
local function isEnemy(p)
    if p == player then return false end
    if player.Team and p.Team then
        return player.Team ~= p.Team
    end
    return true
end

task.spawn(function()
    while task.wait(0.5) do -- Se actualiza cada medio segundo para no bajar los FPS
        
        -- Si está apagado, nos aseguramos de que todo esté limpio
        if not espEnabled then
            clearAllESP()
            continue
        end

        -- 1. APLICAR A JUGADORES REALES
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local humanoid = p.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    applyHighlight(p.Character, PLAYER_COLOR)
                    expandHead(p.Character)
                else
                    resetHead(p.Character)
                end
            end
        end

        -- 2. APLICAR A BOTS (Modelos)
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= player.Character then
                local isPlayerChar = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then isPlayerChar = true; break end
                end
                
                if not isPlayerChar then
                    local humanoid = obj:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        applyHighlight(obj, BOT_COLOR)
                        expandHead(obj)
                    else
                        resetHead(obj)
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- NOTIFICACIÓN Y CONTROL (Ctrl Derecho)
-- ==========================================
local function showNotification(text, color)
    if playerGui:FindFirstChild("ESP_Notify") then playerGui.ESP_Notify:Destroy() end
    local notify = Instance.new("TextLabel")
    notify.Name = "ESP_Notify"
    notify.Size = UDim2.new(0, 250, 0, 40)
    notify.Position = UDim2.new(0.5, -125, 0, 50)
    notify.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    notify.TextColor3 = color
    notify.Text = text
    notify.Font = Enum.Font.GothamBold
    notify.TextSize = 14
    notify.Parent = playerGui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = notify
    local stroke = Instance.new("UIStroke"); stroke.Color = color; stroke.Thickness = 2; stroke.Parent = notify
    task.delay(1.5, function() if notify then notify:Destroy() end end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        espEnabled = not espEnabled 
        
        if espEnabled then
            showNotification("ESP + BIG HEAD: ON", PLAYER_COLOR)
        else
            showNotification("ESP + BIG HEAD: OFF", Color3.fromRGB(150, 150, 150))
            clearAllESP()
            
            -- Limpiar todas las cabezas gigantes al apagar
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then resetHead(p.Character) end
            end
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    resetHead(obj)
                end
            end
        end
    end
end)
