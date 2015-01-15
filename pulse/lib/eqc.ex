
defmodule EQC do

@copyright "Quviq AB, 2014"

@moduledoc """
  This module contains macros to be used with [Quviq
  QuickCheck](http://www.quviq.com). It defines Elixir versions of the Erlang
  macros found in `eqc/include/eqc.hrl`. For detailed documentation of the
  macros, please refer to the QuickCheck documentation.

  `Copyright (C) Quviq AB, 2014.`
"""

defp eqc_forall(x, g, prop) do
  quote(do: :eqc.forall(unquote(g), fn unquote(x) -> unquote(prop) end))
end

defp eqc_bind(x, g, body) do
  quote(do: :eqc_gen.bind(unquote(g), fn unquote(x) -> unquote(body) end))
end

@doc """
A property that should hold for all values generated by a generator.

Usage:

    forall pat <- gen do
      prop
    end

The variables of `pat` are bound in `prop`.

In Erlang: `?FORALL(Pat, Gen, Prop)`.
"""
defmacro forall({:<-, _, [x, g]}, do: prop) when prop != nil, do: eqc_forall(x, g, prop)
defmacro forall(bind, prop) do
  _ = {bind, prop}
  syntax_error "forall PAT <- GEN, do: PROP"
end

@doc """
Bind a generated value for use by another generator.

Usage:

    let pat <- gen1 do
      gen2
    end

The variables of `pat` are bound in `gen2`.

In Erlang: `?LET(Pat, Gen1, Gen2)`.
"""
defmacro let({:<-, _, [x, g]}, do: body) when body != nil, do: eqc_bind(x, g, body)
defmacro let(bind, gen) do
  _ = {bind, gen}
  syntax_error "let PAT <- GEN, do: GEN"
end

@doc """
Generate a value that satisfies a given predicate.

Throws an exception if no value is found after 100 attempts.
Usage:

    such_that pat <- gen, do: pred

The variables of `pat` are bound in `pred`.

In Erlang: `?SUCHTHAT(Pat, Gen, Pred)`.
"""
defmacro such_that({:<-, _, [x, g]}, do: pred) when pred != nil do
  loc = {__CALLER__.file, __CALLER__.line}
  quote do
    :eqc_gen.suchthat(unquote(g), fn unquote(x) -> unquote(pred) end, unquote(loc))
  end
end
defmacro such_that(bind, pred) do
  _ = {bind, pred}
  syntax_error "such_that PAT <- GEN, do: PRED"
end

@doc """
Generate a value that satisfies a given predicate, or `false` if no value is found.

Usage:

    such_that_maybe pat <- gen, do: pred

The variables of `pat` are bound in `pred`.

In Erlang: `?SUCHTHATMAYBE(Pat, Gen, Pred)`.
"""
defmacro such_that_maybe({:<-, _, [x, g]}, do: pred) when pred != nil do
  quote do
    :eqc_gen.suchthatmaybe(unquote(g), fn unquote(x) -> unquote(pred) end)
  end
end
defmacro such_that_maybe(bind, pred) do
  _ = {bind, pred}
  syntax_error "such_that_maybe PAT <- GEN, do: PRED"
end

@doc """
Bind the current size parameter.

Usage:

    sized n, do: prop

In `prop`, `n` is bound to the current size.

In Erlang: `?SIZED(N, Prop)`
"""
defmacro sized(n, do: prop) when prop != nil do
  quote(do: :eqc_gen.sized(fn unquote(n) -> unquote(prop) end))
end
defmacro sized(_, prop) do
  _ = prop
  syntax_error "sized N, do: PROP"
end

@doc """
Add shrinking behaviour to a generator.

Usage:

    shrink g, gs

Generates a value from `g` that can shrink to a value generated by any of the
generators in `gs`.

In Erlang: `?SHRINK(G, Gs)`.
"""
defmacro shrink(g, gs) do
  quote(do: :eqc_gen.shrinkwith(unquote(g), fn -> unquote(gs) end))
end

@doc """
Like `let/2` but adds shrinking behaviour.

Usage:

    let_shrink pat <- gen1 do
      gen2
    end

Here `gen1` must generate a list of values, each of which is added as a
possible shrinking of the result.

In Erlang: `?LETSHRINK(Pat, Gen1, Gen2)`.
"""
defmacro let_shrink({:<-, _, [es, gs]}, do: g) when g != nil do
  quote(do: :eqc_gen.letshrink(unquote(gs), fn unquote(es) -> unquote(g) end))
end
defmacro let_shrink(bind, gen) do
  _ = {bind, gen}
  syntax_error "let_shrink PAT <- GEN, do: GEN"
end

@doc """
Perform an action when a test fails.

Usage:

    when_fail(action) do
      prop
    end

Typically the action will be printing some diagnostic information.

In Erlang: `?WHENFAIL(Action, Prop)`.
"""
defmacro when_fail(action, do: prop) when prop != nil do
  quote do
    :eqc.whenfail(fn eqcResult ->
        :erlang.put :eqc_result, eqcResult
        unquote(action)
      end, EQC.lazy(do: unquote(prop)))
  end
