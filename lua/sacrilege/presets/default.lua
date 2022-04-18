local mouse = require('sacrilege.mouse')

local M = { }

-- TODO: atom { macos = { }, linux = { }, windows = { } } : https://github.com/nwinkler/atom-keyboard-shortcuts
-- TODO: vscode
-- TODO: nano : https://www.nano-editor.org/dist/latest/cheatsheet.html
-- TODO: MenuPopup autocmd to add spelling suggestions to Popup (context)
-- TODO: Allow binding context
-- TODO: Allow popup to be a merge of contexts (flatten = false)

function M.setup(os)
    return {
        insertmode = vim.opt.insertmode,
        mousemodel = vim.opt.mousemodel,
        menubar = '',
        popup = { 'PopUp' },
        context = { 'Context' },
        toolbar = false,
        bind =  { '', ']Keyboard', ']Mouse' },
        menus = {
            { '&File',
                { '&New Tab', key = '⌃T', a   = '<Cmd>tabnew<CR>',
                                          tip = 'Creates a new tab' },
                { '&Open',    key = '⌃O', a   = '<Cmd>lua require(\'telescope.builtin\').find_files()<CR>',
                                          tip = '' },
                { '&Save',    key = '⌃S', a   = '<Cmd>update<CR>',
                                          tip = '' },
                { '&Close',   key = '⌃W', a   = '<Cmd>q<CR>',
                                          tip = '' },
                '-',
                { '&Quit',    key = '⌃Q', a   = '<Cmd>quitall<CR>',
                                          tip = '' }
            },

            { '&Edit',
                { '&Undo',          key = '⌃Z',  a   = '<C-O>u',
                                                 tip = '' },
                { '&Redo',          key = '⇧⌃Z', a   = '<C-O><C-r>',
                                                 tip = '' },
                '-',
                { '&Cut',           key = '⌃X',  a   = '<C-O>x',
                                                 tip = '' },
                { 'Cop&y',          key = '⌃C',  a   = '<C-O>y<C-O>gv',
                                                 tip = '' },
                { '&Paste',         key = '⌃V',  a   = '<C-O>P',
                                                 tip = '' },
                { '&Delete',                     a   = '<C-O>d',
                                                 tip = '' },
                '-',
                { '&Find',          key = '⌃F',  a   = '<C-\\><C-N>/',
                                                 tip = '' },
                { 'Find Pre&vious', key = 'F3',  a   = '<C-\\><C-N>gN',
                                                 tip = '' },
                { 'Find &Next',     key = '⇧F3', a   = '<C-\\><C-N>gn',
                                                 tip = '' },
                '-',
                { 'Rename...',      key = 'F2',  a   = '<Nop>',
                                                 tip = '' }
            },

            { '&Selection',
                { 'Select &All',   key = '⌃A', a   = '<C-\\><C-N>gggH<C-O>G',
                                               tip = '' },
                { '&Block Select',             a   = '<C-\\><C-N>g<C-H>',
                                               tip = '' },
            },

            { '&View',
                { 'Command &Palette',   key = '⇧⌃P', a   = '<Cmd>Telescope<CR>',
                                                     tip = '' },
                { 'Command &Prompt...',              a   = '<C-\\><C-N>:',
                                                     tip = '' },
                '-',
                -- TODO: Default to <Cmd>Lexplore<CR>
                { '&File Explorer',     key = '⌃B',  a   = '<Cmd>NvimTreeToggle<CR>',
                                                     tip = '' }
            },

            { '&Help',
                { 'Show &Manual Page', key = 'F1', a   = '<Cmd>Man<CR>',
                                                   tip = '' },
                { '&Shortcuts',                    a   = '<Cmd>WhichKey<CR>',
                                                   tip = '' },
                { 'Vim &Help',                     a   = '<Cmd>help<CR>',
                                                   tip = '' },
                { 'Vim &Reference',                a   = '<Cmd>help quickref<CR>',
                                                   tip = '' },
                { 'Vim &Tutorial',                 a   = '<Cmd>Tutor<CR>',
                                                   tip = '' },
                { '&About',                        a   = '<Cmd>help copying<CR>',
                                                   tip = '' }
            },

            { 'PopUp',
                { base = 'Edit.Rename...' },
                '-',
                { base = 'Edit.Cut' },
                { base = 'Edit.Copy' },
                { base = 'Edit.Paste' },
                '-',
                { base = 'View.Command Palette' }
            },

            { 'Gutter', hidden = true,
                { '&Gutter', key = '', a = '<Nop>', tip = '' },
            },

            -- { 'ToolBar',
            --
            -- },

            { 'Keyboard', hidden = true,
                { '&Menu',                   key = 'Esc',   ni = '<Cmd>lua require(\'sacrilege\').menu()<CR>'    },
                { '&Menu',                   key = '⎇F10',  a  = '<Cmd>lua require(\'sacrilege\').menu()<CR>'    },
                { '&Toolbar',                key = '',      a  = '<Cmd>lua require(\'sacrilege\').toolbar()<CR>' },
                { '&Popup',                  key = '⇧F10',  a  = '<Cmd>lua require(\'sacrilege\').popup()<CR>'   },
                '-',
                { '&Left Block Selection',   key = '⎇⇧←',   a  = '<C-\\><C-N>g<C-H><S-Left>'  },
                { '&Right Block Selection',  key = '⎇⇧→',   a  = '<C-\\><C-N>g<C-H><S-Right>' },
                { '&Up Block Selection',     key = '⎇⇧↑',   a  = '<C-\\><C-N>g<C-H><S-Up>'    },
                { '&Down Block Selection',   key = '⎇⇧↓',   a  = '<C-\\><C-N>g<C-H><S-Down>'  }
            },

            { 'Mouse', hidden = true,
                { '&Breakpoint',             key = 'LeftMouse',    a = '<Cmd>lua require(\'sacrilege.presets.default\').leftmouse()<CR>'  },
                { '&Popup',                  key = 'RightMouse',   a = '<Cmd>lua require(\'sacrilege.presets.default\').rightmouse()<CR>' },
                '-',
                { '&Start Block Selection',  key = '⎇LeftMouse',   nvic = '<4-LeftMouse>', o = '<C-C><4-LeftMouse>' },
                { '&Extend Block Selection', key = '⎇LeftDrag',    nvic = '<LeftDrag>' },
                { '&Keep Block Selection',   key = '⎇LeftRelease', nvic = '<Nop>'      }
            }
        }
    }
