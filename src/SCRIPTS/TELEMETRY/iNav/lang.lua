local modes, labels, data, FILE_PATH, env = ...
local lang

if data.lang ~= "en" then
	local tmp = FILE_PATH .. "lang_" .. data.lang
	-- Either the compiled or the source file may be present (EdgeTX compiles sources on the radio)
	local fh = io.open(tmp .. ".luac") or io.open(tmp .. ".lua")
	if fh ~= nil then
		io.close(fh)
		lang = loadScript(tmp .. ".luac", env)(modes, labels)
		collectgarbage()
	end
end

if data.voice ~= "en" then
	local fh = io.open(FILE_PATH .. data.voice .. "/on.wav")
	if fh ~= nil then
		io.close(fh)
	else
		data.voice = "en"
	end
end

return lang