-module(netsim_stats).

-include("include/netsim.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0, send_stat/1, define_event/1]).

%% gen_server callbacks
-export([init/1, handle_cast/2, handle_call/3, code_change/3,
        handle_info/2, terminate/2]).

-record(state, {
    event :: #stat{},
    log  = [] :: list(),
    nodes = []:: [netsim_types:nodeid()] % list of nodes for waiting events from
    %% nodes
}).

%% =============================================================================

%% @doc Start stats process.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc Sends stats event.
-spec send_stat(#stat{}) -> ok.
send_stat(Event) ->
    gen_server:call(?MODULE, {event, Event}).

%% @doc Defines when to log time (i.e. what events should be received from all
%% nodes):
define_event(#stat{}=Event) ->
    gen_server:call(?MODULE, {define, Event}).

state() ->
    gen_server:call(?MODULE, state).

%% =============================================================================

init([]) ->
    {ok, #state{}}.

handle_call(state, _, State) ->
    {reply, State, State};

%% @doc Define final event and start logging.
handle_call({define, #stat{}=Event}, _From, State) ->
    lager:info("netsim_stats: define event"),

    State1 = State#state{ 
        nodes = netsim_sup:list_nodes(),
        event = Event
    },

    {reply, ok, State1};

%% @doc Stop event.
handle_call({event, #stat{action=stop, tick=Tick}=Ev}, _, State) -> 
    lager:info("~p: converged.~n", [Tick]),

    {reply, ok, State#state{log=[Ev|State#state.log]}};

%% @doc Receive last missing and matching event.
handle_call(
    {event, #stat{nodeid=NodeId, action=Action, resource=Res, tick=Tick}=Ev}, _,
    #state{nodes=[NodeId], event=#stat{action=Action, resource=Res}}=State) ->
    lager:info("~p: last event: ~p", [Tick, Ev]),

    {reply, ok, State#state{nodes=[], log=[Ev|State#state.log]}};

%% @doc Receive matching event.
handle_call({event, #stat{nodeid=NodeId, action=Action, resource=Res}}, _,
        #state{nodes=Nodes, event=#stat{action=Action, resource=Res}}=State) ->
    {reply, ok, State#state{nodes = lists:delete(NodeId, Nodes)}};

handle_call({event, _Ev}, _, State) ->
    lager:info("~p: received event", [_Ev#stat.tick]),
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

terminate(normal, _State) ->
    ok.

code_change(_, _, State) ->
    {ok, State}.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

workflow_test() ->
    % Setup:
    meck:new(netsim_sup, [no_link]),
    meck:expect(netsim_sup, list_nodes, 0, [a, b]), 

    {ok, _} = start_link(),
    define_event(#stat{action=del, resource={a,1}}),
    ?assertMatch(
        #state{
            nodes = [a, b],
            event = #stat{action=del, resource={a,1}}
        },
        state()
    ),

    ok = send_stat(#stat{action=del, resource={x,2}}),
    ok = send_stat(#stat{action=del, resource={a,1}, nodeid=b}),
    ok = send_stat(#stat{action=del, resource={a,1}, nodeid=a, tick=69}),

    ?assertMatch(
        [#stat{action=del, resource={a, 1}, nodeid=a, tick=69}],
        (state())#state.log
    ),

    ok = send_stat(#stat{action=stop, tick=71}),
    ?assertMatch(
        [_, _],
        (state())#state.log
    ),

    % Cleanup:
    meck:unload(netsim_sup).

-endif.
