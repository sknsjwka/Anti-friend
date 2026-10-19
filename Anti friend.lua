--[[ Anti Friend Join - LOOP + AUTO CLICK NO LOAD | Arceus X ]]

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local LocalPlayer     = Players.LocalPlayer

-- ESTADOS
local isAntiFriendActive = true
local isAutoClickActive  = true
local isRejoining        = false

local F_LASTJOB  = "afj_lastjob.txt"
local F_HOPPING  = "afj_hopping.txt"

local function fRead(n) if not readfile then return nil end local ok,v=pcall(readfile,n) return ok and v or nil end
local function fWrite(n,d) if not writefile then return false end return pcall(writefile,n,d) end
local function fDel(n) if not delfile then return end if isfile then local ok,e=pcall(isfile,n) if ok and e then pcall(delfile,n) end else pcall(delfile,n) end end
local function fExists(n) if not isfile then return false end local ok,v=pcall(isfile,n) return ok and v or false end

-- HTTP
local function httpGet(url)
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and result and result ~= "" then return result end
    local reqs = {}
    if type(request) == "function" then table.insert(reqs, request) end
    if syn and type(syn.request) == "function" then table.insert(reqs, syn.request) end
    if http and type(http.request) == "function" then table.insert(reqs, http.request) end
    for _, fn in ipairs(reqs) do
        ok, result = pcall(function() local r = fn({Url = url, Method = "GET"}) return (r and (r.Body or r.body or r)) or nil end)
        if ok and type(result) == "string" and result ~= "" then return result end
    end
    return nil
end

-- Busca servidor
local function findDifferentServer()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    local body = httpGet(url)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" or type(data.data) ~= "table" then return nil end
    
    local current = game.JobId or ""
    local candidates = {}
    for _, srv in ipairs(data.data) do
        if type(srv) == "table" and srv.id and srv.id ~= "" and srv.id ~= current then
            local playing = tonumber(srv.playing) or 0
            local maxp    = tonumber(srv.maxPlayers) or 999
            if playing < maxp then table.insert(candidates, srv.id) end
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local function getParent()
    if gethui then local ok,h=pcall(gethui) if ok and h then return h end end
    return CoreGui
end
local PARENT = getParent()

-- ==========================================
-- AUTO CLICK NO BOTÃO "LOAD" (Centro Inferior)
-- ==========================================
local function doTouch(x, y)
    -- 1. Tenta simular toque físico (ideal para mobile)
    if VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:SetTouchInput(x, y, Enum.UserInputState.Begin)
            task.wait(0.05)
            VirtualUser:SetTouchInput(x, y, Enum.UserInputState.End)
        end)
    end
    
    -- 2. Fallback: clique de mouse via VirtualInputManager
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function startAutoClick()
    task.spawn(function()
        while isAutoClickActive do
            local vp = workspace.CurrentCamera.ViewportSize
            
            -- Posições ajustadas com base nas suas imagens
            local points = {
                Vector2.new(vp.X * 0.50, vp.Y * 0.85), -- Botão "Load" (O principal que você pediu)
                Vector2.new(vp.X * 0.60, vp.Y * 0.45), -- Botão 1
                Vector2.new(vp.X * 0.48, vp.Y * 0.45)  -- Botão 2
            }

            for _, pt in ipairs(points) do
                if not isAutoClickActive then break end
                doTouch(pt.X, pt.Y)
                task.wait(0.1) -- Pequeno delay entre os cliques
            end
            task.wait(0.3) -- Delay para o jogo processar (evita crash)
        end
    end)
end

-- ==========================================
-- REJOIN EM LOOP
-- ==========================================
local function doRejoin(reason)
    if isRejoining then return end
    isRejoining = true
    fWrite(F_LASTJOB, game.JobId or "")
    fWrite(F_HOPPING, "1")
    
    task.spawn(function()
        while isRejoining do
            local newJobId = findDifferentServer()
            if newJobId then
                local success = pcall(function() 
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, newJobId, LocalPlayer) 
                end)
                if not success then
                    task.wait(2)
                else
                    break -- O jogo vai reiniciar
                end
            else
                task.wait(2)
            end
        end
    end)
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer and isRejoining then
        task.wait(2)
        isRejoining = false
        doRejoin("Servidor cheio. Tentando outro...")
    end
end)

local function checkPlayer(p)
    if not isAntiFriendActive or p == LocalPlayer then return end
    task.spawn(function()
        local ok, isF = pcall(function() return LocalPlayer:IsFriendsWith(p.UserId) end)
        if ok and isF then doRejoin(p.Name) end
    end)
