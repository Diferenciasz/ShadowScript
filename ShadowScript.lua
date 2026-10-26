--// =========================================================
--// ShadowScript v(PAID)
--// Custom Interface - 3 Separate Windows
--// =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// =========================================================
--// BYPASS ANTICHEAT (BLOCKSPIN / ROBLOX)
--// =========================================================

pcall(function()
    local oldIndex = getrawmetatable and getrawmetatable(game)
    if setreadonly and oldIndex then
        setreadonly(oldIndex, false)
        local oldNamecall = oldIndex.__namecall
        oldIndex.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then return end
            if method == "FireServer" and tostring(self) == "LocalPlayer" then return end
            return oldNamecall(self, ...)
        end)
        setreadonly(oldIndex, true)
    end
    
    task.spawn(function()
        while task.wait(60) do
            game:GetService("VirtualUser"):CaptureController()
            game:GetService("VirtualUser"):ClickButton2(Vector2.new())
        end
    end)
end)

--// CONFIG
local GUI_KEY = Enum.KeyCode.K
local AimbotEnabled = false
local AimbotSmoothness = 5
local AimbotFOV = 110
local Wallcheck = true
local AimPart = "Head"
local AimbotBind = Enum.KeyCode.LeftAlt
local WaitingForBind = false

local ESPEnabled = false
local ESPName = true
local ESPDistance = true
local ESPHealth = true
local ESPWeapon = true
local ESPTracer = true
local ESPHighlight = true
local HideNameEnabled = true

local CurrentTarget = nil
local ProtectedPlayers = {}
local ESPData = {}

local RarityColors = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(0, 255, 0),
	Rare = Color3.fromRGB(0, 170, 255),
	Epic = Color3.fromRGB(170, 0, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 0, 0)
}

local Items = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
local WeaponRegistry, WeaponNameIndex, WeaponItemIdIndex = {}, {}, {}

local function ReadDisplayName(tool)
	if not tool then return nil end
	local name = tool:GetAttribute("DisplayName") or tool:GetAttribute("ItemName") or tool:GetAttribute("WeaponName")
	if typeof(name) == "string" and name ~= "" then return name end
	return tool.Name
end

local function GetToolRarity(tool)
	return tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity") or "Common"
end

local function AddRegistryEntry(tool)
	if not tool or not tool:IsA("Tool") then return end
	local displayName = ReadDisplayName(tool)
	local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id") or tool.Name
	local rarity = GetToolRarity(tool)
	local key = "NAME_" .. displayName .. "_" .. tool.Name .. "_RARITY_" .. rarity
	WeaponRegistry[key] = { Name = displayName, Rarity = rarity }
	if tool.Name then WeaponNameIndex[tool.Name] = WeaponRegistry[key] end
	if itemId then WeaponItemIdIndex[tostring(itemId)] = WeaponRegistry[key] end
end

local function RegisterItems(folder)
	if not folder then return end
	for _, tool in ipairs(folder:GetChildren()) do
		if tool:IsA("Tool") then AddRegistryEntry(tool) end
	end
end

local function ScanFolders(folder)
	if not folder then return end
	RegisterItems(folder)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Folder") then ScanFolders(child) end
	end
	folder.ChildAdded:Connect(function(child)
		task.wait(0.1)
		if child:IsA("Folder") then ScanFolders(child) else RegisterItems(folder) end
	end)
end

ScanFolders(Items)

local function GetWeaponInfo(tool)
	if not tool then return nil end
	if WeaponNameIndex[tool.Name] then return WeaponNameIndex[tool.Name] end
	return { Name = ReadDisplayName(tool), Rarity = GetToolRarity(tool) }
end

local function GetWeapons(player)
	local items = {}
	local function scan(container)
		if not container then return end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and tool.Name ~= "Fists" then
				local info = GetWeaponInfo(tool)
				if info then table.insert(items, info) end
			end
		end
	end
	scan(player:FindFirstChild("Backpack"))
	scan(player.Character)
	return items
end

local function HideMyName()
    if not HideNameEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BillboardGui") then v.Enabled = false end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    HideMyName()
