-- @description Marker Functions
-- @author Taras Umanskiy
-- @version 1.0
-- @metapackage
-- @provides [nomain] .
-- @link http://vk.com/tarasmetal
-- @donation https://paypal.me/Tarasmetal
-- @about
--   # Marker Functions
-- @changelog
--  + Code optimizations
local r = reaper

function msg(value)
  if console then
    r.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

-- таблица с кодами цветов
col_arr = {
    blue = {0,0,255},
    red = {255,0,0},
    green = {0,255,0},
    cyan = {0,255,255},
    magenta = {255,0,255},
    yellow = {255,255,0},
    orange = {255,125,0},
    purple = {125,0,225},
    lightblue = {13,165,175},
    lightgreen = {125,255,155},
    pink = {225,0,255},
    brown = {125,95,25},
    gray = {125,125,125},
    white =  {255,255,255},
    black =  {0,0,0},
}

function convertColor(color)
    if color then
        if type(color) == "table" or type(color) == "string" then
            return reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
            -- color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
            -- return color
        else
            return reaper.ColorToNative(0,0,0)|0x0000000
    end
    end
end

function round(num)
  return num ~= 0 and math.floor(num+0.5) or math.ceil(num-0.5)
end

-- function songTimeAll()

-- local TIME_FORMAT = 1       -- number of timestamp format from the above list
-- local POS_POINTER = 1       -- 1 - Edit cursor, any other number - Mouse cursor

-- local err1 = (not TIME_FORMAT or type(TIME_FORMAT) ~= 'number' or TIME_FORMAT < 1 or TIME_FORMAT > 9) and '       Incorrect timestamp format.\n\nMust be a number between 1 and 9.'
-- local err2 = not POS_POINTER or type(POS_POINTER) ~= 'number' and 'Incorrect position pointer format.\n\n\tMust be a number.'
-- local err = err1 or err2

--     if err then r.MB(err,'USER SETTINGS error',0) r.defer(function() end) return end

-- local t = {
-- '%H:%M:%S', -- 1
-- '%d.%m.%y - %H:%M:%S', -- 2
-- '%d.%m.%Y - %I:%M:%S', -- 3
-- '%d.%m.%y - %I:%M:%S', -- 4
-- '%m.%d.%Y - %H:%M:%S', -- 5
-- '%m.%d.%y - %H:%M:%S', -- 6
-- '%m.%d.%Y - %I:%M:%S', -- 7
-- '%m.%d.%y - %I:%M:%S', -- 8
-- '%x - %X'          -- 9
-- }
-- os.setlocale('', 'time')

-- local daytime = tonumber(os.date('%H')) < 12 and ' AM' or ' PM' -- for 3,4,7,8 using 12 hour cycle
-- local daytime = (TIME_FORMAT == 3 or TIME_FORMAT == 4 or TIME_FORMAT == 7 or TIME_FORMAT == 8) and daytime or ''
-- local timestamp = os.date(t[TIME_FORMAT])..daytime
--     return timestamp
-- end

function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    if HEX_COLOR == nil then
        HEX_COLOR = '#FFFFFF'
    end
    local hex = HEX_COLOR:sub(2)
    return '0x' .. hex .. 'FF'
end


function mySort(a,b)
    if  a[1] < b [1] then
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------

function RgbaToArgb(rgba)
  return (rgba >> 8 & 0x00FFFFFF) | (rgba << 24 & 0xFF000000)
end

function ArgbToRgba(argb)
  return (argb << 8) | (argb >> 24 & 0xFF)
end

-- function round(n)
--   return math.floor(n + .5)
-- end

function clamp(v, mn, mx)
  if v < mn then return mn end
  if v > mx then return mx end
  return v
end

function Link(url)
  if not r.CF_ShellExecute then
    r.ImGui_Text(ctx, url)
    return
  end

  local color = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_CheckMark())
  r.ImGui_TextColored(ctx, color, url)
  if r.ImGui_IsItemClicked(ctx) then
    r.CF_ShellExecute(url)
  elseif r.ImGui_IsItemHovered(ctx) then
    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_Hand())
  end
end

function trs_HSV(h, s, v, a)
  local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

------------------------------------------------------------------------------------------------------------------

--твоя функция которую я на скорую руку начал рефакторить и разбил на несколько, см еще фунции ниже
-- предполагаемая задача этой функции - вернуть колво маркеров с таким же названием
function getLastId(name)
    local last_id0 = -1
    for idx =1, ({reaper.CountProjectMarkers( 0 )})[2] do
        local _, _, _, _, m_name = reaper.EnumProjectMarkers( idx-1 )
        local last_id = m_name:lower():match(name:lower()..'(%s%d+)')
        if last_id and tonumber(last_id) then
            last_id0 = math.max(last_id0, tonumber( last_id))
        end
    end
    return last_id0
