# Rosetta

Rosetta is a grammar written with a LALR parse generator: [yacc/bison](http://en.wikipedia.org/wiki/Yacc).
Rosetta is a *source* to *source* and will be *source* to bytecode compiler.

Currently it targets: `Ruby, GoLang` and `C, Javascript` are on the roadmap.

It could target: whatever you want :smile:. Just make a pull request.

## But, wait ... why?

Before showing `some code` I'd like to spend few words on why.

I believe in a future where programming languages will be just `ast` and the **IDE** will render my
favorite syntax/grammar.

I'd like to use **one syntax/grammar to rule them all**. Aka, I'd like to write javascript, ruby,
golang and maybe erlang using 1 notation, without dealing with brackets, blocks, `else` or `elsif`
or `else if` etc...

More importantly I'd like to feel an artisan writing and crafting my code, and my syntax.

- **Why YACC?**: A final decision has not been made, I like `peg` parser in particular
  [kpeg](https://github.com/evanphx/kpeg) although they slightly differ in each implementation. I'd
  like something easy to read and **highly portable**.
- **Why Ruby**?: As for the latter a final decision has not been made, I chose Ruby because I'd like
  it for **rapid prototyping**. Once the grammar will be featured complete, I'll compile it
  (self-hosting) in _Rosetta_ using as a target `go` or even `c` (_portability reasons and stack
  less features_).  However, this decision is subject to change once we define the **macro** system
  and the _maybe_ **metaprogramming** capabilities, so regarding this aspect a good candidate could be
  [mruby](https://github.com/mruby/mruby) or [Lua](http://www.lua.org).

## Anti-Patterns

- This syntax **will not** change any **idioms** of the target language, i.e, it will not provide
  OO idioms on top of languages that do not support it natively.
- Rosetta will not change the entry barrier, you should still know your target language, although I
  aim to write some docs to jump-start and switch from a lang to another and get ready to `code` in
  no time.

## Implementation details

As mentioned before, this is a [yacc](http://en.wikipedia.org/wiki/Yacc) grammar,
that was inspired (in order) by `golang, python, ruby`.

- **LR**: I think `go` is the best grammar out there, it's perfectly clear and the fact that is
  totally `left` to `right`, makes it less error prone, that is a _feature_ of _Rosetta_ as well.
- **Indentation**: over brackets `{}`, as in python I think the code just looks more elegant and
  pleasant.
- **Expressive**: as mentioned earlier I'd like to craft code and be expressive like in Ruby.
- **Format**: once we define a `standard` format (tabs, soft spaces etc..) a tool like `gofmt` will
  be bundled.
- **Errors**: there has been a big focus to provide errors details, the source code is tracked `1:1`
  from source to `output`. So given a `line/column` in the generated code, you'll be able to
  `programmaticaly` find the corrispettive in your source, this means that your **editor** could be
  set for autocompletion and showing errors.
- **Macros**: although they are not here yet, the big aim is to `write your syntax`, as common in
  `Lispy` languages, you write your **own programming language**.

## Code

The code should be indented with `2` tabs. _OPEN DISCUSSION_

A tool for formatting the code will be bundled.

### Comments

Comments are defined by `#`

```python
# Hello comment
a := "foo" # another
```

### Blocks

Code blocks are defined by `INDENT statements OUTDENT` or for oneliners by `: simple_stmt`

### Keywords, Literals and Operator

They follow exactly the [golang](http://golang.org/ref/spec#Keywords) implementation.

Keywords however are `target` dependent, for example on ruby we have `module` and `class`.
In ruby we don't have obviously `go`.

In *Rosetta* two more keywords have been added: `def` and `do`.

### Function literals

For uniformity reasons, methods or functions are defined by the `def` keyword. `func` keyword is always
available as `type` and the `do` notation will be available for the declaration of anonymous
functions or short functions declaration.

```go
def main()
    doSome()
```
in go:
```go
func main() {
    doSome()
}
```

For targets that support `static typing`:

```go
def foo(a, b int, c []string)
    doSome()
```
in go:
```go
func foo(a, b int, c []string) {
    doSome()
}
```

Return types supported with the `->` (arrow) notation.

```go
def foo(a, b int, c []string) -> bool
    doSome()
```
in go:
```go
func foo(a, b int, c []string) (bool) {
    doSome()
}
```

The receiver is transparent with the help of the `self` variable.

```go
type T string

def T.count() -> int
    return len(self)
```
in go:
```go
type T string

func (self T) count() (int) {
    return len(self)
}
```

_OPEN DISCUSSION_

An alternative, could be using a `with` keyword like in python:

```go
with (p Person)
    def hello()
        p.say("Hello")
```

This form is nice when you have to deal with many functions of the same receiver
but is a bit to much verbose for a single one.

## Function as type

```go
type op struct
    name string
    fn   func(int, int) -> int
```
in go:
```go
type op struct {
    name	string
    fn	func(int, int) (int)
}
```

## Anonymous functions (do notation)

```go
x := do (a, b int) -> int
    return a + b

x(1, 2)
```
in go:
```go
x := func(a, b int) (int) {
    return a + b
}
x(1, 2)
```

```go
go!(1, 2) do (a, b int) -> int
    return a + b
```
to go:
```go
go func(a, b int) (int) {
    return a + b
}(1, 2)
```

`go!` is open for _discussion_, I believe is a good pseudo-call but at the same time,
I'm not sure will fit with the **LR** rule.

## Heredocs

Like in python:

```go
lego := """
  Darkness, in the basement ...
  no parents...
"""
```
to go:
```go
lego := "Darkness, in the basement ...\nno parents..."
```

## Herergex

As in coffee-script:

```coffee
some := ///
  (?:[a-b] # comments supported
    |[1-2] # some digits
    |\s\n?
  )
///
```
in go:
```go
some := `(?:[a-b]|[1-2]|\s\n?)`
```

## Interpolation

The interpolation is in `ruby` style. It's ready through the lexer, although
I'm still finalizing the code on the target. _DISCUSSION NEEDED_

## For Statement

The `for` expression has a context aware keyword `in`.

```go
for key, value in oldMap
    newMap[key] = value
```
in go:
```go
for key, value := range oldMap {
    newMap[key] = value
}
```

## If Statement

```go
if a > b
  doSome()
else if a == b
  doAnother()
else: inline()
```
in go:
```go
if a > b {
	doSome()
} else if a == b {
	doAnother()
} else {
	inline()
}
```

## Switch/Select

```go
switch
  case x < y: f1()
  case x < z: f2()
  case x == 4
    f3() # on a full block as well
  default: f4()
```
in go:
```go
switch {
case x < y: f1()
case x < z: f2()
case x == 4: f3()
}
```

## Usage

Right now, there is no gem, as said, the target language is subject to change
until the final draft is out.

If you'd want to play and contribute:

```
$ git clone https://github.com/daddye/rosetta.git
$ bundle install
$ bin/ros -t go
```

## Editor support

- VIM
- Please contribute!!!

## Contributing

1. Fork it ( http://github.com/DAddYE/rosetta/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright (c) 2014 DAddYE (Davide D'Agostino)

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