end)
if LocalPlayer.Character then task.wait(1) HideMyName() end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShadowScript"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local function CreateWindow(titleText, posX, width, height)
	local Main = Instance.new("Frame")
	Main.Size = UDim2.new(0, width, 0, height)
	Main.Position = UDim2.new(0.5, posX, 0.5, 0)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui
	
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", Main)
	stroke.Color = Color3.fromRGB(200, 200, 200)
	stroke.Thickness = 1
	
	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 40)
	Header.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	Header.BorderSizePixel = 0
	Header.Parent = Main
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
	
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -20, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = titleText
	Title.TextColor3 = Color3.fromRGB(0, 0, 0)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header
	
	local Content = Instance.new("ScrollingFrame")
	Content.Size = UDim2.new(1, -20, 1, -50)
	Content.Position = UDim2.new(0, 10, 0, 45)
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel = 0
	Content.ScrollBarThickness = 2
	Content.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	Content.CanvasSize = UDim2.new(0, 0, 0, 0)
	Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Content.Parent = Main
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = Content
	
	local dragging, dragStart, startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	return Content
end

-- Crear ventanas
local ESPPage = CreateWindow("VISUAL", -320, 280, 350)
local AimPage = CreateWindow("SOFTAIM", 0, 280, 350)
local ProtectPage = CreateWindow("FRIEND LIST", 320, 280, 350)

-- Helper UI
local function CreateToggle(parent, text, initial, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = initial and Color3.fromRGB(200, 240, 210) or Color3.fromRGB(240, 240, 240)
	btn.Text = text .. (initial and " [ON]" or " [OFF]")
	btn.TextColor3 = Color3.fromRGB(0, 0, 0)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(1, -16, 0.5, -4)
	dot.BackgroundColor3 = initial and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 150, 150)
	dot.Parent = btn
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	
	local state = initial
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = text .. (state and " [ON]" or " [OFF]")
		callback(state)
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = state and Color3.fromRGB(200, 240, 210) or Color3.fromRGB(240, 240, 240)
		}):Play()
		TweenService:Create(dot, TweenInfo.new(0.15), {
			BackgroundColor3 = state and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 150, 150)
		}):Play()
	end)
	return btn
end

local function CreateValueBox(parent, text, value, callback)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 38)
	holder.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	holder.Parent = parent
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 4)
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.55, 0, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.35, 0, 0, 24)
	box.Position = UDim2.new(0.62, 0, 0.5, -12)
	box.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	box.TextColor3 = Color3.fromRGB(0, 0, 0)
	box.Text = tostring(value)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.Parent = holder
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	
	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then callback(num) box.Text = tostring(num) else box.Text = tostring(value) end
	end)
	return holder
end

-- VISUAL
CreateToggle(ESPPage, "ESP", false, function(v) ESPEnabled = v if not v then for p in pairs(ESPData) do RemoveESP(p) end end end).LayoutOrder = 1
CreateToggle(ESPPage, "Name", true, function(v) ESPName = v end).LayoutOrder = 2
CreateToggle(ESPPage, "Distance", true, function(v) ESPDistance = v end).LayoutOrder = 3
CreateToggle(ESPPage, "Health", true, function(v) ESPHealth = v end).LayoutOrder = 4
CreateToggle(ESPPage, "Weapon", true, function(v) ESPWeapon = v end).LayoutOrder = 5
CreateToggle(ESPPage, "Tracer", true, function(v) ESPTracer = v end).LayoutOrder = 6
CreateToggle(ESPPage, "Highlight", true, function(v) ESPHighlight = v end).LayoutOrder = 7
CreateToggle(ESPPage, "Hide Name", true, function(v) 
    HideNameEnabled = v 
    if v then HideMyName() else
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BillboardGui") then obj.Enabled = true end
            end
        end
    end
end).LayoutOrder = 8

-- SOFTAIM
local AimToggle = CreateToggle(AimPage, "Enable Aimbot", false, function(v) AimbotEnabled = v end)
AimToggle.LayoutOrder = 1

CreateValueBox(AimPage, "Smoothness", AimbotSmoothness, function(v) AimbotSmoothness = v end).LayoutOrder = 2
CreateValueBox(AimPage, "FOV", AimbotFOV, function(v) AimbotFOV = v end).LayoutOrder = 3

local BindBtn = Instance.new("TextButton")
BindBtn.Size = UDim2.new(1, 0, 0, 32)
BindBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
BindBtn.Text = "Bind: " .. AimbotBind.Name
BindBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
BindBtn.Font = Enum.Font.GothamSemibold
BindBtn.TextSize = 11
BindBtn.TextXAlignment = Enum.TextXAlignment.Left
BindBtn.AutoButtonColor = false
BindBtn.Parent = AimPage
BindBtn.LayoutOrder = 4
Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
BindBtn.MouseButton1Click:Connect(function()
	WaitingForBind = true
	BindBtn.Text = "PRESS KEY..."
end)

CreateToggle(AimPage, "Wallcheck", true, function(v) Wallcheck = v end).LayoutOrder = 5

