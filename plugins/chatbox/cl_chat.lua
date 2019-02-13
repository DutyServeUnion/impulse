-- impulse's chatbox is based uponimpulse.chatBox by Exho
-- Author: vin, Exho (obviously), Tomelyr, LuaTenshi
-- Version: 4/12/15

impulse.chatBox = {}

impulse.DefineSetting("chat_fadetime", {name="Chatbox fade time", category="Chatbox", type="slider", default=12, minValue=4, maxValue=120})
impulse.DefineSetting("chat_fontsize", {name="Chatbox font size", category="Chatbox", type="dropdown", default="Medium", options={"Small", "Medium", "Large"}})

--// Builds the chatbox but doesn't display it
function impulse.chatBox.buildBox()
	impulse.chatBox.frame = vgui.Create("DFrame")
	impulse.chatBox.frame:SetSize( ScrW()*0.375, ScrH()*0.35 )
	impulse.chatBox.frame:SetTitle("")
	impulse.chatBox.frame:ShowCloseButton( false )
	impulse.chatBox.frame:SetDraggable( true )
	impulse.chatBox.frame:SetSizable( true )
	impulse.chatBox.frame:SetPos( 10, (ScrH() - impulse.chatBox.frame:GetTall()) - 200)
	impulse.chatBox.frame:SetMinWidth( 300 )
	impulse.chatBox.frame:SetMinHeight( 100 )
	impulse.chatBox.frame:SetPopupStayAtBack(true)
	impulse.chatBox.frame.Paint = function( self, w, h )
		impulse.blur( self, 10, 20, 255 )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
		
		draw.RoundedBox( 0, 0, 0, w, 25, Color( 80, 80, 80, 100 ) )
	end
	impulse.chatBox.oldPaint = impulse.chatBox.frame.Paint
	impulse.chatBox.frame.Think = function()
		if input.IsKeyDown( KEY_ESCAPE ) then
			impulse.chatBox.hideBox()
		end
	end
	
	impulse.chatBox.entry = vgui.Create("DTextEntry", impulse.chatBox.frame) 
	impulse.chatBox.entry:SetSize( impulse.chatBox.frame:GetWide() - 50, 20 )
	impulse.chatBox.entry:SetTextColor( color_white )
	impulse.chatBox.entry:SetFont("Impulse-ChatSmall")
	impulse.chatBox.entry:SetDrawBorder( false )
	impulse.chatBox.entry:SetDrawBackground( false )
	impulse.chatBox.entry:SetCursorColor( color_white )
	impulse.chatBox.entry:SetHighlightColor( Color(52, 152, 219) )
	impulse.chatBox.entry:SetPos( 45, impulse.chatBox.frame:GetTall() - impulse.chatBox.entry:GetTall() - 5 )
	impulse.chatBox.entry.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		derma.SkinHook( "Paint", "TextEntry", self, w, h )
	end

	impulse.chatBox.entry.OnTextChanged = function( self )
		if self and self.GetText then 
			gamemode.Call( "ChatTextChanged", self:GetText() or "" )
		end
	end

	impulse.chatBox.entry.OnKeyCodeTyped = function( self, code )
		local types = {"", "teamchat", "console"}

		if code == KEY_ESCAPE then

			impulse.chatBox.hideBox()
			gui.HideGameUI()

		elseif code == KEY_TAB then
			
			impulse.chatBox.TypeSelector = (impulse.chatBox.TypeSelector and impulse.chatBox.TypeSelector + 1) or 1
			
			if impulse.chatBox.TypeSelector > 3 then impulse.chatBox.TypeSelector = 1 end
			if impulse.chatBox.TypeSelector < 1 then impulse.chatBox.TypeSelector = 3 end
			
			impulse.chatBox.ChatType = types[impulse.chatBox.TypeSelector]

			timer.Simple(0.001, function() impulse.chatBox.entry:RequestFocus() end)

		elseif code == KEY_ENTER then
			-- Replicate the client pressing enter
			
			if string.Trim( self:GetText() ) != "" then
				if impulse.chatBox.ChatType == types[2] then
					LocalPlayer():ConCommand("say_team \"" .. (self:GetText() or "") .. "\"")
				elseif impulse.chatBox.ChatType == types[3] then
					LocalPlayer():ConCommand(self:GetText() or "")
				else
					netstream.Start("msg", self:GetText()) -- use netstream to send messages its faster + we can send bigger messages
				end
			end

			impulse.chatBox.TypeSelector = 1
			impulse.chatBox.hideBox()
		end
	end

	impulse.chatBox.chatLog = vgui.Create("impulseRichText", impulse.chatBox.frame)
	impulse.chatBox.chatLog:SetPos(5, 30)
	impulse.chatBox.chatLog:SetSize(impulse.chatBox.frame:GetWide() - 10, impulse.chatBox.frame:GetTall() - 70)
	impulse.chatBox.chatLog.PaintOver = function(self, w, h)
		local entry = impulse.chatBox.entry

		if (impulse.chatBox.frame:IsActive() and IsValid(entry)) then
			local text = entry:GetValue()
			if (text:sub(1, 1) == "/") then
				local command = string.PatternSafe(string.lower(text))

				impulse.blur( self, 10, 20, 255 )

				surface.SetDrawColor(0, 0, 0, 200)
				surface.DrawRect(0, 0, w, h)

				local i = 0

 				for k, v in pairs(impulse.chatCommands) do
 					if (string.find(k, command)) then
 						local c = impulse.Config.MainColour
 						
 						if v.adminOnly == true and LocalPlayer():IsAdmin() == false then 
 							continue 
 						elseif v.adminOnly == true then
 							c = Color(255, 0, 0, 255)
 						end
 						if v.superAdminOnly == true and LocalPlayer():IsSuperAdmin() == false then 
 							continue 
 						elseif v.superAdminOnly == true then
 							c = Color(255, 0, 0, 255)
 						end
 
						draw.DrawText(k.." - "..v.description, "Impulse-ChatMedium", 10, 10 + i, c, TEXT_ALIGN_LEFT)
						i = i + 15
 					end
 				end
			end
		end
	end
	impulse.chatBox.chatLog.Think = function( self )
		self:SetSize( impulse.chatBox.frame:GetWide() - 10, impulse.chatBox.frame:GetTall() - impulse.chatBox.entry:GetTall() - 40 )
	end
	
	local text = "Say:"

	local say = vgui.Create("DLabel", impulse.chatBox.frame)
	say:SetText("")
	surface.SetFont( "Impulse-ChatSmall")
	local w, h = surface.GetTextSize( text )
	say:SetSize( w + 5, 20 )
	say:SetPos( 5, impulse.chatBox.frame:GetTall() - impulse.chatBox.entry:GetTall() - 5 )
	
	say.Paint = function( self, w, h )
		draw.DrawText( text, "Impulse-ChatSmall", 2, 1, color_white )
	end

	say.Think = function( self )
		local types = {"", "teamchat", "console"}
		local s = {}

		if impulse.chatBox.ChatType == types[2] then 
			text = "Say (TEAM):"	
		elseif impulse.chatBox.ChatType == types[3] then
			text = "Console:"
		else
			text = "Say:"
			s.pw = 45
			s.sw = impulse.chatBox.frame:GetWide() - 50
		end

		if s then
			if not s.pw then s.pw = self:GetWide() + 10 end
			if not s.sw then s.sw = impulse.chatBox.frame:GetWide() - self:GetWide() - 15 end
		end

		local w, h = surface.GetTextSize( text )
		self:SetSize( w + 5, 20 )
		self:SetPos( 5, impulse.chatBox.frame:GetTall() - impulse.chatBox.entry:GetTall() - 5 )

		impulse.chatBox.entry:SetSize( s.sw, 20 )
		impulse.chatBox.entry:SetPos( s.pw, impulse.chatBox.frame:GetTall() - impulse.chatBox.entry:GetTall() - 5 )
	end	
	
	impulse.chatBox.hideBox()
