--!strict
-- Builds an outfit from parts welded to an R15 rig. Server and the preview
-- viewport both call this. assetId on a catalog item is reserved for later.

local OutfitCatalog = require(script.Parent.OutfitCatalog)
local Types = require(script.Parent.Types)

type OutfitSlot = Types.OutfitSlot

local OutfitBuilder = {}

local function colorOf(slot: OutfitSlot): Color3
	return Color3.new(math.clamp(slot.r, 0, 1), math.clamp(slot.g, 0, 1), math.clamp(slot.b, 0, 1))
end

local function limb(model: Model, name: string): BasePart?
	local part = model:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function piece(folder: Folder, target: BasePart, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = "OutfitPart"
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = folder
	local weld = Instance.new("Weld")
	weld.Part0 = target
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	return part
end

local function capeSegment(folder: Folder, previous: BasePart, length: number, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = "CapeSegment"
	part.Size = Vector3.new(1.6, length, 0.12)
	part.Color = color
	part.Material = Enum.Material.Fabric
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = false
	part.CustomPhysicalProperties = PhysicalProperties.new(0.2, 0.1, 0.2, 1, 1)
	part.Parent = folder
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, -previous.Size.Y / 2, 0)
	a0.Parent = previous
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, length / 2, 0)
	a1.Parent = part
	local socket = Instance.new("BallSocketConstraint")
	socket.Attachment0 = a0
	socket.Attachment1 = a1
	socket.LimitsEnabled = true
	socket.UpperAngle = 35
	socket.Parent = part
	part.CFrame = previous.CFrame * CFrame.new(0, -(previous.Size.Y / 2 + length / 2), 0.2)
	return part
end

local function aura(folder: Folder, root: BasePart, style: string, color: Color3)
	local attachment = Instance.new("Attachment")
	attachment.Name = "Aura"
	attachment.Parent = root
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Rate = 18
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.Size = NumberSequence.new(0.6)
	emitter.Parent = attachment
	if style == "flame" then
		emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
		emitter.Rate = 24
	elseif style == "smoke" then
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.LightEmission = 0.2
	elseif style == "frost" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.tex"
		emitter.Speed = NumberRange.new(0.4, 1.2)
	else
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.tex"
	end
	local marker = Instance.new("ObjectValue")
	marker.Name = "AuraLink"
	marker.Value = attachment
	marker.Parent = folder
	folder.Destroying:Connect(function()
		attachment:Destroy()
	end)
end

function OutfitBuilder.Clear(model: Model)
	local existing = model:FindFirstChild("FightingOutfit")
	if existing then
		existing:Destroy()
	end
end

