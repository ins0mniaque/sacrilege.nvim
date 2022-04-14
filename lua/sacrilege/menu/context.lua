local M = { }

-- NOTE: Needs to remember previous context
-- NOTE: Needs config to know if it should bind keys (defaults to true if bind contains '')
function M.context()

end

function M.setup()
    -- NOTE: BufType unnecessary because Terminal has its own mode
    -- :autocmd BufNewFile,BufRead,FileType * lua require().context()
end

return M