-module(torerlo).
-behavior(gen_server).

-define(SERVER, ?MODULE).

-export([start/0,stop/0]).

%-export([init/1,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-compile(export_all).

% gen_server control
start() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

stop() ->
    gen_server:cast(?MODULE, stop).

install(DatabaseName) ->
    gen_server:cast(?SERVER, {install, DatabaseName}).

request(Msg) ->
    gen_server:cast(?SERVER, {request, Msg}).

create(NewMsg) ->
    gen_server:cast(?SERVER, {create, NewMsg}).

auth(UserName, UserPass) ->
    gen_server:call(?SERVER, {auth, UserName, UserPass}).

% gen_server callback
init([]) ->
    io:format("connect to database would be here...\n",[]),
    Pid = spawn(fun() -> process_flag(trap_exit,true), torerlo_listen:listen() end),
    {ok, start}.

handle_call({auth, UserName, UserPass}, _From, State) ->
    io:format("user auth would be here...\n",[]),
    {reply, {UserName, UserPass}, State}.

handle_cast({install, DatabaseName}, State) ->
    io:format("create new database would be here...\n",[]),
    {noreply, DatabaseName};

handle_cast({request, Msg}, State) ->
    io:format("receiving torren-request would be here...\n",[]),
    {noreply, Msg};

handle_cast({create, NewMsg}, State) ->
    io:format("creating new torrent would be here...\n",[]),
    {noreply, NewMsg};

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    {ok, _Reason}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
