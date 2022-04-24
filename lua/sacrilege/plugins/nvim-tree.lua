local menu = require('sacrilege.menu')

local M = { }

function M.load()
    -- TODO: Add NvimTree menu actions
    --
    --       edit, edit_in_place, edit_no_picker, cd, vsplit, split, tabnew, prev_sibling, next_sibling, parent_node,
    --       close_node, preview, first_sibling, last_sibling, toggle_git_ignored, toggle_dotfiles, refresh, create,
    --       remove, trash, rename, full_rename, cut, copy, paste, copy_name, copy_path, copy_absolute_path,
    --       prev_git_item, next_git_item, dir_up, system_open, close, toggle_help, collapse_all, search_node,
    --       toggle_file_info, run_file_command

    menu.set({
        { 'NvimTree',
            { '&Edit',      a   = '<Cmd>lua require(\'nvim-tree.actions\').on_keypress(\'edit\')<CR>',
                            tip = '' },
            { '&Rename',    a   = '<Cmd>lua require(\'nvim-tree.actions\').on_keypress(\'rename\')<CR>',
                            tip = '' },
            { '&Copy Path', a   = '<Cmd>lua require(\'nvim-tree.actions\').on_keypress(\'copy_path\')<CR>',
                            tip = '' },
        },

        { 'NvimTreePopup',
            { base = 'NvimTree.Edit' },
            { base = 'NvimTree.Rename' },
            { base = 'NvimTree.Copy Path' },
        }
    })
end

function M.attach(bufnr, filetype)
    if filetype ~= 'NvimTree' then
        return false
    end

    -- TODO: Fill NvimTree and NvimTreePopup missing keys from keymap
    --       Bind NvimTree menu to buffer (only if not already bound)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<RightMouse>', '<Cmd>lua require(\'sacrilege.ui\').popup(\'NvimTreePopup\')<CR>', { noremap = true, silent = true, nowait = true })

    return true
end

return M