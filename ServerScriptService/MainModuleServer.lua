local RepStorage = game:GetService("ReplicatedStorage")

local module = {}

module.gun = {	
	player = nil;

	weaponName = "";
	weaponType = "";

	headshotDamage = 0;
	bodyshotDamage = 0;

	aimDirection = nil;
	aimOrigin = nil;

	holdAnim = nil;
	aimAnim = nil;
	reloadAnim = nil;
	shootAnim = nil;

	equipped = nil;
	reloading = nil;
    ammo = nil;
    magAmmo = nil;

	remote = nil;
}

function module.gun:Equip()
	local gun = game:GetService("ReplicatedStorage"):WaitForChild(self.weaponName):Clone()
	local handle = gun.GunComponents.Handle
	local aim = gun.GunComponents.Aim
	local handle6D = Instance.new("Motor6D",self.player.Character.RightLowerArm)
	local holdAnim = game:GetService("ReplicatedStorage"):WaitForChild(self.weaponName.."_Animations"):WaitForChild("Hold_Char")

	for i,v in pairs(gun:GetDescendants()) do
		if v:IsA("BasePart") and v ~= handle and v ~= aim then
			local motor = Instance.new("Motor6D")
			motor.Name = v.Name
			motor.Part0 = handle
			motor.Part1 = v
			motor.C0 = motor.Part0.CFrame:inverse() * motor.Part1.CFrame
			motor.Parent = handle
		end
	end

	handle6D.Name = "Handle6D"
	gun.Parent = self.player.Character
	handle6D.Part0 = self.player.Character.RightLowerArm
	handle6D.Part1 = aim

	self.holdAnim:Play()

	self.equipped.Value = true
	self.remote:FireClient(self.player,"Equip")
end

function module.gun:Unequip()
	self.holdAnim:Stop()
	self.player.Character:FindFirstChild(self.weaponName):Destroy()
	self.equipped.Value = false
	self.remote:FireClient(self.player,"Unequip")
end

function module.gun:Reload()
	if self.ammo.Value < self.magAmmo.Value and self.reloading.Value == false then
		self.reloading.Value = true
		local character = self.player.Character
		local reloadSound = character:FindFirstChild(self.weaponName).GunComponents.Handle.ReloadSound

		self:AimHand()
		self.reloadAnim:Play()
		reloadSound:Play()

		wait(self.reloadAnim.Length)

		self.ammo.Value = self.magAmmo.Value
		self.reloading.Value = false
	end
end

function module.gun:Shoot()
	if self.ammo.Value > 0 and self.reloading.Value == false then
		local character = self.player.Character
		local barrel = character:FindFirstChild(self.weaponName).GunComponents.Barrel
		local muzzleEffect = barrel.MuzzleEffect
		local shootSound = barrel.ShootSound

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.IgnoreWater = true

		local raycastResult = game.Workspace:Raycast(self.aimOrigin.Value,self.aimDirection.Value * 1000,raycastParams)

		self.ammo.Value -= 1

		if raycastResult then
			self:Hit(raycastResult.Instance,raycastResult.Position,{character})
			barrel.Attachment1.WorldPosition = raycastResult.Position
		end

		if self.weaponType == "Sniper" then
			self:AimHand()
			self.shootAnim:Play()
			muzzleEffect:Emit()
			shootSound:Play()
		else
			muzzleEffect:Emit()
			shootSound:Play()
		end
		
		wait(0.2)
		barrel.Attachment1.WorldPosition = barrel.Position
	else
		if self.ammo.Value == 0 and self.reloading.Value == false then
			self:Reload()
		end
	end
end

function module.gun:Kill(hitPart)
	if hitPart.Name == "Head" then
		hitPart.Parent.Humanoid:TakeDamage(self.headshotDamage)
	else
		hitPart.Parent.Humanoid:TakeDamage(self.bodyshotDamage)
	end
end

function module.gun:Hit(hitPart,hitPosition,invincible)
	local cantHit = invincible
	local character = self.player.Character
	local barrel = character:FindFirstChild(self.weaponName).GunComponents.Barrel

	barrel.Attachment1.WorldPosition = hitPosition

	if hitPart.Parent:FindFirstChild("Humanoid") then
		self:Kill(hitPart)
	else
		if hitPart.Material == Enum.Material.Glass or hitPart.Material == Enum.Material.Plastic or hitPart.Material == Enum.Material.SmoothPlastic or hitPart.Material == Enum.Material.Wood or hitPart.Material == Enum.Material.WoodPlanks then
			table.insert(cantHit,(#cantHit + 1),hitPart)
			self:Wallbang(hitPosition,cantHit)
		end
	end
end

function module.gun:Wallbang(hitPosition,invincible)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = invincible
	raycastParams.IgnoreWater = true

	local raycastResult = game.Workspace:Raycast(hitPosition,self.aimDirection.Value * 1000,raycastParams)

	if raycastResult then
		self:Hit(raycastResult.Instance,raycastResult.Position,invincible)
	end
end

function module.gun:AimSight()
	local aim = game:GetService("ReplicatedStorage"):WaitForChild(self.weaponName.."_Animations"):WaitForChild("Aim_Char")
	if self.aimAnim then
		self.aimAnim:Play()
	else
		self.aimAnim = self.player.Character.Humanoid:LoadAnimation(aim)
		self.aimAnim:Play()
	end
	self.player.Character.Humanoid.WalkSpeed = 10
end

function module.gun:AimHand()
	if self.aimAnim then
		self.aimAnim:Stop()
	end
	self.player.Character.Humanoid.WalkSpeed = 16
end

function module.gun:New(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

return module