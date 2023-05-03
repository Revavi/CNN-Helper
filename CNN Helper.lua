script_name('CNN HELPER')
script_author('Revavi')
script_version('1.0.0')
script_version_number(1)

require "lib.moonloader"
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local imgui = require 'mimgui'
local fa = require 'fAwesome6'
local ffi = require 'ffi'
local vkeys = require 'vkeys'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local lfunc, fcmd = {}, {}

local wDir = getWorkingDirectory()

local mVec2, mVec4, mn = imgui.ImVec2, imgui.ImVec4, imgui.new
local zeroClr = mVec4(0,0,0,0)

local json = {
    save = function(data, path)
        if doesFileExist(path) then os.remove(path) end
        if type(data) ~= 'table' then return end
        local f = io.open(path, 'a+')
        f:write(encodeJson(data))
        f:close()
    end,
    load = function(path)
        if doesFileExist(path) then
			local f = io.open(path, 'a+')
			local data = decodeJson(f:read('*a'))
			f:close()
			return data
		else
			return {}
        end
    end
}

local mainSt, captchaSt, editAnswerSt = mn.bool(false), mn.bool(false), mn.bool(false)

local author, textAD, dialogActive = '', '', false
local answers = {}

local search, sID, newText, newReact = mn.char[1024](''), 0, mn.char[256](''), mn.int(0)
local reactions = {u8'Реакция: Отклонить', u8'Реакция: Отправить'}
local mnReactions = mn['const char*'][#reactions](reactions)

local dirs = {
	cfg = 'config',
	dev = 'config/Revavi',
	main = 'config/Revavi/CNN'
}
for _, path in pairs(dirs) do if not doesDirectoryExist(wDir..'/'..path) then createDirectory(wDir..'/'..path) end end

answers = json.load(wDir..'//'..dirs.main..'//Answers.json')

local function msg(arg) if arg ~= nil then return sampAddChatMessage('[CNN Helper] {FFFFFF}'..tostring(arg), 0xff6600) end end

local settsPath = 'Revavi/CNN/Settings.ini'
local setts = inicfg.load({
	main = {
		turn = false,
		x = 600,
		y = 400
	}
}, settsPath)

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	repeat wait(0) until isSampAvailable()
	
	sampRegisterChatCommand('cnn', function() mainSt[0] = not mainSt[0]; captchaSt[0] = false; editAnswerSt[0] = false end)
	sampRegisterChatCommand('cnn_answer', function() setts.main.turn = not setts.main.turn; msg('Авто-ответчик '..(setts.main.turn and '{00ff00}Включен' or '{ff0000}Выключен')) end)
	
	msg('Скрипт запущен | открыть меню: /cnn | автор: '..thisScript().authors[1])
	msg('Включить авто-ответчик: /cnn_answer')
	
	while true do
		wait(0)
	end
end

local mainWin = imgui.OnFrame(function() return mainSt[0] and not isGamePaused() end,
function(self)
	local sw, sh = getScreenResolution()
	imgui.SetNextWindowPos(mVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, mVec2(0.5, 0.5))
	imgui.SetNextWindowSize(mVec2(setts.main.x, setts.main.y), 1)
	self.HideCursor = not mainSt[0]
	
    imgui.Begin('##MainWindow', _, imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		setts.main.x, setts.main.y = imgui.GetWindowSize().x, imgui.GetWindowSize().y
	
		imgui.PushFont(f18)
			imgui.CenterText('CNN HELPER v'..thisScript().version)
		imgui.PopFont()
		imgui.CenterText('by '..thisScript().authors[1], 1)
		imgui.Separator()
		
		imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(u8'Авто-ответчик на объявления: '..u8(setts.main.turn and 'Включен' or 'Выключен')).x / 2 )
		imgui.TextColoredRGB('Авто-ответчик на объявления: '..(setts.main.turn and '{00ff00}Включен' or '{ff0000}Выключен'))
		
		imgui.PushItemWidth(imgui.GetWindowWidth() - 16)
		imgui.InputTextWithHint('##Search', fa('MAGNIFYING_GLASS')..u8'  Поиск по отредактированному тексту', search, ffi.sizeof(search))
		imgui.BeginChild('Answers', imgui.ImVec2(imgui.GetWindowWidth() - 16, imgui.GetWindowHeight() - 132 --[[104]]), true)
			imgui.Columns(3, 'Answers')
			imgui.SetColumnWidth(-1, 200); imgui.CenterTextColumn(u8'Автор'); imgui.NextColumn()
			imgui.SetColumnWidth(-1, imgui.GetWindowWidth() - 290); imgui.CenterTextColumn(u8'Отредактированный текст'); imgui.NextColumn()
			imgui.SetColumnWidth(-1, 90); imgui.CenterTextColumn(u8'Реакция'); imgui.NextColumn()
			for i, v in ipairs(answers) do
				if #ffi.string(search) == 0 or rusLower(v.edited):find(rusLower(u8:decode(ffi.string(search))), nil, true) then
					imgui.Separator()
					if imgui.Selectable(v.author, i == sID, imgui.SelectableFlags.SpanAllColumns) then sID = i end; imgui.NextColumn()
					imgui.Text(u8(v.edited)); imgui.NextColumn()
					imgui.CenterTextColumn(v.btn == 1 and u8'Отправить' or u8'Отклонить', v.btn == 1 and mVec4(0,1,0,1) or mVec4(1,0,0,1)); imgui.NextColumn()
				end
			end
			imgui.Columns(1)
			imgui.Separator()
		imgui.EndChild()
		
		if imgui.ButtonClickable(sID ~= 0, fa('PEN_TO_SQUARE'), mVec2(30, 26)) then
			newText = mn.char[256](u8(answers[sID].edited))
			newReact[0] = answers[sID].btn
			mainSt[0] = false
			editAnswerSt[0] = true
		end
		imgui.SameLine()
		if imgui.ButtonClickable(sID ~= 0, fa('TRASH'), mVec2(30, 26)) then
			table.remove(answers, sID)
			sID = 0
			json.save(answers, wDir..'//'..dirs.main..'//Answers.json')
		end
		
		imgui.SameLine(imgui.GetWindowWidth() - 128)
		if imgui.ButtonClickable(#answers ~= 0, fa('trash_can_list')..u8' Удалить всё', mVec2(120, 26)) then
			mainSt[0] = false
			captchaSt[0] = true
		end
		
		imgui.SetCursorPos(mVec2(imgui.GetWindowWidth()-34, 4))
		imgui.PushStyleColor(imgui.Col.Button, zeroClr)
		imgui.PushStyleColor(imgui.Col.ButtonHovered, zeroClr)
		imgui.PushStyleColor(imgui.Col.ButtonActive, zeroClr)
		if imgui.Button(fa('XMARK'), mVec2(30, 30)) then mainSt[0] = false end
		imgui.PopStyleColor(3)
    imgui.End()
end)

local captcha = imgui.OnFrame(function() return captchaSt[0] and not isGamePaused() end,
function(self)
	local sw, sh = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(460, 140), 1)
	self.HideCursor = not captchaSt[0]

	imgui.Begin('##captcha', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		imgui.PushFont(f25)
			imgui.CenterText(u8'Вы точно хотите удалить все ответы?')
		imgui.PopFont()
		local cPos = imgui.GetCursorPos()
		imgui.SetCursorPos(imgui.ImVec2(60, cPos.y+10))
		imgui.PushFont(f25)
			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 0.8))
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.0, 1.0, 0.0, 0.7))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.0, 1.0, 0.0, 0.5))
				if imgui.Button(u8'ДА', imgui.ImVec2(130, 70)) then
					sID = 0
					answers = {}
					json.save(answers, wDir..'//'..dirs.main..'//Answers.json')
					captchaSt[0] = false
					mainSt[0] = true
				end
				imgui.SetCursorPos(imgui.ImVec2(270, cPos.y+10))
			imgui.PopStyleColor(3)
			imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 0.8))
			imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 0.0, 0.0, 0.7))
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.0, 0.0, 0.0, 0.5))
				if imgui.Button(u8'НЕТ', imgui.ImVec2(130, 70)) then
					captchaSt[0] = false
					mainSt[0] = true
				end
			imgui.PopStyleColor(3)
		imgui.PopFont()
	imgui.End()