end

-- предполагаемая задача этой - вернуть новый номер
function generateId(name)
    local last_id = getLastId(name)
    if not last_id or last_id == -1 then
        return 1
    end
    last_id = last_id + 1
    return last_id
end

function btn(label, color)
  reaper.ImGui_PushStyleColor(reaper.ImGui_Col_Button(), color)
  local clicked, selected = reaper.ImGui_Button(label)
  reaper.ImGui_PopStyleColor(1)
  return clicked, selected
end

-- сама основная функция вставляющая маркер
function insertMarker(name, color)

    reaper.Undo_BeginBlock()
    if color == nil or color == '' then
        color = reaper.ColorToNative(0,0,0)|0x0000000
    else
        color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
    end

    local _, num_markers, _ = reaper.CountProjectMarkers(0)
    local cursor_pos = reaper.GetCursorPosition()

    reaper.AddProjectMarker2(0, 0, cursor_pos, 0, name..' '..generateId(name), num_markers+1, color)
    reaper.Undo_EndBlock("Insert marker • " ..name, -1)
end

-- -- сама основная функция вставляющая маркер
-- function insertMarker(name, color)
--     reaper.Undo_BeginBlock()

--     if color == nil or color == '' then
--         color = reaper.ColorToNative(0,0,0)|0x0000000
--     else
--         color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
--     end

--     local _, num_markers, _ = reaper.CountProjectMarkers(0)
--     local cursor_pos = reaper.GetCursorPosition()

--     reaper.AddProjectMarker2(0, 0, cursor_pos, 0, name..' '..generateId(name), num_markers+1, color)
--     reaper.Undo_EndBlock("Insert marker • " ..name, -1)
-- end

function clrMarkers(n)

  -- local m_name = tostring(n)
  local m_name = n

  local markerCount = reaper.CountProjectMarkers(0)
  local markersToDelete = {}

  for i = 0, markerCount - 1 do
    local _, isrgn, pos, rgnend, name, id = reaper.EnumProjectMarkers(i)

    if name:find(m_name) then
      table.insert(markersToDelete, i)
    end
  end

  for i = #markersToDelete, 1, -1 do
    reaper.DeleteProjectMarkerByIndex(0, markersToDelete[i])
  end
end

function insertMarkerNoID(name, color)
    reaper.Undo_BeginBlock()

    if color == nil or color == '' then
        color = reaper.ColorToNative(0,0,0)|0x0000000
    else
        color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
    end

    local _, num_markers, _ = reaper.CountProjectMarkers(0)
    local cursor_pos = reaper.GetCursorPosition()

    reaper.AddProjectMarker2(0, 0, cursor_pos, 0, name, num_markers, color)
    reaper.Undo_EndBlock("Insert NoID • " ..name, -1)
end

function insertMarkerStart(name,color)
clrMarkers(name)
reaper.Undo_BeginBlock()
local pos = reaper.GetCursorPosition()

if color == nil or color == '' then
  color = reaper.ColorToNative(0,0,0)|0x0000000
else
  color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
end

reaper.AddProjectMarker2(0,0,pos,0, name, 0, color)
reaper.Undo_EndBlock('Set Marker • ' .. name, -1)
reaper.UpdateArrange()
end

function insertMarkerEnd(name,color)
clrMarkers(name)
reaper.Undo_BeginBlock()
local pos = reaper.GetCursorPosition()

if color == nil or color == '' then
  color = reaper.ColorToNative(0,0,0)|0x0000000
else
  color = reaper.ColorToNative(table.unpack(col_arr[color]))|0x1000000
end

reaper.AddProjectMarker2(0,0,pos,0, name, 99, color)
reaper.Undo_EndBlock('Set Marker • ' .. name, -1)
reaper.UpdateArrange()
end

function setStartEndMarkers()

  local nameLeft = '=START'
  local nameRight = '=END'

  local markerCount = reaper.CountProjectMarkers(0)
  local markersToDelete = {}

  for i = 0, markerCount - 1 do
    local _, isrgn, pos, rgnend, name, id = reaper.EnumProjectMarkers(i)

    if name:find(nameLeft) then
      -- msg(name .. " - " .. id)
      table.insert(markersToDelete, i)
    end
    if name:find(nameRight) then
      -- msg(name .. " - " .. id)
      table.insert(markersToDelete, i)
    end
  end
  -- msg(" All Markers: " .. markerCount)

  for i = #markersToDelete, 1, -1 do
    reaper.DeleteProjectMarkerByIndex(0, markersToDelete[i])
    -- msg(markersToDelete[i])
  end
    -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------
    local timeSelStart,timeSelEnd = reaper.GetSet_LoopTimeRange(0,0,0,0,0); -- В Аранже
    if timeSelStart==timeSelEnd then no_undo() return end;
    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);
    local color = reaper.ColorToNative(255,0,255)|0x1000000
    reaper.AddProjectMarker2(0,0,timeSelStart,0, nameLeft, 0, color)
    reaper.AddProjectMarker2(0,0,timeSelEnd,0, nameRight, 99, color)
    reaper.PreventUIRefresh(-1);
    reaper.Undo_EndBlock('trs_Insert • START & END markers by time selection',-1);
    reaper.UpdateArrange();
