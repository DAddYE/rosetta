" Copyright 2009 The Go Authors. All rights reserved.
" Use of this source code is rosverned by a BSD-style
" license that can be found in the LICENSE file.
"
" ros.vim: Vim syntax file for Go.
"
" Options:
"   There are some options for customizing the highlighting; the recommended
"   settings are the default values, but you can write:
"     let OPTION_NAME = 0
"   in your ~/.vimrc file to disable particular options. You can also write:
"     let OPTION_NAME = 1
"   to enable particular options. At present, all options default to on.
"
"   - ros_highlight_array_whitespace_error
"     Highlights white space after "[]".
"   - ros_highlight_chan_whitespace_error
"     Highlights white space around the communications operator that don't follow
"     the standard style.
"   - ros_highlight_extra_types
"     Highlights commonly used library types (io.Reader, etc.).
"   - ros_highlight_space_tab_error
"     Highlights instances of tabs following spaces.
"   - ros_highlight_trailing_whitespace_error
"     Highlights trailing white space.

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

if !exists("ros_highlight_array_whitespace_error")
  let ros_highlight_array_whitespace_error = 1
endif
if !exists("ros_highlight_chan_whitespace_error")
  let ros_highlight_chan_whitespace_error = 1
endif
if !exists("ros_highlight_extra_types")
  let ros_highlight_extra_types = 1
endif
if !exists("ros_highlight_space_tab_error")
  let ros_highlight_space_tab_error = 1
endif
if !exists("ros_highlight_trailing_whitespace_error")
  let ros_highlight_trailing_whitespace_error = 1
endif

if !exists("b:ros_subtype")
  let s:lines = getline(1)."\n".getline(2)."\n".getline(3)."\n".getline(4)."\n".getline(5)."\n".getline("$")
  let b:ros_subtype = matchstr(s:lines,'target=\zs\w\+')
  if b:ros_subtype == ''
    let b:ros_subtype = matchstr(substitute(expand("%:t"),'\c\%(\.ros\)\+$','',''),'\.\zs\w\+$')
  endif
  if b:ros_subtype == 'rb'
    let b:ros_subtype = 'ruby'
  elseif b:ros_subtype == 'golang'
    let b:ros_subtype = 'go'
  elseif b:ros_subtype == ''
    if exists('b:current_syntax') && b:current_syntax != ''
      let b:ros_subtype = b:current_syntax
    endif
  endif
endif

let b:ruby_no_expensive = 1

if exists("b:ros_subtype") && b:ros_subtype != '' && b:ros_subtype != 'eco'
  exec "runtime! syntax/".b:ros_subtype.".vim"
endif

syn case match

" Keywords within functions
syn keyword     rosStatement         goto return break continue fallthrough do
syn keyword     rosConditional       if else switch select in
syn keyword     rosLabel             case default
syn keyword     rosRepeat            for

hi def link     rosStatement         Statement
hi def link     rosConditional       Conditional
hi def link     rosLabel             Label
hi def link     rosRepeat            Repeat

" Predefined types
syn keyword     rosType              bool string error
syn keyword     rosSignedInts        int int8 int16 int32 int64 rune
syn keyword     rosUnsignedInts      byte uint uint8 uint16 uint32 uint64 uintptr
syn keyword     rosFloats            float32 float64
syn keyword     rosComplexes         complex64 complex128

hi def link     rosType              Type
hi def link     rosSignedInts        Type
hi def link     rosUnsignedInts      Type
hi def link     rosFloats            Type
hi def link     rosComplexes         Type

" Treat func specially: it's a declaration at the start of a line, but a type
" elsewhere. Order matters here.
syn match       rosType              /\<func\>/
syn match       rosDeclaration       /^def\>/
hi def link     rosDeclaration       Keyword

" Predefined functions and values
syn keyword     rosBuiltins          append cap close complex copy delete imag len size
syn keyword     rosBuiltins          make new panic print println real recover push
syn keyword     rosConstants         iota true false nil

hi def link     rosBuiltins          Keyword
hi def link     rosConstants         Keyword

" Comments; their contents
syn keyword     rosTodo              contained TODO FIXME XXX BUG
syn cluster     rosCommentGroup      contains=rosTodo
syn region      rosComment           start="#" end="$" contains=@rosCommentGroup,@Spell

hi def link     rosComment           Comment
hi def link     rosTodo              Todo

" Strings and their contents
" syn cluster     rosStringGroup       contains=rosEscapeOctal,rosEscapeC,rosEscapeX,rosEscapeU,rosEscapeBigU,rosEscapeError
" syn region      rosString            start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=@rosStringGroup
" syn region rosRawString  start=+[rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=rosRawEscape,@Spell
" syn region rosRawString  start=+[rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=rosRawEscape,@Spell
syn region rosRawString  start=+[rR]"""+ end=+"""+ keepend contains=@Spell
syn region rosRawString  start=+[rR]'''+ end=+'''+ keepend contains=@Spell

hi def link     rosString            String
hi def link     rosRawString         String

syn match rosRawEscape +\\['"]+ display transparent contained


" Characters; their contents
syn cluster     rosCharacterGroup    contains=rosEscapeOctal,rosEscapeC,rosEscapeX,rosEscapeU,rosEscapeBigU
syn region      rosCharacter         start=+'+ skip=+\\\\\|\\'+ end=+'+ contains=@rosCharacterGroup
hi def link     rosCharacter         Character

" Integers
syn match       rosDecimalInt        "\<\d\+\([Ee]\d\+\)\?\>"
syn match       rosHexadecimalInt    "\<0x\x\+\>"
syn match       rosOctalInt          "\<0\o\+\>"
syn match       rosOctalError        "\<0\o*[89]\d*\>"

hi def link     rosDecimalInt        Integer
hi def link     rosHexadecimalInt    Integer
hi def link     rosOctalInt          Integer
hi def link     Integer             Number

" Floating point
syn match       rosFloat             "\<\d\+\.\d*\([Ee][-+]\d\+\)\?\>"
syn match       rosFloat             "\<\.\d\+\([Ee][-+]\d\+\)\?\>"
syn match       rosFloat             "\<\d\+[Ee][-+]\d\+\>"

hi def link     rosFloat             Float

" Imaginary literals
syn match       rosImaginary         "\<\d\+i\>"
syn match       rosImaginary         "\<\d\+\.\d*\([Ee][-+]\d\+\)\?i\>"
syn match       rosImaginary         "\<\.\d\+\([Ee][-+]\d\+\)\?i\>"
syn match       rosImaginary         "\<\d\+[Ee][-+]\d\+i\>"

hi def link     rosImaginary         Number

" Spaces after "[]"
if ros_highlight_array_whitespace_error != 0
  syn match rosSpaceError display "\(\[\]\)\@<=\s\+"
endif

" Spacing errors around the 'chan' keyword
if ros_highlight_chan_whitespace_error != 0
  " receive-only annotation on chan type
  syn match rosSpaceError display "\(<-\)\@<=\s\+\(chan\>\)\@="
  " send-only annotation on chan type
  syn match rosSpaceError display "\(\<chan\)\@<=\s\+\(<-\)\@="
  " value-ignoring receives in a few contexts
  syn match rosSpaceError display "\(\(^\|[={(,;]\)\s*<-\)\@<=\s\+"
endif


let b:current_syntax = "ros"