end

-- TODO: Additional menus

-- Diagnostics
-- TODO: Map other vim.diagnostic.* functions
-- { 'Diagnostics', '<Cmd>lua vim.diagnostic.open_float()<CR>' }
-- { 'Previous Error', '<Cmd>lua vim.diagnostic.goto_prev()<CR>' }
-- { 'Next Error', '<Cmd>lua vim.diagnostic.goto_next()<CR>' }

-- LSP
-- TODO: Map other vim.lsp.buf.* functions
-- { 'Go to Declaration', '<Cmd>lua vim.lsp.buf.declaration()<CR>' }
-- { 'Go to Definition', '<Cmd>lua vim.lsp.buf.definition()<CR>' }
-- { 'Show Definition', '<Cmd>lua vim.lsp.buf.hover()<CR>' }
-- { 'Go to Implementation', '<Cmd>lua vim.lsp.buf.implementation()<CR>' }
-- { 'Show signature', '<Cmd>lua vim.lsp.buf.signature_help()<CR>' }
-- { 'Add LSP workspace', '<Cmd>lua vim.lsp.buf.add_workspace_folder()<CR>' }
-- { 'Remove LSP workspace', '<Cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>' }
-- { 'List LSP workspaces', '<Cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>' }
-- { 'Go to Type Definition', '<Cmd>lua vim.lsp.buf.type_definition()<CR>' }
-- { 'Rename symbol', '<Cmd>lua vim.lsp.buf.rename()<CR>' }
-- { 'Code action', '<Cmd>lua vim.lsp.buf.code_action()<CR>' }
-- { 'Find all references', '<Cmd>lua vim.lsp.buf.references()<CR>' }
-- { 'Format file', '<Cmd>lua vim.lsp.buf.formatting()<CR>' }
-- { 'Format selection', '<Cmd>lua vim.lsp.buf.formatting()<CR>' } -- TODO: Format selection