end)

local editAnswer = imgui.OnFrame(function() return editAnswerSt[0] and not isGamePaused() end, -- редактирование/создание заметки
function(self)
	local sw, sh = getScreenResolution()
	imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(600, 170), 1)
	self.HideCursor = not editAnswerSt[0]
	
	imgui.Begin('##answerEdit', _, imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse)
		imgui.PushFont(f18)
			imgui.CenterText(u8'Редактирование ответа')
		imgui.PopFont()
		imgui.Separator()
		imgui.TextColoredRGB('Автор: {ffffff}'..answers[sID].author)
		imgui.TextColoredRGB('Текст объявления: {ffffff}'..answers[sID].text)
		imgui.Text(u8'Отредактированный текст: ')
		imgui.PushItemWidth(imgui.GetWindowWidth()-16)
		imgui.InputText('##editAnswerValue', newText, ffi.sizeof(newText))
		imgui.PopItemWidth()
		imgui.PushItemWidth(150)
		imgui.Combo('##reaction', newReact, mnReactions, #reactions)
		imgui.PopItemWidth()
		imgui.SetCursorPosX( imgui.GetWindowWidth() / 2 - 100 / 2 )
		if imgui.ButtonClickable(#ffi.string(newText) ~= 0, u8'Сохранить', mVec2(100, 26)) then
			answers[sID].edited=u8:decode(ffi.string(newText))
			answers[sID].btn=newReact[0]
			json.save(answers, wDir..'//'..dirs.main..'//Answers.json')
		
			editAnswerSt[0] = false
			mainSt[0] = true
			newText = mn.char[256]('')
		end
		
		imgui.SetCursorPos(mVec2(imgui.GetWindowWidth()-34, 1))
		imgui.PushStyleColor(imgui.Col.Button, zeroClr)
		imgui.PushStyleColor(imgui.Col.ButtonHovered, zeroClr)
		imgui.PushStyleColor(imgui.Col.ButtonActive, zeroClr)
		if imgui.Button(fa('XMARK'), mVec2(30, 30)) then editAnswerSt[0] = false; mainSt[0] = true end
		imgui.PopStyleColor(3)
	imgui.End()
end)

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = mn.ImWchar[3](fa.min_range, fa.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(fa.get_font_data_base85('solid'), 14, config, iconRanges)
	f18 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 18, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	f25 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '//trebucbd.ttf', 25, _, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
end)

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	text = text:gsub('{......}', '')
	if dialogActive then
		dialogActive, author, textAD = false, '', ''
	else 
		if dialogId == 557 then
			dialogActive = true
			
			author = text:match('Объявление от (.+), спустя')
			textAD = text:match('Сообщение:	(.+)\nОтредактируйте')
			if setts.main.turn then
				for _, v in ipairs(answers) do 
					if author == v.author and textAD == v.text then
						lua_thread.create(function()
							wait(100)
							sampSendDialogResponse(dialogId, v.btn, v.list, v.edited)
						end)
					end
				end
			end
		end
	end
end

function sampev.onSendDialogResponse(id, button, list, input)
	if id == 557 and dialogActive then
		for i, v in ipairs(answers) do 
			if author == v.author and textAD == v.text then
				dialogActive, author, textAD = false, '', ''
				return {id, button, list, input}
			end
		end
		table.insert(answers, {author=author, text=textAD, edited=input, btn=button, list=list})
		json.save(answers, wDir..'//'..dirs.main..'//Answers.json')
		
		dialogActive, author, textAD = false, '', ''
	end
end

function sampev.onServerMessage(color, text)
	text = text:gsub('%{......%}', '')
	if not text:find('(.+)_(.+)%[(%d+)%]') then
		if text:find('Это объявление уже редактирует (.+)') or text:find('Произошла ошибка, попробуйте ещё раз') then
			dialogActive, author, textAD = false, '', ''
		end
	end
end

function rusLower(text)
	text = tostring(text)
	local characters = { {up='А', low='а'}, {up='Б', low='б'}, {up='В', low='в'}, {up='Г', low='г'}, {up='Д', low='д'}, {up='Е', low='е'}, {up='Ё', low='ё'}, {up='Ж', low='ж'}, {up='З', low='з'}, {up='И', low='и'}, {up='Й', low='й'}, {up='К', low='к'}, {up='Л', low='л'}, {up='М', low='м'}, {up='Н', low='н'}, {up='О', low='о'}, {up='П', low='п'}, {up='Р', low='р'}, {up='С', low='с'}, {up='Т', low='т'}, {up='У', low='у'}, {up='Ф', low='ф'}, {up='Х', low='х'}, {up='Ц', low='ц'}, {up='Ч', low='ч'}, {up='Ш', low='ш'}, {up='Щ', low='щ'}, {up='Ъ', low='ъ'}, {up='Ы', low='ы'}, {up='Ь', low='ь'}, {up='Э', low='э'}, {up='Ю', low='ю'}, {up='Я', low='я'} }
	for _, v in pairs(characters) do text = text:gsub(v.up, v.low) end
	return text
end

function imgui.CenterText(text, arg)
	local arg = arg or 0
	imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(text).x / 2 )
	if arg == 0 then imgui.Text(text) elseif arg == 1 then imgui.TextDisabled(text) end