-- FRIEND LIST
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, 0, 1, 0)
PlayerList.BackgroundTransparency = 1
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 2
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 1000)
PlayerList.Parent = ProtectPage
Instance.new("UIListLayout", PlayerList).Padding = UDim.new(0, 4)

local function UpdateProtectedList()
	for _, child in ipairs(PlayerList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.Name:lower() < b.Name:lower() end)
	for _, player in ipairs(players) do
		if player ~= LocalPlayer then
			local isProt = ProtectedPlayers[player] == true
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 30)
			btn.BackgroundColor3 = isProt and Color3.fromRGB(200, 240, 210) or Color3.fromRGB(240, 240, 240)
			btn.Text = player.Name
			btn.TextColor3 = Color3.fromRGB(0, 0, 0)
			btn.Font = Enum.Font.GothamSemibold
			btn.TextSize = 11
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.AutoButtonColor = false
			btn.Parent = PlayerList
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 8, 0, 8)
			dot.Position = UDim2.new(1, -16, 0.5, -4)
			dot.BackgroundColor3 = isProt and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 150, 150)
			dot.Parent = btn
			Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
			
			btn.MouseButton1Click:Connect(function()
				ProtectedPlayers[player] = not isProt
				UpdateProtectedList()
			end)
		end
	end
end

local function CreateESP(player)
	if not player or player == LocalPlayer or ESPData[player] then return end
	local data = {
		Name = Drawing.new("Text"), Distance = Drawing.new("Text"), Health = Drawing.new("Text"),
		Tracer = Drawing.new("Line"), Weapons = {}, Highlight = Instance.new("Highlight")
	}
	for _, d in ipairs({data.Name, data.Distance, data.Health}) do d.Center = true d.Outline = true d.Font = 2 end
	data.Name.Size = 13 data.Distance.Size = 12 data.Health.Size = 12
	data.Tracer.Thickness = 1 data.Tracer.Transparency = 0.8
	data.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	data.Highlight.FillTransparency = 1 data.Highlight.OutlineTransparency = 0
	if player.Character then data.Highlight.Parent = player.Character data.Highlight.Adornee = player.Character end
	ESPData[player] = data
end

local function RemoveESP(player)
	local data = ESPData[player]
	if not data then return end
	for _, d in ipairs({data.Name, data.Distance, data.Health, data.Tracer}) do if d then d:Remove() end end
	for _, d in ipairs(data.Weapons) do if d then d:Remove() end end
	if data.Highlight then data.Highlight:Destroy() end
	ESPData[player] = nil
end

local function UpdateESP(player)
	local data = ESPData[player]
	if not data then CreateESP(player) data = ESPData[player] end
	if not data then return end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")

	local function hide2D()
		data.Name.Visible = false data.Distance.Visible = false data.Health.Visible = false data.Tracer.Visible = false
		for _, d in ipairs(data.Weapons) do d.Visible = false end
	end

	if not char or not head or not root or not humanoid or humanoid.Health <= 0 then
		hide2D()
		if data.Highlight then data.Highlight.Adornee = nil data.Highlight.Enabled = false end
		return
	end

	if data.Highlight then
		data.Highlight.Parent = char data.Highlight.Adornee = char data.Highlight.Enabled = ESPHighlight
	end

	if not ESPEnabled then
		hide2D()
		if data.Highlight then data.Highlight.Enabled = isTarget or ESPHighlight end
		return
	end

	local headPos, hVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
	local rootPos, rVis = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.3, 0))
	local isTarget = CurrentTarget == player
	local espColor = ProtectedPlayers[player] and Color3.fromRGB(0, 255, 100) or (isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(150, 50, 255))

	if data.Highlight then
		data.Highlight.OutlineColor = espColor
		data.Highlight.FillColor = espColor
	end

	if not hVis or not rVis or headPos.Z < 0 then hide2D() return end

	local height = math.abs(headPos.Y - rootPos.Y)
	local width = height / 2
	local x = rootPos.X - width / 2
	local y = headPos.Y
	local anchorX = x + width + 6
	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local dist = localRoot and (localRoot.Position - root.Position).Magnitude or 0
	local anchorY = dist > 25 and y - 24.5 or y - 12

	if ESPName then data.Name.Text = player.Name data.Name.Position = Vector2.new(anchorX, anchorY) data.Name.Color = espColor data.Name.Visible = true else data.Name.Visible = false end
	if ESPDistance and localRoot then data.Distance.Text = math.floor(dist) .. "m" data.Distance.Position = Vector2.new(anchorX, anchorY + 12) data.Distance.Color = Color3.fromRGB(180, 180, 180) data.Distance.Visible = true else data.Distance.Visible = false end
	if ESPHealth then
		local perc = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		data.Health.Text = math.floor(math.max(0, humanoid.Health)) .. "/" .. math.floor(humanoid.MaxHealth)
		data.Health.Position = Vector2.new(anchorX, anchorY + 24) data.Health.Color = Color3.fromRGB(255 * (1 - perc), 255 * perc, 0) data.Health.Visible = true
	else data.Health.Visible = false end

	for _, d in ipairs(data.Weapons) do d.Visible = false end
	if ESPWeapon then
		for i, w in ipairs(GetWeapons(player)) do
			if not data.Weapons[i] then local t = Drawing.new("Text") t.Size = 13.75 t.Center = true t.Outline = true t.Font = 2 data.Weapons[i] = t end
			local d = data.Weapons[i]
			d.Text = "[" .. tostring(w.Rarity) .. "] " .. tostring(w.Name) d.Color = RarityColors[w.Rarity] or Color3.new(1, 1, 1)
			d.Position = Vector2.new(x + width / 2, y + height + 6 + ((i - 1) * 12)) d.Visible = true
		end
	end

	if ESPTracer then
		data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
		data.Tracer.To = Vector2.new(headPos.X, headPos.Y) data.Tracer.Color = espColor data.Tracer.Visible = true
	else data.Tracer.Visible = false end
