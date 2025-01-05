defmodule DicomNet.Endpoint do
  @moduledoc """
  Defines a DICOM network endpoint.

  The endpoint is the boundary where all DICOM upper layer network connection
  enter the system. For every connection, a `DicomNet.Association` is instantiated.
  If the assocation is established successfully, received DICOM operations
  are forwarded to registered listeners as messages.

  See also:
    * https://dicom.nema.org/dicom/2013/output/chtml/part08/chapter_9.html
  """
  use GenServer
  require Logger

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def register_listener(endpoint \\ __MODULE__, listener) when is_pid(listener) do
    GenServer.cast(endpoint, {:register_listener, listener})
  end

  @impl true
  def init(port: port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])

    Logger.info("Accepting DICOM connections on port #{port}")

    send(self(), :check_for_connection)

    state = %{listen_socket: listen_socket, listeners: []}
    {:ok, state}
  end

  @impl true
  def handle_info(:check_for_connection, %{listen_socket: listen_socket} = state) do
    case :gen_tcp.accept(listen_socket, 100) do
      {:ok, client_socket} ->
        {:ok, assoc_pid} =
          DicomNet.Association.start(%{socket: client_socket, event_listener: self()})

        :gen_tcp.controlling_process(client_socket, assoc_pid)

      {:error, :timeout} ->
        nil
    end

    # loop
    send(self(), :check_for_connection)
    {:noreply, state}
  end

  @impl true
  def handle_info({:dicom, dicom_op}, %{listeners: listeners} = state) do
    for listener <- listeners do
      send(listener, {:dicom, dicom_op})
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:register_listener, listener}, %{listeners: listeners} = state) do
    new_state = %{state | listeners: [listener | listeners]}
    {:noreply, new_state}
  end
end