-- Debug
-- TODO: Add support for :Termdebug/vimspector/nvim-gdb
-- { 'Debugger', '<Cmd>lua require(\'dapui\').toggle()<CR>' }
-- { 'Toggle Breakpoint', '<Cmd>lua require(\'dap\').toggle_breakpoint()<CR>' }
-- { 'Continue', '<Cmd>lua require(\'dap\').continue()<CR>' }
-- { 'Step Over', '<Cmd>lua require(\'dap\').step_over()<CR>' }
-- { 'Step Into', '<Cmd>lua require(\'dap\').step_into()<CR>' }
-- { 'Step Out', '<Cmd>lua require(\'dap\').step_out()<CR>' }
-- { 'Show variable value', '<Cmd>lua require(\'dap.ui.variables\').hover()<CR>' }
-- { 'Show variable value2', '<Cmd>lua require(\'dap.ui.variables\').visual_hover()<CR>' }
-- { 'Show value', '<Cmd>lua require(\'dap.ui.widgets\').hover()<CR>' }
-- { 'Show all scopes', '<Cmd>lua local widgets=require(\'dap.ui.widgets\');widgets.centered_float(widgets.scopes)<CR>' }
-- { 'REPL', '<Cmd>lua require(\'dap\').repl.open()<CR>' }
-- { 'REPL Run Last', '<Cmd>lua require(\'dap\').repl.run_last()<CR>' }
-- { 'Conditional Breakpoint...', '<Cmd>lua require(\'dap\').set_breakpoint(vim.fn.input(\'Breakpoint condition: \'))<CR>' }
-- { 'Tracepoint...', '<Cmd>lua require(\'dap\').set_breakpoint({ nil, nil, vim.fn.input(\'Log point message: \') })<CR>' }
-- { 'Show variable scopes', '<Cmd>lua require(\'dap.ui.variables\').scopes()<CR>' }

-- TODO: Text manipulation menu (Comment/Lowercase/Uppercase...)
-- TODO: jbyuki/instant.nvim menu

function M.leftmouse()
    local location = mouse.locate()

    if     location.tabline      then print('LeftMouse: Tab line')
    elseif location.statusline   then print('LeftMouse: Status line')
    elseif location.cmdline      then print('LeftMouse: Command line')
    elseif location.border       then print('LeftMouse: Border')
    elseif location.foldcolumn   then print('LeftMouse: Fold column')
    elseif location.signcolumn   then print('LeftMouse: Sign column')
    elseif location.numbercolumn then print('LeftMouse: Number column')
    elseif location.closedfold   then print('LeftMouse: Closed fold')
    elseif location.virtualtext  then print('LeftMouse: Virtual text')
    elseif location.eolchar      then print('LeftMouse: End of line character')
    elseif location.eol          then print('LeftMouse: End of line')
    elseif location.eof          then print('LeftMouse: End of file')
    else                              print('LeftMouse: Content')
    end

    mouse.input('<LeftMouse>')
end

function M.rightmouse()
    local location = mouse.locate()

    if     location.tabline      then print('RightMouse: Tab line')
    elseif location.statusline   then print('RightMouse: Status line')
    elseif location.cmdline      then print('RightMouse: Command line')
    elseif location.border       then print('RightMouse: Border')
    elseif location.foldcolumn   then print('RightMouse: Fold column')
    elseif location.signcolumn   then print('RightMouse: Sign column')
    elseif location.numbercolumn then print('RightMouse: Number column')
    elseif location.closedfold   then print('RightMouse: Closed fold')
    elseif location.virtualtext  then print('RightMouse: Virtual text')
    elseif location.eolchar      then print('RightMouse: End of line character')
    elseif location.eol          then print('RightMouse: End of line')
    elseif location.eof          then print('RightMouse: End of file')
    else                              print('RightMouse: Content')
    end

    mouse.input('<RightMouse>')
end

return M