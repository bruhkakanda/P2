local lib = {} -- test duo

local RunService = game:GetService("RunService")   
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")

local GUI_INSET = GuiService:GetGuiInset()

local function isAlreadyActive()
	local taggedElements = CollectionService:GetTagged("pk-ui")

	if #taggedElements > 0 then
		return true
	else
		return false
	end
end

if getgenv().LOADED_PK_UI then return end
if isAlreadyActive() then return end

getgenv().LOADED_PK_UI = true

local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenInfoInBack = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local tweenInfoOutBack = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoOutSlow = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfoInSlow = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

lib.isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
lib.DraggingEnabled = true
lib.CreatedUI = nil
lib.Templates = nil
lib.LibGUID = HttpService:GenerateGUID(false)

lib.DragList = {}
lib.Pages = {}
lib.Tabs = {}
lib.Blocks = {}
lib.Buttons = {}
lib.SideButtons = {}
lib.SelectedTab = ""
lib.Minimalized = false

lib.Themes = {
	"default",
	"ocean",
	"spooky",
	"halloween"
}

local theme = getgenv().THEME

if theme then
	if not table.find(lib.Themes, (theme):lower()) then
		theme = "Default"
	end
end

if not theme then theme = "Default" end

theme = theme:lower()

local ThemedHUD, ThemedTemplates = loadstring(game:HttpGet("https://patchkids.xyz/themes_coded/".. theme..".txt"))()

function lib.newDrag(frame, storeTo, id)
	assert(typeof(storeTo) == "table", "storeTo must be a table")
	assert(id ~= nil, "Drag ID is required")

	if storeTo[id] then
		lib.RemoveDrag(storeTo, id)
	end

	local dragData = {
		dragging = false,
		dragInput = nil,
		dragStart = nil,
		startPos = nil,
		connections = {}
	}

	local function update(position)
		if not lib.DraggingEnabled then return end
		if not dragData.dragging then return end

		local delta = position - dragData.dragStart
		frame.Position = UDim2.new(
			dragData.startPos.X.Scale,
			dragData.startPos.X.Offset + delta.X,
			dragData.startPos.Y.Scale,
			dragData.startPos.Y.Offset + delta.Y
		)
	end

	dragData.connections.began = frame.InputBegan:Connect(function(input)
		if not lib.DraggingEnabled then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragData.dragging = true
			dragData.dragInput = input
			dragData.dragStart = input.Position
			dragData.startPos = frame.Position

			dragData.connections.touchMove = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.Change then
					update(input.Position)
				end
			end)
		end
	end)

	dragData.connections.mouseMove = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input.Position)
		end
	end)

	dragData.connections.ended = frame.InputEnded:Connect(function(input)
		if input == dragData.dragInput then
			dragData.dragging = false
			dragData.dragInput = nil

			if dragData.connections.touchMove then
				dragData.connections.touchMove:Disconnect()
				dragData.connections.touchMove = nil
			end
		end
	end)

	storeTo[id] = dragData
end

function lib.delDrag(storeTo, id)
	local dragData = storeTo[id]
	if not dragData then return end

	for _, connection in pairs(dragData.connections) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end

	storeTo[id] = nil
end

function lib.toggleDrag()
	lib.DraggingEnabled = not lib.DraggingEnabled
end

