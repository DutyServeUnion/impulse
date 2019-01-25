netstream.Hook("impulseSceneFOV", function(ply, fov, time) -- for some reason setfov is broken on client
	if fov == 0 then fov = 70 end
	ply:SetFOV(fov, time)
end)

netstream.Hook("impulseScenePVS", function(ply, stage)
	if impulse.Config.IntroScenes[stage] then
		ply.extraPVS = impulse.Config.IntroScenes[stage].pos
	end
end)

if SERVER then return end

impulse.Scenes = impulse.Scenes or {}

function impulse.Scenes.Play(stage, sceneData, onDone)
	impulse.Scenes.pos = nil
	impulse.Scenes.ang = nil
	sceneData.speed = sceneData.speed or 1

	netstream.Start("impulseScenePVS", stage)

	hook.Add("CalcView", "impulseScene", function()
		impulse.Scenes.pos = impulse.Scenes.pos or sceneData.pos
		impulse.Scenes.ang = impulse.Scenes.ang or sceneData.ang

		local view = {}

		if sceneData.endpos and not sceneData.static then
			impulse.Scenes.pos = LerpVector(FrameTime() * sceneData.speed, impulse.Scenes.pos, sceneData.endpos)
		end

		if sceneData.endang and not sceneData.static then
			impulse.Scenes.ang = LerpAngle(FrameTime() * sceneData.speed, impulse.Scenes.ang, sceneData.endang)
		end

		if not sceneData.time and sceneData.endpos and impulse.Scenes.pos:Distance(sceneData.endpos) < 1 then 
			hook.Remove("CalcView", "impulseScene") 
			hook.Remove("HUDPaint", "impulseScene")
			impulse.hudEnabled = true
			if onDone then
				onDone()
			end
		end

		view.origin = impulse.Scenes.pos
		view.angles = impulse.Scenes.ang
		view.farz = 15000
		view.drawviewer = true
		return view
	end)

	local outputText = ""
	local textPos = 1
	local nextTime = 0

	if sceneData.text then
		hook.Add("HUDPaint", "impulseScene", function()
			if CurTime() > nextTime and textPos != string.len(sceneData.text) then
				textPos = textPos + 1
				nextTime = CurTime() + .08
				surface.PlaySound("impulse/typewriter"..tostring(math.random(1,4))..".wav")
			end

			impulse.Scenes.markup = markup.Parse("<font=Impulse-Elements27-Shadow>"..string.sub(sceneData.text, 1, textPos).."</font>", ScrW() * .7)
			impulse.Scenes.markup:Draw(ScrW()/2, ScrH() * .8, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end)
	end

	if sceneData.fovFrom then
		netstream.Start("impulseSceneFOV", sceneData.fovFrom, 0)
		netstream.Start("impulseSceneFOV", 0, sceneData.fovTime)
	end

	if sceneData.time then
		timer.Simple(sceneData.time, function()
			hook.Remove("CalcView", "impulseScene")
			hook.Remove("HUDPaint", "impulseScene")
			impulse.hudEnabled = true
			if onDone then
				onDone()
			end
		end)
	end

	impulse.hudEnabled = false
end