end

------------------------------------------------------------------------------------------------------------------
function btnFuncCol(name, funcName, helpText, col, i)
           r.ImGui_PushID(ctx, col)
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, ''..name..'') then
              click_count, text = 0, funcName
              if funcName ~= '' then
                _G[funcName]() -- Вызываем функцию по имени переменной idCmd
              end
              click_count = click_count + 1
           end
            r.ImGui_PopStyleColor(ctx, 3)
            r.ImGui_PopID(ctx)

          if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_BeginTooltip(ctx)
           r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
               if helpText ~= '' then
           r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), helpText)
               end
           r.ImGui_PopTextWrapPos(ctx)
           r.ImGui_EndTooltip(ctx)
            end
           		return
end

function btnCmdCol(name, idCmd, helpText, col, i)
           r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, ''..name..'') then
              click_count, text = 0, idCmd
              if idCmd ~= '' then
                r.Main_OnCommand(r.NamedCommandLookup('' .. idCmd ..''), 0)
              end
              click_count = click_count + 1
           end
            r.ImGui_PopStyleColor(ctx, 3)
            r.ImGui_PopID(ctx)

          if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_BeginTooltip(ctx)
			     r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
               if helpText ~= '' then
			     r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), helpText)
               end
			     r.ImGui_PopTextWrapPos(ctx)
			     r.ImGui_EndTooltip(ctx)
            end

           return
end

function btnSCRCol(name, idCmd, helpText, col, i)
		   r.ImGui_PushID(ctx, col)
		   r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        trs_HSV(col / 7.0, 0.6, 0.6, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), trs_HSV(col / 7.0, 0.7, 0.7, 1.0))
           r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  trs_HSV(col / 7.0, 0.8, 0.8, 1.0))
           if r.ImGui_Button(ctx, ''..name..'') then
              click_count, text = 0, idCmd
              if idCmd ~= '' then
                -- r.Main_OnCommand(r.NamedCommandLookup('' .. idCmd ..''), 0)
                local r_path = reaper.GetResourcePath()
                dofile(string.format("%s\\Scripts\\Taras Scripts\\" .. idCmd .. "", r_path))
              end
              click_count = click_count + 1
           end
            r.ImGui_PopStyleColor(ctx, 3)
            r.ImGui_PopID(ctx)

          if r.ImGui_IsItemHovered(ctx) then
          r.ImGui_BeginTooltip(ctx)
           r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
               if helpText ~= '' then
           r.ImGui_TextColored(ctx, hex2rgb('#FFFFFF'), helpText)
           r.ImGui_TextColored(ctx, hex2rgb('#C7C7C7'), idCmd)
               end
           r.ImGui_PopTextWrapPos(ctx)
           r.ImGui_EndTooltip(ctx)
            end

           return
end

function setMarker666()
  reaper.Undo_BeginBlock()
local pos = reaper.GetCursorPosition()
m_index = 666
for i=1,m_index do
    reaper.DeleteProjectMarker(0, m_index, 0)
end

if color == nil or color == '' then
    color = reaper.ColorToNative(0,0,0)|0x1000000
else
    color = reaper.ColorToNative(table.unpack(color))|0x1000000
end
reaper.AddProjectMarker2(0,0,pos,0, 'REC', m_index, color)
reaper.Undo_EndBlock('Set Marker • ' .. 'REC', -1)
reaper.UpdateArrange()
end

function goToMarker666()
local marker_num = reaper.CountProjectMarkers(0)

for i=0, marker_num-1 do
    local _, _, pos, _, name, _ = reaper.EnumProjectMarkers(i)
    -- if name == "=START" or "=END" then
    if name == "REC" then
        reaper.SetEditCurPos(pos, true, false)
    end
end

if reaper.GetPlayState() == 1 then -- Если воспроизведение включено
    reaper.OnPlayButton() -- Нажмите PLAY, чтобы переместить курсор воспроизведения на курсор редактирования
end

reaper.UpdateArrange()

function NoUndoPoint() end
reaper.defer(NoUndoPoint)
end