function lib.createHUD()
	local Main = ThemedHUD.Main
	local UIScale = ThemedHUD.Main.UIScale
	local Glow = ThemedHUD.Main.Glow
	local BG = ThemedHUD.Main.BG
	local UICorner_4 = BG.UICorner
	local Topbar = ThemedHUD.Main.Topbar
	local Close = Topbar.Container.Close
	local Min = Topbar.Container.Min
	local Toggle = ThemedHUD.Toggle
	local Search_2 = Main.Container.Search.Search.Search
	local Container_1 = Main.Container
	
	lib.newDrag(Main, lib.DragList, "Main")

	local function toggleMain()
		if UIScale.Scale == 0.5 then
			Main.Visible = true
			TweenService:Create(UIScale, tweenInfoOutBack, {Scale = 1}):Play()
			TweenService:Create(Main, tweenInfo, {GroupTransparency = 0}):Play()
			if not lib.Minimalized then
				TweenService:Create(Glow, tweenInfoOutSlow, {Transparency = 0.5}):Play()
			end
		elseif UIScale.Scale == 1 then
			TweenService:Create(UIScale, tweenInfoInSlow, {Scale = 0.5}):Play()
			TweenService:Create(Main, tweenInfo, {GroupTransparency = 1}):Play()
			TweenService:Create(Glow, tweenInfoOutSlow, {Transparency = 1}):Play()

			task.delay(0.3, function()
				if UIScale.Scale == 0.5 then
					Main.Visible = false
				end
			end)
		end
	end

	local function findPage(pageName)
		for _, pg in lib.Pages do
			if pg.Name == pageName then
				return pg
			end
		end

		return
	end

	Close.Activated:Connect(function()
		TweenService:Create(UIScale, tweenInfoInSlow, {Scale = 0.5}):Play()
		TweenService:Create(Main, tweenInfo, {GroupTransparency = 1}):Play()
		TweenService:Create(Glow, tweenInfoOutSlow, {Transparency = 1}):Play()

		task.delay(0.3, function()
			if UIScale.Scale == 0.5 then
				Main.Visible = false
			end
		end)
	end)

	Min.Activated:Connect(function()
		if not lib.Minimalized then
			lib.Minimalized = true
			TweenService:Create(BG, tweenInfoOutSlow, {Size = UDim2.fromScale(1,0.1)}):Play()
			TweenService:Create(UICorner_4, tweenInfoOutSlow, {CornerRadius = UDim.new(0,0)}):Play()
			TweenService:Create(Glow, tweenInfoOutSlow, {Transparency = 1}):Play()
			Container_1.Visible = false
			
			Min.Small.Visible = false
			Min.Big.Visible = true
		else
			lib.Minimalized = false
			TweenService:Create(BG, tweenInfoOutSlow, {Size = UDim2.fromScale(1,1)}):Play()
			TweenService:Create(UICorner_4, tweenInfoOutSlow, {CornerRadius = UDim.new(0.05,0)}):Play()
			TweenService:Create(Glow, tweenInfoOutSlow, {Transparency = 0.5}):Play()
			
			Min.Small.Visible = true
			Min.Big.Visible = false

			task.delay(0.125, function()
				if not lib.Minimalized then
					Container_1.Visible = true
				end
			end)
		end
	end)

	if lib.isMobile then
		lib.newDrag(Toggle, lib.DragList, "Toggle")

		Toggle.Activated:Connect(function()
			toggleMain()
		end)
	else
		Toggle.Visible = false
	end

	UserInputService.InputBegan:Connect(function(input, p)
		if not p and input.KeyCode == Enum.KeyCode.Q then
			toggleMain()
		end
	end)

	Search_2.Changed:Connect(function()
		local SearchingContent = string.lower(Search_2.Text)
		local activePage = findPage(lib.SelectedTab)
		if not activePage then return end

		if SearchingContent == "" then
			for _, buttonData in lib.Buttons do
				if buttonData.Element then
					buttonData.Element.Visible = true
				end
			end

			for _, blockData in lib.Blocks do
				if blockData.Element then
					blockData.Element.Visible = true
				end
			end

			return
		end

		local matchingItems = {}
		local blocksVisible = {}

		for buttonName, buttonData in lib.Buttons do
			if string.find(string.lower(buttonName), SearchingContent, 1, true) then
				table.insert(matchingItems, buttonName)

				if buttonData.Block then
					table.insert(blocksVisible, buttonData.Block)
				end
			end
		end

		for buttonName, buttonData in lib.Buttons do
			if buttonData.Element then
				buttonData.Element.Visible = table.find(matchingItems, buttonName) ~= nil
			end
		end

		for blockName, blockData in lib.Blocks do
			if blockData.Element then
				blockData.Element.Visible = table.find(blocksVisible, blockName) ~= nil or table.find(blocksVisible, blockData) ~= nil
			end
		end
	end)

	ThemedHUD.Name = lib.LibGUID
	ThemedHUD:AddTag("pk-ui")
	ThemedHUD.Parent = CoreGui
	ThemedHUD.Enabled = true
	lib.CreatedUI = ThemedHUD