end
function imgui.CenterTextColumn(text, color)
	local color = color or nil
	imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2); if not color then imgui.Text(text)
	else imgui.TextColored(color, text) end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function onWindowMessage(msg, arg, argg)
    if msg == 0x100 or msg == 0x101 then
        if (arg == vkeys.VK_ESCAPE and (mainSt[0] or (captchaSt[0] or editAnswerSt[0]))) and not isPauseMenuActive() then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
				if mainSt[0] then mainSt[0] = false end
				if editAnswerSt[0] then mainSt[0] = true; editAnswerSt[0] = false end
				if captchaSt[0] then mainSt[0] = true; captchaSt[0] = false end
            end
        end
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		inicfg.save(setts, settsPath)
	end
end

function imgui.ButtonClickable(clickable, ...)
	if clickable then
		return imgui.Button(...)
	else
		local r, g, b, a = 0, 0.2, 0.5, 0.5 -- imgui.ImColor(imgui.GetStyle().Colors[imgui.Col.Button]):GetFloat4()
		imgui.PushStyleColor(imgui.Col.Button, mVec4(r, g, b, a/2) )
		imgui.PushStyleColor(imgui.Col.ButtonHovered, mVec4(r, g, b, a/2))
		imgui.PushStyleColor(imgui.Col.ButtonActive, mVec4(r, g, b, a/2))
		imgui.PushStyleColor(imgui.Col.Text, imgui.GetStyle().Colors[imgui.Col.TextDisabled])
		imgui.Button(...)
		imgui.PopStyleColor(4)
	end
end