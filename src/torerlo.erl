-module(torerlo).
-behavior(gen_server).

-include_lib("deps/epgsql/include/pgsql.hrl").

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
    io:format("Reading configuration file...~n", []),
    {ok, Settings} = file:consult("src/torerlo.cfg"),
    {value, {_, Servername}} = lists:keysearch(server, 1, Settings),
    io:format("Server: ~p~n", [Servername]),
    {value, {_, DBName}} = lists:keysearch(database, 1, Settings),
    io:format("Database: ~p~n", [DBName]),
    {value, {_, DBUser}} = lists:keysearch(dbuser, 1, Settings),
    io:format("DB User: ~p~n", [DBUser]),
    {value, {_, DBPass}} = lists:keysearch(dbpass, 1, Settings),
    io:format("connect to database...~n",[]),
    torerlo_pgsql:db_connect("localhost", "postgres", "postgres", "torerlo"),
    io:format("port is listening...~n",[]),
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