end

function lib.createTemplates()
	lib.Templates = ThemedTemplates
end

function lib.notify(msg, ch)
	print(msg,ch)
end

function lib.load()
	if not lib.CreatedUI and not lib.Templates then return end
	local loadCounter = 0

	lib.CreatedUI.Main.Container.Loading.Visible = true

	local function setTitle(title, textColor)
		local main = lib.CreatedUI.Main.Container.Loading
		local taskBar = main.TaskList
		local template = taskBar.Template:Clone()
		template.Parent = taskBar
		template.Visible = true
		template.LayoutOrder = 0 - #taskBar:GetChildren()

		taskBar.Template.Visible = false

		template.Text = title
		template.TextColor3 = textColor
	end

	local function tweenAway()
		local main = lib.CreatedUI.Main.Container.Loading
		TweenService:Create(main.Loading, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
		TweenService:Create(main.Logo, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
	end

	local function forceFreeze(seconds)
		local endTime = os.clock() + seconds
		while os.clock() < endTime do
			for i = 1, 100000 do
				local _ = math.sin(i) * math.cos(i)
			end
		end
	end

	local isCurrentlyLoading = true 
	TweenService:Create(
		lib.CreatedUI.Main.Container.Loading.Loading,
		TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = 359}
	):Play()

	local spinCon
	spinCon = RunService.RenderStepped:Connect(function(deltaTime)
		lib.CreatedUI.Main.Container.Loading.Loading.Rotation += 90 * deltaTime
	end)

	setTitle("[GET] Check %PatchKids% Folder...", Color3.fromRGB(255,255,255))
	task.wait(1)

	forceFreeze(0.5)

	if not isfolder("PatchKids") then
		setTitle("[WARN] Failed to GET %PatchKids% Folder", Color3.fromRGB(255,0,0))
		setTitle("[NEW] Create %PatchKids% Folder...", Color3.fromRGB(255,255,255))
		makefolder("PatchKids")

		setTitle("[OK]", Color3.fromRGB(0,255,0))
	else
		setTitle("[OK]", Color3.fromRGB(0,255,0))
	end

	setTitle("[GET] Fetching Game, Hud, Features...", Color3.fromRGB(255,255,255))

	for i=1,900 do
		if i == 501 then
			task.wait(0.1)
		elseif i > 501 and i < 700 then
			task.wait(0.01)
		elseif i == 701 then
			task.wait(0.1)
		elseif i > 701 and i < 705 then
			task.wait(0.01)
		end
	end

	forceFreeze(0.1)

	setTitle("[OK]", Color3.fromRGB(0,255,0))
	tweenAway()
	spinCon:Disconnect()

	task.wait(1)

	isCurrentlyLoading = false 

	lib.CreatedUI.Main.Container.Loading.Visible = false
	lib.CreatedUI.Main.Container.NoTab.Visible = true

	lib.playSound(128629124431651)
end

function lib.TabTween(tab)
	tab.Button.MouseEnter:Connect(function()
		TweenService:Create(tab, tweenInfo, {BackgroundTransparency = 0}):Play()
		TweenService:Create(tab.List.Title, tweenInfo, {TextColor3 = Color3.new(0,0,0)}):Play()
		TweenService:Create(tab.List.Icon, tweenInfo, {ImageColor3 = Color3.new(0,0,0)}):Play()
	end)
	tab.Button.MouseLeave:Connect(function()
		if lib.SelectedTab ~= tab.Name then
			TweenService:Create(tab, tweenInfo, {BackgroundTransparency = 1}):Play()
			TweenService:Create(tab.List.Title, tweenInfo, {TextColor3 = Color3.new(1,1,1)}):Play()
			TweenService:Create(tab.List.Icon, tweenInfo, {ImageColor3 = Color3.new(1,1,1)}):Play()
		end
	end)
end

function lib.UpdateTab(name)
	local tab = nil

	for _, v in lib.Tabs do
		if v.Name and v.Name == name then
			tab = v
			break
		end
	end

	if tab and lib.SelectedTab == name then
		TweenService:Create(tab, tweenInfo, {BackgroundTransparency = 0}):Play()
		TweenService:Create(tab.List.Title, tweenInfo, {TextColor3 = Color3.new(0,0,0)}):Play()
		TweenService:Create(tab.List.Icon, tweenInfo, {ImageColor3 = Color3.new(0,0,0)}):Play()
	else
		TweenService:Create(tab, tweenInfo, {BackgroundTransparency = 1}):Play()
		TweenService:Create(tab.List.Title, tweenInfo, {TextColor3 = Color3.new(1,1,1)}):Play()
		TweenService:Create(tab.List.Icon, tweenInfo, {ImageColor3 = Color3.new(1,1,1)}):Play()
	end
end

function lib.alphaFeature(button, name)
	if not string.find(name, "ALPHA_") then return end

	button.Title.Text = string.gsub(name, "ALPHA_", "")

	local alpha = lib.Templates.Alpha:Clone()
	alpha.Parent = button

	local newContainer = Instance.new("Frame")
	newContainer.Name = "Container"
	newContainer.Parent = button
	newContainer.BackgroundTransparency = 1
	newContainer.Size = UDim2.fromScale(1, 0.65)
	button.Keybind.ZIndex = 5

	button.Slider.Parent = newContainer; button.Keybind.Parent = newContainer; button.TextBox.Parent = newContainer; button.Button.Parent = newContainer; button.Toggle.Parent = newContainer; button.Title.Parent = newContainer
	button.Size = UDim2.new(0.95, 0, 0, 60)
	button.UICorner.CornerRadius = UDim.new(0, 10)
end

function lib.newTab(name, image)
	if not lib.CreatedUI and not lib.Templates then return end

	local tab = lib.Templates.Tab:Clone()
	tab.Name = name
	tab.LayoutOrder = #lib.CreatedUI.Main.Container.Tabs:GetChildren() + 1
	tab.List.Title.Text = name
	tab.List.Icon.Image = "rbxassetid://"..image
	tab.List.Icon.Visible = true
	tab.Parent = lib.CreatedUI.Main.Container.Tabs
	tab.Visible = true

	table.insert(lib.Tabs, tab)

	tab.Button.Activated:Connect(function()
		lib.switchPage(name)
	end)

	lib.TabTween(tab)
	lib.newPage(name)
end

function lib.newPage(name)
	if not lib.CreatedUI and not lib.Templates then return end

	local page = lib.Templates.Page:Clone()
	page.Name = name
	page.Parent = lib.CreatedUI.Main.Container.Pages
	page.Visible = false

	table.insert(lib.Pages, page)
end

function lib.switchPage(name)
	if not lib.CreatedUI and not lib.Templates then return end

	lib.SelectedTab = name
	lib.UpdateTab(name)

	lib.CreatedUI.Main.Container.NoTab.Visible = false
	lib.CreatedUI.Main.Container.Search.Visible = true

	for _, page in lib.Pages do
		if page.Name ~= name then
			page.Visible = false
			lib.UpdateTab(page.Name)
		else
			page.Visible = true
		end
	end
end

function lib.newBlock(name, pageName)
	if not lib.CreatedUI and not lib.Templates then return end

	local block = lib.Templates.Block:Clone()
	block.Name = name
	block.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[pageName]:GetChildren() + 1
	block.ZIndex = 1000 - block.LayoutOrder
	block.Top.Text = name
	block.Parent = lib.CreatedUI.Main.Container.Pages[pageName]
	block.Visible = true
	lib.Blocks[name] = {
		Size = 1,
		Element = block,
		Page = pageName
	}

	block.Top.Min.Small.Visible = true
	block.Top.Min.Big.Visible = false

	block.Top.Min.Activated:Connect(function()
		local blockData = lib.Blocks[name]
		if blockData then
			if blockData.Size == 1 then
				block.Top.Min.Small.Visible = false
				block.Top.Min.Big.Visible = true
				blockData.Size = 0

				for _, btn in lib.Buttons do
					if btn.Block == name then
						btn.Element.Visible = false
					end
				end
			else
				block.Top.Min.Small.Visible = true
				block.Top.Min.Big.Visible = false
				blockData.Size = 1

				for _, btn in lib.Buttons do
					if btn.Block == name then
						btn.Element.Visible = true
					end
				end
			end
		end
	end)
end

function lib.newButton(name, block, keybind, callback)
	if not lib.CreatedUI and not lib.Templates then return end

	local blockData = lib.Blocks[block]
	if not blockData then return end

	-- t

	local button = lib.Templates.Button:Clone()
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[blockData.Page][block]:GetChildren() + 1
	button.ZIndex = 1000 - button.LayoutOrder
	button.Name = name
	button.Title.Text = name
	button.Button.Visible = true
	button.Keybind.Visible = keybind
	button.Parent = lib.CreatedUI.Main.Container.Pages[blockData.Page][block]

	lib.alphaFeature(button, name)
	local container = button:FindFirstChild("Container") or button

	lib.Buttons[name] = {
		Block = block,
		Keybind = nil,
		Type = "Button",
		Element = button
	}

	container.Button.Activated:Connect(function()
		callback()
	end)

	if keybind then
		if lib.isMobile then
			local hasSideButton = false

			local function setBindText(active)
				container.Keybind.Text = active and "On Screen" or "None"
			end

			setBindText(false)

			container.Keybind.Activated:Connect(function()
				if hasSideButton then
					lib.removeSideButton(name)
					hasSideButton = false
					setBindText(false)
				else
					lib.newSideButton(name, callback)
					hasSideButton = true
					setBindText(true)
				end
			end)

			-- Keep the label in sync if the side button is removed another way (e.g. its own 'x')
			local original = lib.removeSideButton
			lib.removeSideButton = function(removedName, ...)
				original(removedName, ...)
				if removedName == name and hasSideButton then
					hasSideButton = false
					setBindText(false)
				end
			end
		else
			local listening = false
			local currentKey = nil

			local function setKey(key)
				currentKey = key
				lib.Buttons[name].Keybind = key
				container.Keybind.Text = key and key.Name or "None"
			end

			setKey(nil)

			container.Keybind.Activated:Connect(function()
				if listening then return end
				listening = true
				container.Keybind.Text = "..."

				local con
				con = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

					if input.KeyCode == Enum.KeyCode.Escape then
						setKey(nil)
					else
						setKey(input.KeyCode)
					end

					listening = false
					con:Disconnect()
				end)
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe or listening or not currentKey then return end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				if input.KeyCode == currentKey then
					callback()
				end
			end)
		end
	end
