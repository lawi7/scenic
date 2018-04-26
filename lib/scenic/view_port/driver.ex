#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# each platform-specific version of scenic_platform must implement
# a complient version of Scenic.ViewPort. There won't be any conflics
# as by definition, there should be only one platform adapter in the
# deps of any one build-type of a project.


defmodule Scenic.ViewPort.Driver do
  use GenServer
  require Logger
  alias Scenic.ViewPort

#  import IEx

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_opts) do
    quote do
      def init(_),                        do: {:ok, nil}

      # simple, do-nothing default handlers
      def handle_call(msg, from, state),  do: { :noreply, state }
      def handle_cast(msg, state),        do: { :noreply, state }
      def handle_info(msg, state),        do: { :noreply, state }

      def child_spec({name, config}) do
        %{
          id: name,
          start: {ViewPort.Driver, :start_link, [{__MODULE__, name, config}]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker
        }
      end

      #--------------------------------------------------------
      defoverridable [
        init:                   1,
#        handle_sync:            1,
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
        child_spec:             1
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # Driver initialization


    def child_spec({root_sup, config}) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [{root_sup, config}]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  #--------------------------------------------------------
  def start_link({_, config} = args) do
    case config.name do
      nil -> GenServer.start_link(__MODULE__, args)
      name -> GenServer.start_link(__MODULE__, args, name: name)
    end
  end


  #--------------------------------------------------------
  def init( {root_sup, config} ) do
    GenServer.cast(self(), {:after_init, root_sup, config})
    {:ok, nil}
  end

  #============================================================================
  # handle_call

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_call(msg, from, %{driver_module: mod, driver_state: d_state} = state) do
    case mod.handle_call( msg, from, d_state ) do
      { :noreply, d_state }         ->  { :noreply, Map.put(state, :driver_state, d_state) }
      { :reply, response, d_state } ->  { :reply, response, Map.put(state, :driver_state, d_state) }
    end
  end

  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  # finish init
  def handle_cast({:after_init, vp_supervisor, config}, _) do
    # find the viewport this driver belongs to
    viewport_pid = vp_supervisor
    |> Supervisor.which_children()
    |> Enum.find_value( fn
      {_, pid, :worker, [Scenic.ViewPort]} -> pid
      _ -> false
    end) 

    # {vp_pid, dyn_sup_pid} = vp_supervisor
    # |> Supervisor.which_children()
    # |> Enum.reduce( {nil, nil}, fn
    #   {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]}, {vp, _} ->
    #     {vp, pid}
    #   {_, pid, :worker, [Scenic.ViewPort]}, {_, dyn} ->
    #     {pid, dyn}
    #   _, {vp, dyn} ->
    #     {vp, dyn}
    # end)    

    # let the driver module initialize itself
    module = config.module
     {:ok, driver_state} = module.init( viewport_pid, config.opts )

    state = %{
      viewport: viewport_pid,
      driver_module:  module,
      driver_state:   driver_state
    }

    { :noreply, state }
  end

  #--------------------------------------------------------
  # set the graph
  def handle_cast({:set_graph, _} = msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )

    state = state
    |> Map.put( :driver_state, d_state )
    |> Map.put( :last_msg, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # update the graph
  def handle_cast({:update_graph, {_, deltas}} = msg, %{driver_module: mod, driver_state: d_state} = state) do
    # don't call handle_update_graph if the list is empty
    d_state = case deltas do
      []      -> d_state
      _  ->
        { :noreply, d_state } = mod.handle_cast( msg, d_state )
        d_state
    end
    
    state = state
    |> Map.put( :driver_state, d_state )
    |> Map.put( :last_msg, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
#  def handle_cast({:driver_cast, msg}, %{driver_module: mod, driver_state: d_state} = state) do
#    { :noreply, d_state } = mod.handle_cast( msg, d_state )
#    { :noreply, Map.put(state, :driver_state, d_state) }
#  end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_cast(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end

  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # there may be more than one driver sending update messages to the
  # scene. Go no faster than the fastest one
#  def handle_info(@sync_message,
#  %{last_msg: last_msg, driver_module: mod, driver_state: d_state, sync_interval: sync_interval} = state) do
#    cur_time = :os.system_time(:millisecond)
#    case (cur_time - last_msg) > sync_interval do
#      true  ->
##        ViewPort.send_to_scene( :graph_update )
#        { :noreply, d_state } = mod.handle_sync( d_state )
#        { :noreply, Map.put(state, :driver_state, d_state) }
#      false ->
#        { :noreply, state }
#    end
#  end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_info(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_info( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end



end


























