local M = { }

for id, command in pairs(require("sacrilege.commands.native")) do
    M[id] = command
end

for id, command in pairs(require("sacrilege.commands.ide")) do
    M[id] = command
end

return M