end

function lib.newToggle(name, block, callback)
	if not lib.CreatedUI and not lib.Templates then return end

	local blockData = lib.Blocks[block]
	if not blockData then return end

	local button = lib.Templates.Button:Clone()
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[blockData.Page][block]:GetChildren() + 1
	button.ZIndex = 1000 - button.LayoutOrder
	button.Name = name
	button.Title.Text = name
	button.Toggle.Visible = true
	button.Parent = lib.CreatedUI.Main.Container.Pages[blockData.Page][block]

	lib.alphaFeature(button, name)
	local container = button:FindFirstChild("Container") or button

	lib.Buttons[name] = {
		Block = block,
		Toggle = false,
		Type = "Toggle",
		Element = button,
		ToggleFunction = function()
			local buttonData = lib.Buttons[name]
			if buttonData then
				if buttonData.Toggle then
					buttonData.Toggle = false

					TweenService:Create(container.Toggle.Frame, tweenInfo, {Position = container.Toggle.Off.Position, BackgroundColor3 = container.Toggle.Off.BackgroundColor3}):Play()

					callback(buttonData.Toggle)
				else
					buttonData.Toggle = true

					TweenService:Create(container.Toggle.Frame, tweenInfo, {Position = container.Toggle.On.Position, BackgroundColor3 = container.Toggle.On.BackgroundColor3}):Play()

					callback(buttonData.Toggle)
				end
			end
		end,
	}

	container.Toggle.Activated:Connect(function()
		lib.Buttons[name].ToggleFunction()
	end)
