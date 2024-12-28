local M = {}

function add_debug_cmd()
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

    " catch-all for top-level, if applied, marks up text as Error
    " NOTE: defined near the top so subsequent rules can have higher priority
    syntax match httTopLevelError '^\s*.*$'


    " Text lines
    syntax region httTextLine
	   \ start='^\s*\ze[^%]'
      \ end='$'
      \ keepend oneline contained
      \ contains=httTextLineContinuation,httLuaExpr,httComponentCall

    syntax region httLuaLine start='\v^\s*%([^@])@=' end='$' contains=@Lua keepend oneline
    " Hack, explicitly match '% end' to apply Keyword style to 'end'
    " ... otherwise, it is marked in an error code, becaus the syntax highlighter thinks
    " ... it is unmatched...
    syntax match httLuaLineEnd '\<end\>' contained containedin=httLuaLine

    "Directive lines
    syntax match httDirective '^\s*%\s*@.*' contains=httDirectiveSymbol,httDirectiveKeyword
    syntax match httDirectiveSymbol "^\s*%" contained contains=httDirectiveStart
    syntax match httDirectiveKeyword '@\w\+' contained
    syntax match httDirectiveStart '%' contained

    " Lua code blocks (between '% @code' and nearest '% @end')
    syntax region httLuaBlock start='^\s*%\s*@code\s*$' end='^\s*%\s*@end\s*$' contains=@Lua,httDirective keepend contained

    " Component lines
    " Lua code blocks (between '% @code' and nearest '% @end')
    syntax match httComponentStart '^\s*%\s*@component' contained contains=httDirective
    syntax match httComponentEnd '^\s*%\s*@end\s*$' contained contains=httDirective

    syntax cluster httComponentContents contains=httTextLine,httLuaLine,httLuaBlock,httDirective

    syntax region httComponentBlock
      \ start='^\s*%\s*@component'
      \ end='^\s*%\s*@end\s*$'
      \ contains=httComponentStart,httComponentEnd,@httComponentContents,httDirective
      \ keepend extend
      \ fold

    syntax region httComponentSkipLuaBlock
      \ start='^\s*%\s*@code\s*$'
      \ end='^\s*%\s*@end\s*$'
      \ contained
      \ containedin=httComponentBlock
      \ contains=httLuaBlock
      \ keepend extend
      \ transparent

    syntax match httTextLineContinuation '\~>' contained


    " ---- start httLuaExpr
    syntax match httLuaExprDelimiter '{{' contained
    syntax match httLuaExprDelimiter '}}' contained

    syntax region httLuaString start=+'+ skip=+\\'+ end=+'+ contained extend
    syntax region httLuaString start=+"+ skip=+\\"+ end=+"+ contained extend
    syntax region httLuaMultilineString start='\[\[' end='\]\]' contained extend
    syntax region httLuaMultilineComment start='--\[\[' end='\]\]--' contained extend

    syntax match httLuaExprEnd '}}' containedin=httLuaExpr contained

    syntax cluster httLuaExprContents
      \ contains=httLuaExprDelimiter,@Lua,httLuaString,httLuaMultilineString,httLuaMultilineComment

    syntax region httLuaExpr start='{{' end='}}' contains=@httLuaExprContents keepend extend contained

    highlight link httLuaExprDelimiter Special
    highlight link httLuaString luaString
    highlight link httLuaMultilineString luaString
    highlight link httLuaMultilineComment luaComment
    highlight link httLuaExprEnd Special
    " ----- end

    " ---- start httComponentCall
    syntax match httComponentCallStart '{{@' contained
    syntax match httComponentCallEnd '}}' contained

    syntax region httComponentCall
      \ start='{{@'
      \ end='}}'
      \ contains=httComponentCallStart,httComponentCallEnd,httComponentExpr,httComponentArgs
      \ keepend extend contained

    syntax region httComponentExpr
      \ start='\s\+\zs'
      \ end='\ze\s'
      \ contained
      \ containedin=httComponentCall
      \ contains=@httLuaExprContents
      \ nextgroup=httComponentArgs
      \ skipwhite

    syntax region httComponentArgs
      \ start='\S\+\s\+\zs'
      \ end='\ze}}'
      \ contained
      \ containedin=httComponentCall
      \ contains=@httLuaExprContents

    highlight link httComponentCallStart Special
    highlight link httComponentCallEnd Special
    highlight link httComponentExpr Function
    highlight link httComponentArgs Normal

    " ---- end

    syntax cluster httTopLevel contains=httDirective,httLuaBlock,httComponentBlock,httLuaLine

    syntax region httFile start='\%^' end='\%$' contains=@httTopLevel,httTopLevelError

  ]])

  vim.cmd([[
    highlight default link httDirective PreProc
    highlight default link httDirectiveSymbol Operator
    highlight default link httDirectiveKeyword Identifier
    "highlight default link httLuaLine Normal
    highlight default link httLuaLineStart Operator
    highlight default link httDirectiveStart Operator

    highlight link httLuaLineEnd luaFunction

    highlight link httTextLineContinuation Comment

    highlight link httTopLevelError Error

  ]])

  vim.cmd("syntax sync fromstart")

  add_debug_cmd()
end

M.setup = function()
  vim.api.nvim_create_autocmd({"BufRead", "BufNewFile", "FileType"}, {
    pattern = "*.htt",
    callback = function(args)
      vim.bo[args.buf].filetype = "htt"
      M.set_syntax()
    end,
    group = vim.api.nvim_create_augroup("HTTSetup", { clear = true })
  })
end

return M
