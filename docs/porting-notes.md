# Porting R7RS to x-lang — what it cost

Notes kept from the 2026 port, for anyone doing the same to another lang.
Not part of the README: this is about how the port went, not how to use the
bundle.

## What porting it actually cost

**Almost nothing, and that is the finding.** R7RS is 700 lines of Scheme on top
of R5RS, and once x-r5rs was ported the whole stack loaded on the first try.
Four edits total, in two files.

**`(fn (x) …)` in generated code is the same bug as `(def lambda fn)`, one level
up.** `x/records.x` emits procedures — a constructor, a predicate, an accessor
per field — and emitted them as `fn` forms with Scheme-shaped formals. x's `fn`
takes an explicit receiver, so every one of them bound its first real parameter
to the receiver and shifted the rest off the end. The constructor built a record
out of nothing and the accessors read a slot that was not there, which
*segfaults* rather than raising. Emitting `lambda` — the operative that splices
the receiver in — makes the generated code correct by construction. 13 specs.

**`apply` supplies the receiver too.** x-r5rs's `convert` wrapper passed one by
hand:

```x
(apply %cvt (pair () (pair v (pair target extra))))
```

which shifts every argument along, so `(convert 'point %string)` answered `nil`
instead of `"point"`. It did not raise; the first symptom was
`define-record-type` failing with `Str8 append: not a string`, three layers
away. Fixed in the r5rs bundle, where it also silently affected nothing else —
which is its own small lesson about how much a wrong-but-quiet primitive can
hide.

**A char is an int underneath.** `(eq? 65 #\A)` is `#t` in x — characters and
small integers share identity — so R5RS's `eqv?` reached its `eq?` fallback and
agreed with x rather than with Scheme. The char cases have to come first *and*
char-versus-non-char has to be answered before the fallback sees it.

**An empty list converts to nil, not `""`.** `%convert-to` answers nil for a nil
value by design — absence stays absence — but `(list->string '())` is the empty
*string*, and `string`, `string-map` and `vector->string` all inherit the
difference.

## Why `guard` took an engine fix

This is the sharpest thing the port turned up, and it is worth reading even if
you never touch R7RS.

R7RS `guard` and x's `guard` are different forms with the same name, so
providing one means shadowing the other — and `guard` is a name both `lib/` and
the spec runner resolve *by name at run time*. That is
[x-lang#525](https://github.com/jonruttan/x-lang/issues/525)'s story about `do`,
where a shape-dispatcher solved it.

A dispatcher was not enough here. Shadowing `guard` **at all** interposes one
operative frame between the runner's `%seq` and the body it guards, and
`define` could not survive that: it bound by letting TCO pop the operative's
frame so the `def` landed globally, and x offered no way for an operative to
define in its caller's environment across a frame boundary. Every `define`
inside a guarded body bound nowhere, silently, and the runner's own handler
swallowed the unbound-symbol error it caused — **~100 failures with empty
output** to buy the 17 in `12-exceptions.spec.md`.

[x-lang#527](https://github.com/jonruttan/x-lang/issues/527) fixed that with one
primitive, `(base def-global)`, which takes `def`'s top-level path whatever the
frame depth. `def` itself is untouched — its save-stack rule is settled
semantics that `include`/`import` rely on.

**Then two more places turned out to be relying on the same accident**, and
neither was visible until something added a frame:

- `x/records.x` emitted `(def …)` for the constructor, predicate and every
  accessor. Loading `guard` broke all 13 record specs until those became
  `%def-global`.
- `case` (in the r5rs bundle) bound three helpers with sequential `def`s inside
  an operative, so `case-check-datums` was unbound as soon as a frame appeared.
  Rewritten with `letrec`, which binds through real parameters.

The dispatcher also needed tightening. "Every clause is a pair" does not
separate the two shapes, and misreading the runner's own handler as `cond`
clauses swallowed 55 errors silently. The clause **head** discriminates: R7RS
leads with a test (`else`, `#t`, or a call), x leads with a statement's
operator.

Removing the `let` from the first draft *looked* like the fix and moved the
numbers barely at all — which is how the real cause got found.