end

function lib.newSlider(name, block, max, min, def, callback)
	if not lib.CreatedUI and not lib.Templates then return end
	local blockData = lib.Blocks[block]
	if not blockData then return end

	local button = lib.Templates.Button:Clone()
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[blockData.Page][block]:GetChildren() + 1
	button.ZIndex = 1000 - button.LayoutOrder
	button.Name = name
	button.Title.Text = name
	button.Slider.Visible = true
	button.Parent = lib.CreatedUI.Main.Container.Pages[blockData.Page][block]

	lib.Buttons[name] = {
		Block = block,
		Value = def,
		Min = min,
		Max = max,
		Type = "Slider",
		Element = button
	}

	local isPlaying = false

	local antiDrag = button.Button
	antiDrag.Parent = button.Slider
	antiDrag.ZIndex = 0
	antiDrag.Visible = true

	button.Title.Size = UDim2.fromScale(0.4, 0.8)

	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local isDragging = false

	local tween = nil

	local function setValue(value)
		value = math.clamp(math.round(value), min, max)
		lib.Buttons[name].Value = value
		button.Slider.TextBox.Text = tostring(value)

		if tween then
			tween:Cancel()
			tween = nil
		end

		tween = TweenService:Create(button.Slider.Bar.Bar, tweenInfo, {Size = UDim2.fromScale((value - min) / (max - min), 1)})
		tween:Play()

		callback(value)
	end

	local function updateFromMouse()
		local absPos = button.Slider.Bar.AbsolutePosition.X
		local absSize = button.Slider.Bar.AbsoluteSize.X
		local mouseX = UIS:GetMouseLocation().X
		local alpha = math.clamp((mouseX - absPos) / absSize, 0, 1)
		setValue(min + alpha * (max - min))
	end

	setValue(def)

	button.Slider.Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateFromMouse()
		end
	end)

	local dragConn
	button.Slider.Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragConn = RunService.RenderStepped:Connect(function()
				if isDragging then updateFromMouse() end
			end)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
			if dragConn then dragConn:Disconnect(); dragConn = nil end
		end
	end)

	button.Slider.TextBox.FocusLost:Connect(function()
		local num = tonumber(button.Slider.TextBox.Text)
		if num then
			setValue(num)
		else
			button.Slider.TextBox.Text = tostring(lib.Buttons[name].Value)
		end
	end)