function resetProjStartTime()
local sws_exist = reaper.APIExists("SNM_SetDoubleConfigVar")
if sws_exist then
  reaper.SNM_SetDoubleConfigVar("projtimeoffs", 0)
  reaper.UpdateTimeline()
else
  reaper.ShowConsoleMsg("This script requires the SWS extension for REAPER. Please install it and try again.")
end
end

function resetProjBackTime()
-- function Main()

  reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

  if reaper.GetPlayState() == 0 or reaper.GetPlayState == 2 then

    offset = reaper.GetProjectTimeOffset( 0, false )

    reaper.SetEditCurPos( -offset, 1, 0 )
  end

  reaper.Undo_EndBlock("Move edit cursor to time 0 or to project start", 0) -- End of the undo block. Leave it at the bottom of your main function.

-- end

-- Main() -- Execute your main function
reaper.UpdateArrange() -- Update the arrangement (often needed)
end

function setTimecodeZero()
-- USER CONFIG AREA --
local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- local r = reaper
local p_text = 'trs'..'_'
local d_text = SCRIPT_NAME
local d = d_text

if d_text ~= '' then
  d_text = string.format('• ' .. p_text .. d_text .. ' •')
else
  d_text = string.format('• ' .. p_text .. 'T@RvZ Test Script' .. ' •')
end

console = false -- true/false: display debug messages in the console
-- msg("OFF ♦ "..(sec).." • "..(cmd).." • "..(mode).." • "..(resolution).." • "..(val).." ♦ ")

-- Display a message in the console for debugging
msg(''..d_text..'')

-- END OF USER CONFIG AREA --
r.Undo_BeginBlock() -- для того, чтобы можно было отменить действие
r.PreventUIRefresh(-1);
--=====================
local MODE = ({
  ['time'    ] =  0,
  ['seconds' ] =  3,
  ['frames'  ] =  5,
  ['set to 0'] = -1,
})[SCRIPT_NAME:match('%(([^%)]+)%)') or 'time']

assert(MODE, "Internal error: unknown timecode format")
assert(reaper.SNM_GetDoubleConfigVar, "SWS is required to use this script")

local curpos = reaper.GetCursorPosition()
local timecode = 0

if MODE >= 0 then
  timecode = reaper.format_timestr_pos(curpos, '', MODE)
  -- local ok, csv = reaper.GetUserInputs(SCRIPT_NAME, 1, "Timecode,extrawidth=50", timecode)
  local ok, csv = reaper.GetUserInputs(SCRIPT_NAME, 0, "Timecode,extrawidth=50", timecode)

  -- if not ok then
  if ok then
    reaper.defer(function() end)
    return
  end

  timecode = reaper.parse_timestr_len(csv, 0, MODE)
end

reaper.SNM_SetDoubleConfigVar('projtimeoffs', timecode - curpos)
reaper.UpdateTimeline()
--=====================
r.PreventUIRefresh(0);
r.Undo_EndBlock(d, -1) -- для того, чтобы можно было отменить действие
end
------------------------------------------------------------------------------------------------------------------

function MarkerReNameIndex()
  local marker_count = r.CountProjectMarkers(0)
  local marker_names = {}

  for i = 0, marker_count - 1 do
    local _, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(i)
    if not isrgn then
      local new_name = name:gsub("%s+%d+", "")

      if marker_names[new_name] then
        marker_names[new_name] = marker_names[new_name] + 1
        new_name = new_name  .. " " ..  marker_names[new_name]
      else
        marker_names[new_name] = 0
      end
        -- marker_names[new_name]
      if new_name ~= name then
        r.SetProjectMarkerByIndex(0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, 0)
          -- msg(name .. " - " .. new_name)
      end
    end
  end
  r.UpdateArrange()
end

function MarkerDelIndex()
  local numMarkers = r.CountProjectMarkers(0)
  for i = 0, numMarkers - 1 do
    local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = r.EnumProjectMarkers3(0, i)
    local firstWord = name:match("([^%s]+)")
    if not isrgn then
      r.DeleteProjectMarkerByIndex(0, markrgnindexnumber)
      r.AddProjectMarker2(0, false, pos, 0, firstWord, -1, color)
    end
  end
  r.UpdateArrange()
end


-- function MarkerDelIndex()
--   local numMarkers = r.CountProjectMarkers(0)
--   for i = 0, numMarkers - 1 do
--     local _, _, pos, _, name, _ = r.EnumProjectMarkers(i)
--     local firstWord = name:match("([^%s]+)")
--     r.DeleteProjectMarkerByIndex(0, i)
--     r.AddProjectMarker2(0, false, pos, 0, firstWord, i, 1)
--   end
--   r.UpdateArrange()
-- end
