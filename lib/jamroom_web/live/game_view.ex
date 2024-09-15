defmodule JamroomWeb.GameView do
  use Phoenix.LiveView
  # use Jamroom.Game

  @possible_drum_keys ["1", "2", "3", "4"]
  @possible_guitar_chords ["1", "2", "3", "4", "5", "6", "7"]
  @ms_between_beats 75

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div class="">
      <%= JamroomWeb.PageView.render("menu.html", assigns) %>
      <div class="game-display">
        <img src="/images/bg.png" class="game_img" />
        <%= JamroomWeb.PageView.render("drummer.html", assigns) %>
        <%= JamroomWeb.PageView.render("guitarist.html", assigns) %>
      </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # May need to unsubscribe on termination
    if connected?(socket), do: Phoenix.PubSub.subscribe(Jamroom.InternalPubSub, "game")

    socket =
      assign(socket,
        name: get_random_name(),
        guitarist: Jamroom.Band.guitarist(),
        strum_guitar: nil,
        drummer: Jamroom.Band.drummer(),
        hit_drum: nil
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, socket) do
    with member_index <-
           Jamroom.Band.members()
           |> Enum.find_index(fn x -> x == socket.assigns.name end) do
      member_index
      |> Jamroom.Band.remove_at()
    end

    Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:update_game_state})
  end

  @impl Phoenix.LiveView
  def handle_event("select-guitar", _value, socket) do
    _old_guitarist = Jamroom.Band.guitarist()

    maybe_new_guitarist = socket.assigns.name

    Jamroom.Band.add_at(0, maybe_new_guitarist)
    Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:update_game_state})
    {:noreply, assign(socket, guitarist: maybe_new_guitarist, strum_guitar: nil)}
  end

  def handle_event("guitar-keydown", params, socket) do
    %{"key" => key} = params

    if Enum.member?(@possible_guitar_chords, key) do
      Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:play_sound, :guitar, key})

      :timer.apply_after(
        100,
        Phoenix.PubSub,
        :broadcast,
        [Jamroom.InternalPubSub, "game", {:stop_sound, :guitar}]
      )
    end

    {:noreply, socket}
  end

  def handle_event("un-select-guitar", _value, socket) do
    Jamroom.Band.remove_at(0)
    Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:update_game_state})

    {:noreply, assign(socket, strum_guitar: nil)}
  end

  def handle_event("select-drum", _value, socket) do
    _old_drummer = Jamroom.Band.drummer()

    maybe_new_drummer = socket.assigns.name

    Jamroom.Band.add_at(1, maybe_new_drummer)
    Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:update_game_state})
    {:noreply, assign(socket, hit_drum: nil)}
  end

  def handle_event("drum-keydown", params, socket) do
    %{"key" => key} = params

    if Enum.member?(@possible_drum_keys, key) do
      Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:play_sound, :drum, key})

      :timer.apply_after(
        100,
        Phoenix.PubSub,
        :broadcast,
        [Jamroom.InternalPubSub, "game", {:stop_sound, :drum}]
      )
    end

    {:noreply, socket}
  end

  def handle_event("un-select-drum", _value, socket) do
    Jamroom.Band.remove_at(1)
    Phoenix.PubSub.broadcast(Jamroom.InternalPubSub, "game", {:update_game_state})

    {:noreply, assign(socket, drummer: nil, hit_drum: nil)}
  end

  @impl Phoenix.LiveView
  def handle_info({:update_game_state}, socket) do
    {:noreply, assign(socket, get_game_state(socket))}
  end

  def handle_info({:play_sound, :guitar, chord}, socket) do
    synchronize_sound()
    {:noreply, assign(socket, strum_guitar: chord)}
  end

  def handle_info({:stop_sound, :guitar}, socket) do
    {:noreply, assign(socket, strum_guitar: nil)}
  end

  def handle_info({:play_sound, :drum, chord}, socket) do
    synchronize_sound()
    {:noreply, assign(socket, hit_drum: chord)}
  end

  def handle_info({:stop_sound, :drum}, socket) do
    {:noreply, assign(socket, hit_drum: nil)}
  end

  # we want time to be kept by this function otherwise everyone will get a headache lol
  # it also helps mask latency
  def synchronize_sound() do
    time = :os.system_time(:millisecond)
    time_string = Integer.to_string(time)
    ms_string = String.slice(time_string, -3..-1)
    {ms, _} = Integer.parse(ms_string)
    remainder = rem(ms, @ms_between_beats)
    sleep_time = @ms_between_beats - remainder
    :timer.sleep(sleep_time)
  end

  defp get_random_name do
    names = [
      "cersei",
      "milo",
      "pixel",
      "pharmacy",
      "drake",
      "humanoid",
      "kilogram",
      "area",
      "turkey",
      "tanner"
    ]

    "#{Enum.random(names)}-#{:rand.uniform(200)}"
  end

  defp get_game_state(socket) do
    guitarist = Jamroom.Band.guitarist()
    drummer = Jamroom.Band.drummer()

    socket.assigns
    |> Map.take([:name, :guitarist, :strum_guitar, :drummer, :hit_drum])
    |> Map.put(:guitarist, guitarist)
    |> Map.put(:drummer, drummer)
  end
end