end

local function GetTargetPart(character)
	if not character then return nil end
	return character:FindFirstChild(AimPart) or character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso")
end

local function FindTarget()
	local closest, closestDist = nil, AimbotFOV
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not ProtectedPlayers[player] then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local part = GetTargetPart(char)
					if part then
						local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
						if onScreen then
							local dist = (Vector2.new(screen.X, screen.Y) - (Camera.ViewportSize / 2)).Magnitude
							if dist <= AimbotFOV and dist < closestDist then
								closest, closestDist = player, dist
							end
						end
					end
				end
			end
		end
	end
	return closest
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5 FOVCircle.Filled = false FOVCircle.Transparency = 0.5 FOVCircle.Color = Color3.fromRGB(150, 50, 255)

RunService.RenderStepped:Connect(function()
	FOVCircle.Position = Camera.ViewportSize / 2
	FOVCircle.Radius = AimbotFOV
	FOVCircle.Visible = AimbotEnabled
	CurrentTarget = nil
	if not AimbotEnabled then return end
	
	local target = FindTarget()
	CurrentTarget = target
	
	if not target or not target.Character then return end
	local part = GetTargetPart(target.Character)
	if not part then return end
	
	local aimPosition = part.Position
	
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.SeatPart then
		aimPosition = aimPosition - Vector3.new(-0.15, 0.05, 0)
	end
	
	local camPos = Camera.CFrame.Position
	local targetPos = aimPosition
	
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.SeatPart then
		local velocity = LocalPlayer.Character.HumanoidRootPart.Velocity / 12
		targetPos = targetPos + velocity
	end
	
	local current = Camera.CFrame
	local desired = CFrame.new(current.Position, targetPos)
	
	local dist = (current.Position - targetPos).Magnitude
	local alpha = dist < 15 and 1 or math.clamp(1 / math.max(AimbotSmoothness, 1), 0.1, 1)
	
	Camera.CFrame = current:Lerp(desired, alpha)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if WaitingForBind then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			AimbotBind = input.KeyCode
			WaitingForBind = false
			BindBtn.Text = "Bind: " .. AimbotBind.Name
			return
		end
	end
	if not processed and input.KeyCode == AimbotBind then
		AimbotEnabled = not AimbotEnabled
		if AimToggle then
			AimToggle.Text = "Enable Aimbot" .. (AimbotEnabled and " [ON]" or " [OFF]")
			TweenService:Create(AimToggle, TweenInfo.new(0.15), {
				BackgroundColor3 = AimbotEnabled and Color3.fromRGB(200, 240, 210) or Color3.fromRGB(240, 240, 240)
			}):Play()
		end
	end
	if not processed and input.KeyCode == GUI_KEY then
		for _, w in ipairs(ScreenGui:GetChildren()) do
			if w:IsA("Frame") then w.Visible = not w.Visible end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if ESPEnabled then
		for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then UpdateESP(p) end end
	else
		for p in pairs(ESPData) do RemoveESP(p) end
	end
end)

for _, p in ipairs(Players:GetPlayers()) do UpdateProtectedList() end
Players.PlayerAdded:Connect(UpdateProtectedList)
Players.PlayerRemoving:Connect(function(p) ProtectedPlayers[p] = nil UpdateProtectedList() RemoveESP(p) end)

print("ShadowScript Loaded")