function OutfitBuilder.Apply(model: Model, outfit: { [string]: OutfitSlot })
	OutfitBuilder.Clear(model)
	local folder = Instance.new("Folder")
	folder.Name = "FightingOutfit"
	folder.Parent = model
	local head = limb(model, "Head")
	local upper = limb(model, "UpperTorso")
	local lower = limb(model, "LowerTorso")
	local root = limb(model, "HumanoidRootPart")

	local function slot(category: string): (OutfitSlot?, any)
		local worn = outfit[category]
		if not worn then
			return nil, nil
		end
		return worn, OutfitCatalog.Find(category, worn.id)
	end

	local headSlot, headItem = slot("Headgear")
	if head and headSlot and headItem then
		local color = colorOf(headSlot)
		local style = headItem.style
		if style == "visor" then
			piece(folder, head, Vector3.new(1.3, 0.25, 0.4), CFrame.new(0, 0.05, -0.55), color, Enum.Material.Glass)
		elseif style == "mask" then
			piece(folder, head, Vector3.new(1.1, 0.7, 0.3), CFrame.new(0, -0.15, -0.5), color, Enum.Material.SmoothPlastic)
		elseif style == "helm" then
			piece(folder, head, Vector3.new(1.4, 0.7, 1.4), CFrame.new(0, 0.45, 0), color, Enum.Material.Metal)
		elseif style == "crown" then
			piece(folder, head, Vector3.new(1.3, 0.35, 1.3), CFrame.new(0, 0.7, 0), color, Enum.Material.Metal)
		elseif style == "tiara" then
			piece(folder, head, Vector3.new(1.15, 0.18, 0.3), CFrame.new(0, 0.35, -0.45), color, Enum.Material.Neon)
		else
			piece(folder, head, Vector3.new(1.3, 0.8, 1.2), CFrame.new(0, 0.35, 0.1), color, Enum.Material.Fabric)
		end
	end

	local suitSlot, suitItem = slot("Suits")
	if upper and suitSlot and suitItem then
		local color = colorOf(suitSlot)
		local style = suitItem.style
		local mat = if style == "suit" then Enum.Material.SmoothPlastic else Enum.Material.Metal
		if style == "vest" or style == "wrap" then
			mat = Enum.Material.Fabric
		end
		piece(folder, upper, Vector3.new(2.05, 1.7, 1.1), CFrame.new(0, 0.05, 0), color, mat)
		if style == "armor" or style == "plate" then
			piece(folder, upper, Vector3.new(0.8, 0.8, 0.25), CFrame.new(0, 0.2, -0.6), color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Neon)
		end
	end

	local pantSlot, pantItem = slot("Pants")
	if lower and pantSlot and pantItem then
		local color = colorOf(pantSlot)
		piece(folder, lower, Vector3.new(1.9, 1.3, 1.0), CFrame.new(0, -0.1, 0), color, Enum.Material.Fabric)
		if pantItem.style == "greaves" or pantItem.style == "legplate" then
			local left = limb(model, "LeftUpperLeg")
			local right = limb(model, "RightUpperLeg")
			if left then
				piece(folder, left, Vector3.new(0.9, 1.3, 0.8), CFrame.new(0, -0.1, 0), color, Enum.Material.Metal)
			end
			if right then
				piece(folder, right, Vector3.new(0.9, 1.3, 0.8), CFrame.new(0, -0.1, 0), color, Enum.Material.Metal)
			end
		end
	end

	local capeSlot, capeItem = slot("Capes")
	if upper and capeSlot and capeItem then
		local color = colorOf(capeSlot)
		local anchor = piece(folder, upper, Vector3.new(1.4, 0.25, 0.25), CFrame.new(0, 0.7, 0.55), color, Enum.Material.Fabric)
		local length = if capeItem.style == "longcape" then 1.3 else 0.8
		local count = if capeItem.style == "scarf" then 1 else 3
		local previous: BasePart = anchor
		for _ = 1, count do
			previous = capeSegment(folder, previous, length, color)
		end
	end

	local gloveSlot, gloveItem = slot("Gloves")
	if gloveSlot and gloveItem then
		local color = colorOf(gloveSlot)
		for _, name in { "LeftHand", "RightHand" } do
			local hand = limb(model, name)
			if hand then
				piece(folder, hand, Vector3.new(0.55, 0.4, 0.7), CFrame.new(0, -0.1, 0), color, Enum.Material.Fabric)
				if gloveItem.style == "gauntlet" or gloveItem.style == "bracer" then
					local armName = if string.find(name, "Left", 1, true) then "LeftLowerArm" else "RightLowerArm"
					local arm = limb(model, armName)
					if arm then
						piece(folder, arm, Vector3.new(0.7, 0.5, 0.7), CFrame.new(0, -0.4, 0), color, Enum.Material.Metal)
					end
				end
			end
		end
	end

	local bootSlot, bootItem = slot("Boots")
	if bootSlot and bootItem then
		local color = colorOf(bootSlot)
		for _, name in { "LeftFoot", "RightFoot" } do
			local foot = limb(model, name)
			if foot then
				piece(folder, foot, Vector3.new(0.7, 0.4, 1.2), CFrame.new(0, -0.05, -0.1), color, Enum.Material.SmoothPlastic)
			end
		end
		if bootItem.style == "high" or bootItem.style == "armored" or bootItem.style == "shin" then
			for _, name in { "LeftLowerLeg", "RightLowerLeg" } do
				local leg = limb(model, name)
				if leg then
					piece(folder, leg, Vector3.new(0.75, 1.1, 0.7), CFrame.new(0, -0.2, 0), color, Enum.Material.SmoothPlastic)
				end
			end
		end
	end

	local auraSlot, auraItem = slot("Auras")
	if root and auraSlot and auraItem then
		aura(folder, root, auraItem.style, colorOf(auraSlot))
	end
end

return OutfitBuilder
