-- Build player/character/prone.aseprite from the exported sprite sheet.
-- 4 frames x 66x66, 12 fps, tagged "prone".
local srcPath = "D:/Godot project/Defender/player/character/prone.png"
local dstPath = "D:/Godot project/Defender/player/character/prone.aseprite"
local FW, FH, N = 66, 66, 4

local src = app.open(srcPath)
local sheet = src.cels[1].image

local dst = Sprite(FW, FH, ColorMode.RGB)
dst.layers[1].name = "sprite"

for i = 0, N - 1 do
  local frame = (i == 0) and dst.frames[1] or dst:newEmptyFrame()
  local cel = dst:newCel(dst.layers[1], frame)
  cel.image:drawImage(sheet, Point(-FW * i, 0))
  frame.duration = 1.0 / 10.0
end

dst:saveAs(dstPath)
local f = io.open("D:/Godot project/Defender/.pxwork/ase_log.txt", "w")
f:write("frames=" .. tostring(#dst.frames) .. " size=" .. dst.width .. "x" .. dst.height .. "\n")
for i, fr in ipairs(dst.frames) do
  f:write(string.format("frame %d duration %.4f\n", i, fr.duration))
end
f:close()
app.alert("done")
