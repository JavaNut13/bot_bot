defmodule BotBot.RegexCond do
  defmacro match(matchable, do: matches) do
    de_sigged = matches |> Enum.map(fn
      {:"->", context, [[lhs], code]} ->
        lhs = de_sig matchable, lhs
        {:"->", context, [[lhs], code]}
    end)
  
    quote do
      cond do
        unquote de_sigged
      end
    end
  end

  # @ variables are considered to be regexes until I work out how to do this better
  defp de_sig(matchable, regex = {:"@", _, _}) do
    quote do
      Regex.match?(unquote(regex), unquote(matchable))
    end
  end

  defp de_sig(matchable, regex = {:sigil_r, _, _}) do
    quote do
      Regex.match?(unquote(regex), unquote(matchable))
    end
  end

  defp de_sig(matchable, {:"->", context, [[lhs], code]}) do
    de_sigged = de_sig matchable, lhs
    {:"->", context, [[de_sigged], code]}
  end

  defp de_sig(matchable, {type, context, [lhs, rhs]}) do
    lhs = de_sig matchable, lhs
    rhs = de_sig matchable, rhs
    {type, context, [lhs, rhs]}
  end

  defp de_sig(_matchable, other) do
    other
  end
end