end

function lib.newTextBox(name, block, def, callback)
	if not lib.CreatedUI and not lib.Templates then return end

	local blockData = lib.Blocks[block]
	if not blockData then return end

	local button = lib.Templates.Button:Clone()
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[blockData.Page][block]:GetChildren() + 1
	button.ZIndex = 1000 - button.LayoutOrder
	button.Name = name
	button.Title.Text = name
	button.TextBox.Visible = true
	button.TextBox.PlaceholderText = def
	button.Parent = lib.CreatedUI.Main.Container.Pages[blockData.Page][block]

	lib.Buttons[name] = {
		Block = block,
		Type = "TextBox",
		Element = button
	}

	button.TextBox.FocusLost:Connect(function()
		callback(button.TextBox.Text)
	end)
end

function lib.newDropdown(name, block, list, callback)
	if not lib.CreatedUI and not lib.Templates then return end

	local blockData = lib.Blocks[block]
	if not blockData then return end

	local button = lib.Templates.Button:Clone()
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[blockData.Page][block]:GetChildren() + 1
	button.ZIndex = 1000 - button.LayoutOrder
	button.Name = name
	button.Title.Text = name
	button.Dropdown.Visible = true
	button.Parent = lib.CreatedUI.Main.Container.Pages[blockData.Page][block]
	button.Dropdown.BackgroundTransparency = 0
	button.Title.Size = UDim2.fromScale(0.6, 0.8)

	lib.Buttons[name] = {
		Block = block,
		Type = "Dropdown",
		Options = list,
		Option = "",
		Element = button
	}

	local isLoaded = false
	local loadedList = {}

	local function unLoadDropdown()
		TweenService:Create(button.Dropdown.Icon, tweenInfoOutSlow, {Rotation = 90}):Play()
		button.DropdownList.Visible = false

		for _, v in loadedList do
			v:Destroy()
		end
		loadedList = {}

		isLoaded = false
	end

	local function loadDropdown()
		TweenService:Create(button.Dropdown.Icon, tweenInfoOutSlow, {Rotation = 0}):Play()
		button.DropdownList.Visible = true

		for _, option in list do
			local optionButton = button.DropdownList.Block:Clone()
			optionButton.Name = option
			optionButton.Text = option

			local line = Instance.new("Frame", optionButton)
			line.Size = UDim2.new(1,0,0,1)
			line.BorderSizePixel = 0

			optionButton.Activated:Connect(function()
				lib.Buttons[name].Option = option
				button.Dropdown.Option.Text = option
				callback(option)
				unLoadDropdown()
			end)

			optionButton.Parent = button.DropdownList

			table.insert(loadedList, optionButton)

			task.wait(0.01)
		end

		isLoaded = true
	end

	button.Dropdown.Activated:Connect(function()
		if not isLoaded then
			loadDropdown()
		else
			unLoadDropdown()
		end
	end)
