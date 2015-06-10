local TheInput = GLOBAL.TheInput
local show_type = GetModConfigData("show_type")

function GetHealth(e)  
	if e ~= nil and e.components ~= nil and e.components.health and e.components.healthinfo then
		local str = e.components.healthinfo.text
		local h=e.components.health
		local mx=math.floor(h.maxhealth-h.minhealth)
		local cur=math.floor(h.currenthealth-h.minhealth)

		if type( mx ) == "number" and type( cur ) == "number" then
			if show_type == 0 then
				str = "["..cur.." / "..mx .."]"
			elseif show_type == 1 then
				str = "["..math.floor(cur*100/mx).."%]"
			else
				str = "["..cur.." / "..mx .." "..math.floor(cur*100/mx).."%]"
			end
		end

		if e.components.healthinfo then
			e.components.healthinfo:SetText(str)
		end
	end
end

AddClassPostConstruct("components/health", function(self)
	local original_SetVal = self.SetVal

	self.SetVal = function(self, val, cause)
		GetHealth(self.inst)
		original_SetVal(self, val, cause)
	end
end)

AddGlobalClassPostConstruct('widgets/hoverer', 'HoverText', function(self)
	self.OnUpdate = function(self)

		local using_mouse = self.owner.components and self.owner.components.playercontroller:UsingMouse()        
	    
	    if using_mouse ~= self.shown then
	        if using_mouse then
	            self:Show()
	        else
	            self:Hide()
	        end
	    end
	    
	    if not self.shown then 
	        return 
	    end
	    
	    local str = nil
	    if self.isFE == false then 
	        str = self.owner.HUD.controls:GetTooltip() or self.owner.components.playercontroller:GetHoverTextOverride()
	    else
	        str = self.owner:GetTooltip()
	    end

	    local secondarystr = nil
	 
	    if not str and self.isFE == false then
	        local lmb = self.owner.components.playercontroller:GetLeftMouseAction()
	        if lmb then
	            
	            str = lmb:GetActionString()
	            
	            if lmb.target and lmb.invobject == nil and lmb.target ~= lmb.doer then
	                local name = lmb.target:GetDisplayName() or (lmb.target.components.named and lb.target.components.named.name)
	                
	                
	                if name then
	                    local adjective = lmb.target:GetAdjective()
	                    
	                    if adjective then
	                        str = str.. " " .. adjective .. " " .. name
	                    else
	                        str = str.. " " .. name
	                    end
	                    
	                    if lmb.target.components.stackable and lmb.target.components.stackable.stacksize > 1 then
	                        str = str .. " x" .. tostring(lmb.target.components.stackable.stacksize)
	                    end
	                    if lmb.target.components.inspectable and lmb.target.components.inspectable.recordview and lmb.target.prefab then
	                        GLOBAL.ProfileStatsSet(lmb.target.prefab .. "_seen", true)
	                    end
	                end
	            end

				if lmb.target and lmb.target ~= lmb.doer and lmb.target.components and lmb.target.components.healthinfo and lmb.target.components.healthinfo.text ~= '' then
					local name = lmb.target:GetDisplayName() or (lmb.target.components.named and lmb.target.components.named.name) or ""
					--local i,j = string.find(str, " " .. name, nil, true)
					--if i ~= nil and i > 1 then str = string.sub(str, 1, (i-1)) end
					str = str.. "\n" .. lmb.target.components.healthinfo.text
				end
	        end
	        local rmb = self.owner.components.playercontroller:GetRightMouseAction()
	        if rmb then
	            secondarystr = GLOBAL.STRINGS.RMB .. ": " .. rmb:GetActionString()
	        end
	    end

	    if str then
	        self.text:SetString(str)
	        self.text:Show()
	    else
	        self.text:Hide()
	    end
	    if secondarystr then
	        YOFFSETUP = -80
	        YOFFSETDOWN = -50
	        self.secondarytext:SetString(secondarystr)
	        self.secondarytext:Show()
	    else
	        self.secondarytext:Hide()
	    end

	    local changed = (self.str ~= str) or (self.secondarystr ~= secondarystr)
	    self.str = str
	    self.secondarystr = secondarystr
	    if changed then
	        local pos = TheInput:GetScreenPosition()
	        self:UpdatePosition(pos.x, pos.y)
	    end
	end
end)

