local PANEL = {}

function PANEL:Init()
	self:SetSize(600, 400)
	self:Center()
	self:SetTitle("Character Creation")
	self:MakePopup()
	self:SetBackgroundBlur(true)

	self.nextButton = vgui.Create("DButton", self)
	self.nextButton:SetPos(530,370)
	self.nextButton:SetSize(60,20)
	self.nextButton:SetText("Finish")
	self.nextButton:SetDisabled(false)
	self.nextButton.DoClick = function()
		local characterName = self.nameEntry:GetValue()
		local characterGender = self.genderBox:GetValue():lower()
		local characterModel = self.characterPreview.Entity:GetModel()
		local characterSkin = self.characterPreview.Entity:GetSkin()

		local msg = Derma_Message

		if characterName == "" then return msg("Please fill in the character name.", "impulse", "OK") end
		--if #characterName:Explode(" ") > 3 then return msg("Too many spaces in character name.", "impulse", "OK") end
		if characterName:len() >= 24 then return msg("Character name too long. (max 24 characters)", "impulse", "OK") end
		if characterName:len() <= 6  then return msg("Character name too short. (min 6 characters)", "impulse", "OK") end

		Derma_Query("Are you sure you are finished? You can edit your character later, but it will cost a fee.", "impulse", "Yes", function()
			print("[impulse] Sending character data to server")
			netstream.Start("impulseCharacterCreate", characterName, characterModel, characterSkin) -- send the completed character to server for checks and creation
			self:GetParent():Remove() -- close main menu menu
			impulse.hudEnabled = true
			impulse_isNewPlayer = false
		end, "No, take me back")
	end

	self.characterPreview = vgui.Create("DModelPanel", self)
	self.characterPreview:SetSize(600,400)
	self.characterPreview:SetPos(0,30)
	self.characterPreview:SetModel(impulse.Config.DefaultMaleModels[1])
	self.characterPreview:MoveToBack()
	self.characterPreview:SetCursor("arrow")
	self.characterPreview:SetFOV(70)
	self.characterPreview:SetCamPos(Vector(52, 52, 52))
 	function self.characterPreview:LayoutEntity(ent) 
  		ent:SetAngles(Angle(0,40,0))
 	end

 	local characterPreview = self.characterPreview

	self.nameLbl = vgui.Create("DLabel", self)
 	self.nameLbl:SetFont("Impulse-Elements18-Shadow")
	self.nameLbl:SetText("Full Name:")
	self.nameLbl:SizeToContents()
	self.nameLbl:SetPos(10,40)

 	self.nameEntry = vgui.Create("DTextEntry", self)
 	self.nameEntry:SetSize(180,23)
 	self.nameEntry:SetPos(10,60)

	self.genderLbl = vgui.Create("DLabel", self)
	self.genderLbl:SetFont("Impulse-Elements18-Shadow")
	self.genderLbl:SetText("Gender:")
	self.genderLbl:SizeToContents()
	self.genderLbl:SetPos(10,90)

  	self.genderBox = vgui.Create("DComboBox", self)
  	self.genderBox:SetPos(10,110)
  	self.genderBox:SetSize(180,23)
  	self.genderBox:SetValue("Male")
  	self.genderBox:AddChoice("Male")
  	self.genderBox:AddChoice("Female")
  	function self.genderBox.OnSelect(panel, index, value)
  		if value == "Male" then
  			self:PopulateModels(impulse.Config.DefaultMaleModels)
  			characterPreview:SetModel(impulse.Config.DefaultMaleModels[1])
  			self.skinSlider:SetValue(0)
  			self.skinSlider:SetMax(characterPreview.Entity:SkinCount())
  		else
  			self:PopulateModels(impulse.Config.DefaultFemaleModels)
  			characterPreview:SetModel(impulse.Config.DefaultFemaleModels[1])
  			self.skinSlider:SetValue(0)
  			self.skinSlider:SetMax(characterPreview.Entity:SkinCount())
  		end
  	end

	self.modelLbl = vgui.Create("DLabel", self)
	self.modelLbl:SetFont("Impulse-Elements18-Shadow")
	self.modelLbl:SetText("Models:")
	self.modelLbl:SizeToContents()
	self.modelLbl:SetPos(400,40)

  	self:PopulateModels(impulse.Config.DefaultMaleModels)

	self.skinLbl = vgui.Create("DLabel", self)
	self.skinLbl:SetFont("Impulse-Elements18-Shadow")
	self.skinLbl:SetText("Skin:")
	self.skinLbl:SizeToContents()
	self.skinLbl:SetPos(400,260)

	self.skinSlider = vgui.Create("DNumSlider", self)
	self.skinSlider:SetMin(0)
	self.skinSlider:SetDecimals(0)
	self.skinSlider:SetMax(characterPreview.Entity:SkinCount()-1)
	self.skinSlider:SetSize(395,20)
	self.skinSlider:SetPos(230, 280)
	self.skinSlider:SetValue(0)
	function self.skinSlider:OnValueChanged(newSkin)
		characterPreview.Entity:SetSkin(newSkin)
	end
end

function PANEL:PopulateModels(modelTable)
	if self.modelScroll then self.modelScroll:Remove() end -- done to fix some weird bugs when changing size of the iconlayout with the sidebar

 	self.modelScroll = vgui.Create("DScrollPanel", self)
 	self.modelScroll:SetPos(400,60)
 	self.modelScroll:SetSize(200,185)

 	self.modelBase = vgui.Create("DIconLayout", self.modelScroll)
 	self.modelBase:Dock(FILL)
 	self.modelBase:SetSpaceY(5)
 	self.modelBase:SetSpaceX(5)

  	for _, model in pairs(modelTable) do
    	local modelIcon = vgui.Create("SpawnIcon", self.modelBase)
    	modelIcon:SetModel(model)
    	modelIcon:SetSize(58,58)
    	modelIcon.savedModel = model
    	modelIcon.DoClick = function()
    		self.characterPreview:SetModel(modelIcon.savedModel)
    		self.skinSlider:SetValue(0)
    		self.skinSlider:SetMax(self.characterPreview.Entity:SkinCount()-1)
    	end
  	end
end


vgui.Register("impulseCharacterCreator", PANEL, "DFrame")