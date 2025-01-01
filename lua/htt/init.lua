local M = {}

local function add_debug_cmd()
  vim.api.nvim_command([[
    function! SyntaxDebug()
      for id in synstack(line("."), col("."))
        echo synIDattr(id, "name")
      endfor
    endfunction
  ]])

  vim.api.nvim_command([[nnoremap <F5> :call SyntaxDebug()<CR>]])
end

function M.set_syntax()
  vim.cmd("syntax clear")
  vim.cmd([[
  syntax include @Lua syntax/lua.vim
  
  " Hack, clear luaParenError and luaError
  syntax clear luaParenError
  syntax clear luaError
  
  syntax region httExpr matchgroup=httExprDelim start='{{' end='}}' oneline contained contains=@Lua
  syntax region httCall matchgroup=httCallDelim start='{{@' end='}}' oneline contained contains=httComponentIdent
  
  syntax match httComponentIdent '\v\s*\zs\w+' skipwhite nextgroup=@Lua
  
  syntax match httLine '.*$' oneline transparent contains=httExpr,httCall
  syntax match httLineStart '\v^.+$' oneline contains=httLine
  syntax match httLineCont '\v\~\>' contained nextgroup=httLine
  syntax match httLineStart '\v^\~\>.*$' oneline contains=httLineCont
  
  syntax match httLuaLineStart '\v^\s*[%]\s*.*$' contains=httLuaLineCtlOpen
  syntax match httLuaLineCtlOpen '\v^\s*\zs[%]' contained nextgroup=httLuaLine_e2
  syntax match httLuaLine_e2 '\v\s*' contained transparent contains=NONE nextgroup=httLuaLine
  syntax match httLuaLine '\v.*$' contained contains=@Lua,luaCondElseif keepend
  
  syntax match httLuaLineEndStart '\v^\s*[%]\s*<end>\s*.*$' contains=httLuaLineEndCtlOpen
  syntax match httLuaLineEndCtlOpen '\v^\s*\zs[%]' contained nextgroup=httLuaLineEnd_e2
  syntax match httLuaLineEnd_e2 '\v\s*' contained transparent contains=NONE nextgroup=httLuaLineEnd
  syntax match httLuaLineEnd '\v<end>' contained nextgroup=httLuaLineEnd_e4
  syntax match httLuaLineEnd_e4 '\v\s*' contained transparent contains=NONE nextgroup=httLuaLineEndLua
  syntax match httLuaLineEndLua '\v.*$' contained contains=@Lua keepend
  
  syntax match httLuaLineElseStart '\v^\s*[%]\s*<else>\s*.*$' contains=httLuaLineElseCtlOpen
  syntax match httLuaLineElseCtlOpen '\v^\s*\zs[%]' contained nextgroup=httLuaLineElse_e2
  syntax match httLuaLineElse_e2 '\v\s*' contained transparent contains=NONE nextgroup=httLuaLineElse
  syntax match httLuaLineElse '\v<else>' contained nextgroup=httLuaLineElse_e4
  syntax match httLuaLineElse_e4 '\v\s*' contained transparent contains=NONE nextgroup=httLuaLineElseLua
  syntax match httLuaLineElseLua '\v.*$' contained contains=@Lua keepend
  
  syntax match httDirectiveStart '\v^\s*[%]\s*[@]\w+\s*(\w+)?\s*$' contains=httDirectiveCtlOpen
  syntax match httDirectiveCtlOpen '\v^\s*\zs[%]' contained nextgroup=httDirective_e2
  syntax match httDirective_e2 '\v\s*' contained transparent contains=NONE nextgroup=httDirectiveKw
  syntax match httDirectiveKw '\v[@]\w+' contained nextgroup=httDirective_e4
  syntax match httDirective_e4 '\v\s*' contained transparent contains=NONE nextgroup=httDirectiveArg
  syntax match httDirectiveArg '\v(\w+)?\ze\s*$' contained
  
  syntax match httLuaBlock '\v^\s*[%]\s*[@]code\s*$\_.{-}^\s*[%]\s*[@]end\s*$' skipwhite contains=httDirectiveStart,@Lua
  
  syntax cluster httCtlOpenTag contains=httDirectiveCtlOpen,httLuaLineCtlOpen,httLuaLineElseCtlOpen
  
  highlight link httDirectiveKw Structure
  highlight link httDirectiveArg Label
  highlight link httLineCont Comment
  highlight link httExprDelim Delimiter
  highlight link httCallDelim Include
  
  highlight link httLuaLineCtlOpen Special
  highlight link httDirectiveCtlOpen httLuaLineCtlOpen
  highlight link httLuaLineElseCtlOpen httLuaLineCtlOpen
  highlight link httLuaLineEndCtlOpen httLuaLineCtlOpen
  
  highlight link httComponentIdent Label
  
  highlight link httLuaLineElse luaCond
  highlight link httLuaLineEnd luaCond
  
  syntax match luaTableKey "\(\w\+\)\s*=" contains=luaSymbolOperator contained containedin=luaTableBlock
  highlight link luaTableKey Identifier
  ]])
  add_debug_cmd()
end

M.setup = function()
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "FileType" }, {
    pattern = "*.htt",
    callback = function(args)
      vim.bo[args.buf].filetype = "htt"
      M.set_syntax()
    end,
    group = vim.api.nvim_create_augroup("HTTSetup", { clear = true })
  })
end



return M