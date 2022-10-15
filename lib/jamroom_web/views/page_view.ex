defmodule JamroomWeb.PageView do
  use JamroomWeb, :view

  def position_state(name, guitarist, drummer) do
    is_drummer? = name == drummer
    is_guitarist? = name == guitarist

    cond do
      is_drummer? -> :is_drummer
      is_guitarist? -> :is_guitarist
      guitarist == nil || drummer == nil -> :position_available
      true -> :positions_filled
    end
  end
end