end

--// Hides the chat box but not the messages
function impulse.chatBox.hideBox()
	impulse.chatBox.frame.Paint = function() end
	impulse.chatBox.chatLog:SetScrollBarVisible(false)
	impulse.chatBox.chatLog.active = false
	
	--impulse.chatBox.chatLog:GotoTextEnd()
	
	impulse.chatBox.lastMessage = impulse.chatBox.lastMessage or CurTime() - impulse.GetSetting("chat_fadetime")
	
	-- Hide the chatbox except the log
	local children = impulse.chatBox.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == impulse.chatBox.frame.btnMaxim or pnl == impulse.chatBox.frame.btnClose or pnl == impulse.chatBox.frame.btnMinim then continue end
		
		if pnl != impulse.chatBox.chatLog then
			pnl:SetVisible( false )
		end
	end
	
	-- Give the player control again
	impulse.chatBox.frame:SetMouseInputEnabled( false )
	impulse.chatBox.frame:SetKeyboardInputEnabled( false )
	gui.EnableScreenClicker( false )
	
	-- We are done chatting
	hook.Run("FinishChat")
	
	-- Clear the text entry
	impulse.chatBox.entry:SetText( "" )
	hook.Run( "ChatTextChanged", "" )
end

--// Shows the chat box
function impulse.chatBox.showBox()
	-- Draw the chat box again
	impulse.chatBox.frame.Paint = impulse.chatBox.oldPaint

	impulse.chatBox.chatLog:SetScrollBarVisible(true)
	impulse.chatBox.chatLog.active = true
	
	impulse.chatBox.lastMessage = nil
	
	-- Show any hidden children
	local children = impulse.chatBox.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == impulse.chatBox.frame.btnMaxim or pnl == impulse.chatBox.frame.btnClose or pnl == impulse.chatBox.frame.btnMinim then continue end
		
		pnl:SetVisible( true )
	end
	
	-- MakePopup calls the input functions so we don't need to call those
	impulse.chatBox.frame:MakePopup()
	impulse.chatBox.entry:RequestFocus()

	-- Make sure other addons know we are chatting
	hook.Run("StartChat")