end

function lib.newSideButton(name, pressFunc)
	if not lib.CreatedUI then return end

	if lib.SideButtons[name] then
		lib.removeSideButton(name)
	end

	local sideButton = ThemedHUD.Toggle:Clone()
	sideButton.Name = "Side_" .. name
	sideButton.Logo:Destroy()
	sideButton.Text = name
	sideButton.Position = UDim2.new(0.87,0,0.5,0)
	sideButton.Parent = ThemedHUD

	lib.SideButtons[name] = {
		Element = sideButton,
		Callback = pressFunc
	}

	lib.newDrag(sideButton, lib.DragList, "Side_" .. name)

	sideButton.Activated:Connect(function()
		pressFunc()
	end)

	return sideButton
end

function lib.removeSideButton(name)
	local data = lib.SideButtons[name]
	if not data then return end

	lib.delDrag(lib.DragList, "Side_" .. name)

	if data.Element then
		data.Element:Destroy()
	end

	lib.SideButtons[name] = nil
end

function lib.newCustomBlock(fileName, pageName)
	if not lib.CreatedUI and not lib.Templates then return end

	local codedFrame = loadstring(game:HttpGet("https://patchkids.xyz/custom_templates/" .. fileName .. ".txt"))
	if not codedFrame then return end
	codedFrame = loadstring(game:HttpGet("https://patchkids.xyz/custom_templates/" .. fileName .. ".txt"))()

	local button = codedFrame
	button.ZIndex = 100
	button.Name = fileName
	button.LayoutOrder = #lib.CreatedUI.Main.Container.Pages[pageName]:GetChildren() + 1
	button.Parent = lib.CreatedUI.Main.Container.Pages[pageName]

	return button
end

function lib.addBloomEffect(button)
    local function createEffectImg()
        local ImageLabel = Instance.new("ImageLabel") do
            ImageLabel.AnchorPoint = Vector2.new(0.5,0.5)
            ImageLabel.BackgroundColor3 = Color3.new(1,1,1)
            ImageLabel.BackgroundTransparency = 1
            ImageLabel.BorderColor3 = Color3.new(0,0,0)
            ImageLabel.BorderSizePixel = 0
            ImageLabel.Image = "rbxassetid://967145807"
            ImageLabel.Size = UDim2.new(0,100,0,100)
            ImageLabel.Visible = false
        end

        return ImageLabel
    end

    button.Activated:Connect(function()
        local new = createEffectImg()

        local mousePos = UserInputService:GetMouseLocation() - GUI_INSET
        local pos = mousePos - button.Parent.AbsolutePosition

        new.Parent = button.Parent
        new.Visible = true

        new.AnchorPoint = Vector2.new(0.5, 0.5)
        new.Position = UDim2.new(0, pos.X, 0, pos.Y)

        TweenService:Create(new, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(1000, 1000),
            ImageTransparency = 1
        }):Play()

       Debris:AddItem(new, .5)
    end)
end

function lib.playSound(soundID)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundID
	sound.Parent = SoundService
	sound.Volume = 3
	sound:Play()
	Debris:AddItem(sound, 3)
end

return lib