end
defmacro when_fail(_, prop) do
  _ = prop
  syntax_error "when_fail ACTION, do: PROP"
end

@doc """
Make a generator lazy.

Usage:

    lazy do: gen

The generator is not evaluated until a value is generated from it. Crucial when
building recursive generators.

In Erlang: `?LAZY(Gen)`.
"""
defmacro lazy(do: g) when g != nil do
  quote(do: :eqc_gen.lazy(fn -> unquote(g) end))
end
defmacro lazy(gen) do
  _ = gen
  syntax_error "lazy do: GEN"
end

@doc """
Add a precondition to a property.

Usage:

    implies pre do
      prop
    end

Any test case not satisfying the precondition will be discarded.

In Erlang: `?IMPLIES(Pre, Prop)`.
"""
defmacro implies(pre, do: prop) when prop != nil do
  quote(do: :eqc.implies(unquote(pre), unquote(to_char_list(Macro.to_string(pre))), fn -> unquote(prop) end))
end
defmacro implies(pre, prop) do
  _ = {pre, prop}
  syntax_error "implies COND, do: PROP"
end

@doc """
Run a property in a separate process and trap exits.

Usage:

    trap_exit do
      prop
    end

Prevents a property from crashing if a linked process exits.

In Erlang: `?TRAPEXIT(Prop)`.
"""
defmacro trap_exit(do: prop) when prop != nil, do: quote(do: :eqc.trapexit(fn -> unquote(prop) end))
defmacro trap_exit(prop) do
  _ = prop
  syntax_error "trap_exit do: PROP"
end

@doc """
Set a time limit on a property.

Usage:

    timeout limit do
      prop
    end

Causes the property to fail if it doesn't complete within the time limit.

In Erlang: `?TIMEOUT(Limit, Prop)`.
"""
defmacro timeout(limit, do: prop) when prop != nil do
  quote(do: :eqc.timeout_property(unquote(limit), EQC.lazy(do: unquote(prop))))
end
defmacro timeout(_, prop) do
  _ = prop
  syntax_error "timeout TIME, do: PROP"
end

@doc """
Repeat a property several times.

Usage:

    always n do
      prop
    end

The property succeeds if all `n` tests of `prop` succeed.

In Erlang: `?ALWAYS(N, Prop)`.
"""
defmacro always(n, do: prop) when prop != nil do
  quote(do: :eqc.always(unquote(n), fn -> unquote(prop) end))
end
defmacro always(_, prop) do
  _ = prop
  syntax_error "always N, do: PROP"
end

@doc """
Repeat a property several times, failing only if the property fails every time.

Usage:

    sometimes n do
      prop
    end

The property succeeds if any of the `n` tests of `prop` succeed.

In Erlang: `?SOMETIMES(N, Prop)`.
"""
defmacro sometimes(n, do: prop) when prop != nil do
  quote(do: :eqc.sometimes(unquote(n), fn -> unquote(prop) end))
end
defmacro sometimes(_, prop) do
  _ = prop
  syntax_error "sometimes N, do: PROP"
end

@doc """
Setup and tear-down for a test run.

Usage:

    setup_teardown(setup) do
      prop
    after
      x -> teardown
    end

Performs `setup` before a test run (default 100 tests) and `teardown` after
the test run. The result of `setup` is bound to `x` in `teardown`, allowing
passing resources allocated in `setup` to `teardown`. The `after` argument is
optional.

In Erlang: `?SETUP(fun() -> X = Setup, fun() -> Teardown end, Prop)`.
"""
defmacro setup_teardown(setup, do: prop, after: teardown) when prop != nil do
  x = Macro.var :x, __MODULE__
  td = cond do
    !teardown -> :ok
    true      -> {:case, [], [x, [do: teardown]]}
  end
  quote do
    {:eqc_setup, fn ->
        unquote(x) = unquote(setup)
        fn -> unquote(td) end
      end,
      EQC.lazy(do: unquote(prop))}
  end
end
defmacro setup_teardown(_, opts) do
  _ = opts
  syntax_error "setup_teardown SETUP, do: PROP, after: (X -> TEARDOWN)"
end

@doc """
A property that is only executed once for each test case.

Usage:

    once_only do
      prop
    end

Repeated tests are generated but not run, and shows up as `x`s in the test
output. Useful if running tests is very expensive.

In Erlang: `?ONCEONLY(Prop)`.
"""
defmacro once_only(do: prop) when prop != nil do
  quote(do: :eqc.onceonly(fn -> unquote(prop) end))
end
defmacro once_only(prop) do
  _ = prop
  syntax_error "once_only do: PROP"
end

defp syntax_error(err), do: raise(ArgumentError, "Usage: " <> err)

end
