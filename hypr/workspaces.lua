-- Distribui os workspaces entre os monitores detectados automaticamente:
--   1-5   -> primeiro monitor (default)
--   6-10  -> segundo monitor (se existir), se não, ficam no primeiro.
-- Funciona em qualquer máquina, qualquer quantidade de monitores.

local monitors = hl.get_monitors()
table.sort(monitors, function(a, b) return a.id < b.id end)

local primary = monitors[1]
local secondary = monitors[2]

if primary then
    for i = 1, 5 do
        hl.workspace_rule({
            workspace = tostring(i),
            monitor = primary.name,
            default = i == 1,
        })
    end
end

if secondary then
    for i = 6, 10 do
        hl.workspace_rule({
            workspace = tostring(i),
            monitor = secondary.name,
            default = i == 6,
        })
    end
end