end

-- ==========================================
-- UI MINIMALISTA
-- ==========================================
local function buildUI()
    local old = PARENT:FindFirstChild("AntiFriendUI")
    if old then old:Destroy() end
    
    local g = Instance.new("ScreenGui")
    g.Name="AntiFriendUI" g.ResetOnSpawn=false g.Parent=PARENT
    
    local m = Instance.new("Frame")
    m.Size=UDim2.new(0,200,0,130) m.Position=UDim2.new(0,20,0,20)
    m.BackgroundColor3=Color3.fromRGB(25,25,30) m.BorderSizePixel=0
    m.Active=true m.Draggable=true m.Parent=g
    Instance.new("UICorner",m).CornerRadius=UDim.new(0,10)
    local ms=Instance.new("UIStroke",m) ms.Color=Color3.fromRGB(80,80,130)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X" closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold closeBtn.TextSize = 12 closeBtn.Parent = m
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

    local b1 = Instance.new("TextButton")
    b1.Size=UDim2.new(1,-20,0,35) b1.Position=UDim2.new(0,10,0,25)
    b1.BackgroundColor3=Color3.fromRGB(60,160,90) b1.BorderSizePixel=0
    b1.Text="Anti-Friend: ON" b1.TextColor3=Color3.new(1,1,1)
    b1.Font=Enum.Font.GothamBold b1.TextSize=14 b1.AutoButtonColor=false b1.Parent=m
    Instance.new("UICorner",b1).CornerRadius=UDim.new(0,8)

    b1.MouseButton1Click:Connect(function()
        isAntiFriendActive = not isAntiFriendActive
        if isAntiFriendActive then
            b1.Text="Anti-Friend: ON" b1.BackgroundColor3=Color3.fromRGB(60,160,90)
            for _,p in ipairs(Players:GetPlayers()) do checkPlayer(p) end
        else
            b1.Text="Anti-Friend: OFF" b1.BackgroundColor3=Color3.fromRGB(60,60,80)
        end
    end)

    local b2 = Instance.new("TextButton")
    b2.Size=UDim2.new(1,-20,0,35) b2.Position=UDim2.new(0,10,0,70)
    b2.BackgroundColor3=Color3.fromRGB(60,160,90) b2.BorderSizePixel=0
    b2.Text="Auto Click: ON" b2.TextColor3=Color3.new(1,1,1)
    b2.Font=Enum.Font.GothamBold b2.TextSize=14 b2.AutoButtonColor=false b2.Parent=m
    Instance.new("UICorner",b2).CornerRadius=UDim.new(0,8)

    b2.MouseButton1Click:Connect(function()
        isAutoClickActive = not isAutoClickActive
        if isAutoClickActive then
            b2.Text="Auto Click: ON" b2.BackgroundColor3=Color3.fromRGB(60,160,90)
            startAutoClick()
        else
            b2.Text="Auto Click: OFF" b2.BackgroundColor3=Color3.fromRGB(60,60,80)
        end
    end)

    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 40, 0, 40) openBtn.Position = UDim2.new(0, 20, 0, 20)
    openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    openBtn.Text = "≡" openBtn.TextColor3 = Color3.new(1,1,1)
    openBtn.Font = Enum.Font.GothamBold openBtn.TextSize = 20
    openBtn.Visible = false openBtn.Active = true openBtn.Draggable = true openBtn.Parent = g
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
    local obs = Instance.new("UIStroke", openBtn) obs.Color = Color3.fromRGB(80,80,130)

    closeBtn.MouseButton1Click:Connect(function() m.Visible = false openBtn.Visible = true end)
    openBtn.MouseButton1Click:Connect(function() m.Visible = true openBtn.Visible = false end)
end

-- INICIALIZAÇÃO
buildUI()
startAutoClick()

task.spawn(function()
    task.wait(2)
    if fExists(F_HOPPING) then
        local lastJob = fRead(F_LASTJOB)
        if lastJob and lastJob ~= "" and lastJob == (game.JobId or "") then
            fDel(F_HOPPING)
            task.wait(1)
            doRejoin("Caiu no mesmo")
            return
        else
            fDel(F_HOPPING) fDel(F_LASTJOB)
            isRejoining = false
        end
    end

    Players.PlayerAdded:Connect(checkPlayer)
    for _,p in ipairs(Players:GetPlayers()) do checkPlayer(p) end
end)
