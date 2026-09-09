-- Detecta monitores conectados automaticamente e aplica uma regra
-- genérica e portável: resolução preferida, posição automática e
-- escala automática (baseada em PPI). Funciona em qualquer máquina:
-- laptop, desktop, monitor único ou múltiplos monitores.

local monitors = hl.get_monitors()

for _, m in ipairs(monitors) do
    hl.monitor({
        output = m.name,
        mode = "preferred",
        position = "auto",
        scale = "auto",
    })
end

-- Regra "pega-tudo": qualquer monitor conectado depois do início da
-- sessão também recebe os mesmos padrões.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})