end

local oldAddText = chat.AddText

--// Overwrite chat.AddText to detour it into my chatbox
function chat.AddText(...)
	if not impulse.chatBox.chatLog then
		impulse.chatBox.buildBox()
	end
	
	impulse.chatBox.chatLog:AddText(...)
	chat.PlaySound()
end

--// Stops the default chat box from being opened
hook.Remove("PlayerBindPress", "impulse.chatBox_hijackbind")
hook.Add("PlayerBindPress", "impulse.chatBox_hijackbind", function(ply, bind, pressed)
	if string.sub( bind, 1, 11 ) == "messagemode" then
		if bind == "messagemode2" then 
			impulse.chatBox.ChatType = "teamchat"
		else
			impulse.chatBox.ChatType = ""
		end
		
		if IsValid( impulse.chatBox.frame ) then
			impulse.chatBox.showBox()
		else
			impulse.chatBox.buildBox()
			impulse.chatBox.showBox()
		end
		return true
	end
end)

--// Hide the default chat too in case that pops up
hook.Remove("HUDShouldDraw", "impulse.chatBox_hidedefault")
hook.Add("HUDShouldDraw", "impulse.chatBox_hidedefault", function( name )
	if name == "CHudChat" then
		return false
	end
end)

 --// Modify the Chatbox for align.
local oldGetChatBoxPos = chat.GetChatBoxPos
function chat.GetChatBoxPos()
	return impulse.chatBox.frame:GetPos()
end

function chat.GetChatBoxSize()
	return impulse.chatBox.frame:GetSize()
end

chat.Open = impulse.chatBox.showBox
function chat.Close(...) 
	if IsValid( impulse.chatBox.frame ) then 
		impulse.chatBox.hideBox(...)
	else
		impulse.chatBox.buildBox()
		impulse.chatBox.showBox()
	end
end