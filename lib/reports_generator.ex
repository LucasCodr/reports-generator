defmodule ReportsGenerator do
  alias ReportsGenerator.Parser

  @available_foods [
    "açaí",
    "churrasco",
    "esfirra",
    "hambúrguer",
    "pastel",
    "pizza",
    "prato_feito",
    "sushi"
  ]

  @options [
    "foods",
    "users"
  ]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build_many(filenames) when not is_list(filenames),
    do: {:error, "Provide a list of strings."}

  def build_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  defp sum_reports(
         %{"foods" => foods1, "users" => users1},
         %{"foods" => foods2, "users" => users2}
       ) do
    foods = merge_sum(foods1, foods2)
    users = merge_sum(users1, users2)

    build_report(foods, users)
  end

  defp merge_sum(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  def fetch_higher_cost(report, option) when option in @options do
    {:ok, Enum.max_by(report[option], fn {_key, value} -> value end)}
  end

  def fetch_higher_cost(_report, _option), do: {:error, "Invalid option!"}

  defp sum_values([id, food, price], %{"foods" => foods, "users" => users}) do
    users = Map.put(users, id, users[id] + price)
    foods = Map.put(foods, food, foods[food] + 1)

    build_report(foods, users)
  end

  defp report_acc do
    foods = Enum.into(@available_foods, %{}, &{&1, 0})
    users = Enum.into(1..30, %{}, &{Integer.to_string(&1), 0})

    build_report(foods, users)
  end

  defp build_report(foods, users), do: %{"foods" => foods, "users" => users}
end