AddGlobalClassPostConstruct('widgets/controls', 'Controls', function(self)
	self.OnUpdate = function(self)		
		local controller_mode = TheInput:ControllerAttached()
		local controller_id = TheInput:GetControllerID()
		
		if controller_mode then
			self.mapcontrols:Hide()
		else		
			self.mapcontrols:Show()
		end


	    for k,v in pairs(self.containers) do
			if v.should_close_widget then
				self.containers[k] = nil
				v:Kill()
			end
		end
	    
	    if self.demotimer then
			if GLOBAL.IsGamePurchased() then
				self.demotimer:Kill()
				self.demotimer = nil
			end
		end
		
		if controller_mode and not self.inv.open and not self.crafttabs.controllercraftingopen then

			local ground_l, ground_r = self.owner.components.playercontroller:GetGroundUseAction()
			local ground_cmds = {}
			if self.owner.components.playercontroller.deployplacer or self.owner.components.playercontroller.placer then
				local placer = self.terraformplacer

				if self.owner.components.playercontroller.deployplacer then
					self.groundactionhint:Show()
					self.groundactionhint:SetTarget(self.owner.components.playercontroller.deployplacer)
					
					if self.owner.components.playercontroller.deployplacer.components.placer.can_build then
						if TheInput:ControllerAttached() then
							self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION) .. " " .. self.owner.components.playercontroller.deployplacer.components.placer:GetDeployAction():GetActionString().."\n"..TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION).." "..STRINGS.UI.HUD.CANCEL)
						else
							self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION) .. " " .. self.owner.components.playercontroller.deployplacer.components.placer:GetDeployAction():GetActionString())
						end
							
					else
						self.groundactionhint.text:SetString("")	
					end
					
				elseif self.owner.components.playercontroller.placer then
					self.groundactionhint:Show()
					self.groundactionhint:SetTarget(self.owner)
					self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION) .. " " .. GLOBAL.STRINGS.UI.HUD.BUILD.."\n" .. TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) .. " " .. STRINGS.UI.HUD.CANCEL.."\n")	
				end
			elseif ground_r then
				--local cmds = {}
				self.groundactionhint:Show()
				self.groundactionhint:SetTarget(self.owner)				
				table.insert(ground_cmds, TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ALTACTION) .. " " .. ground_r:GetActionString())
				self.groundactionhint.text:SetString(table.concat(ground_cmds, "\n"))
			elseif not ground_r then
				self.groundactionhint:Hide()
			end
			
			local attack_shown = false
			if self.owner.components.playercontroller.controller_target and self.owner.components.playercontroller.controller_target:IsValid() then

				local cmds = {}
				local textblock = self.playeractionhint.text
				if self.groundactionhint.shown and 
				GLOBAL.distsq(GetPlayer():GetPosition(), self.owner.components.playercontroller.controller_target:GetPosition()) < 1.33 then
					--You're close to your target so we should combine the two text blocks.
					cmds = ground_cmds
					textblock = self.groundactionhint.text
					self.playeractionhint:Hide()
				else
					self.playeractionhint:Show()
					self.playeractionhint:SetTarget(self.owner.components.playercontroller.controller_target)
				end

				local l, r = self.owner.components.playercontroller:GetSceneItemControllerAction(self.owner.components.playercontroller.controller_target)
							
				local target = self.owner.components.playercontroller.controller_target
				
				-- table.insert(cmds, target:GetDisplayName())
				local health = ""
				if controller_target and controller_target.components and controller_target.components.healthinfo and controller_target.components.healthinfo.text ~= '' then
					health = controller_target.components.healthinfo.text
				end
				table.insert(cmds, controller_target:GetDisplayName() .. "\n" ..health)

				if target == self.owner.components.playercontroller.controller_attack_target then
					table.insert(cmds, TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ATTACK) .. " " .. GLOBAL.STRINGS.UI.HUD.ATTACK)
					attack_shown = true
				end
				if GetPlayer():CanExamine() then
					table.insert(cmds,TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_INSPECT) .. " " .. GLOBAL.STRINGS.UI.HUD.INSPECT)
				end
				if l then
					table.insert(cmds, TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION) .. " " .. l:GetActionString())
				end
				if r and not ground_r then
					table.insert(cmds, TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ALTACTION) .. " " .. r:GetActionString())
				end

				textblock:SetString(table.concat(cmds, "\n"))
			else
				self.playeractionhint:Hide()
				self.playeractionhint:SetTarget(nil)
			end
			
			if self.owner.components.playercontroller.controller_attack_target and not attack_shown then
				self.attackhint:Show()
				self.attackhint:SetTarget(self.owner.components.playercontroller.controller_attack_target)
				local health = ""
				if controller_attack_target and controller_attack_target.components and controller_attack_target.components.healthinfo and controller_attack_target.components.healthinfo.text ~= '' then
					health = controller_attack_target:GetDisplayName() .. " " .. controller_attack_target.components.healthinfo.text
				end

				self.attackhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ATTACK) .. " " .. GLOBAL.STRINGS.UI.HUD.ATTACK .. "\n" .. health)
				-- self.attackhint.text:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ATTACK) .. " " .. STRINGS.UI.HUD.ATTACK)
			else
				self.attackhint:Hide()
				self.attackhint:SetTarget(nil)
			end
			
		else
		
			self.attackhint:Hide()
			self.attackhint:SetTarget(nil)
			
			self.playeractionhint:Hide()
			self.playeractionhint:SetTarget(nil)
			
			self.groundactionhint:Hide()
			self.groundactionhint:SetTarget(nil)
		end
		

		--default offsets	
		self.playeractionhint:SetScreenOffset(0,0)
		self.attackhint:SetScreenOffset(0,0)
		
		--if we are showing both hints, make sure they don't overlap
		if self.attackhint.shown and self.playeractionhint.shown then
			
			local w1, h1 = self.attackhint.text:GetRegionSize()
			local x1, y1 = self.attackhint:GetPosition():Get()
			--print (w1, h1, x1, y1)
			
			local w2, h2 = self.playeractionhint.text:GetRegionSize()
			local x2, y2 = self.playeractionhint:GetPosition():Get()
			--print (w2, h2, x2, y2)
			
			local sep = (x1 + w1/2) < (x2 - w2/2) or
						(x1 - w1/2) > (x2 + w2/2) or
						(y1 + h1/2) < (y2 - h2/2) or					
						(y1 - h1/2) > (y2 + h2/2)
						
			if not sep then
				local a_l = x1 - w1/2
				local a_r = x1 + w1/2
				
				local p_l = x2 - w2/2
				local p_r = x2 + w2/2
				
				if math.abs(p_r - a_l) < math.abs(p_l - a_r) then
					local d = (p_r - a_l) + 20
					self.attackhint:SetScreenOffset(d/2,0)
					self.playeractionhint:SetScreenOffset(-d/2,0)
				else
					local d = (a_r - p_l) + 20
					self.attackhint:SetScreenOffset( -d/2,0)
					self.playeractionhint:SetScreenOffset(d/2,0)
				end
			end
		end
	end
end)

AddPrefabPostInitAny(function(inst)
	if inst.components.healthinfo == nil then
		if  inst:HasTag("hive") or 
			inst:HasTag("eyeturret") or 
			inst:HasTag("houndmound") or 
			inst:HasTag("ghost") or 
			inst:HasTag("insect") or 
			inst:HasTag("spider") or
			inst:HasTag("chess") or 
			inst:HasTag("mech") or
			inst:HasTag("mound") or
			inst:HasTag("shadow") or
			inst:HasTag("tree") or
			inst:HasTag("veggie") or
			inst:HasTag("shell") or
			inst:HasTag("rocky") or
			inst:HasTag("smallcreature") or
			inst:HasTag("largecreature") or
			inst:HasTag("wall") or
			inst:HasTag("character") or
			inst:HasTag("companion") or
			inst:HasTag("glommer") or
			inst:HasTag("animal") or
			inst:HasTag("monster") or
			inst:HasTag("prey") or
			inst:HasTag("scarytoprey") or
			inst:HasTag("player") 
									then

			inst:AddComponent("healthinfo")
			if inst.components.health then
				GetHealth(inst)
			end
		end
	end
end)