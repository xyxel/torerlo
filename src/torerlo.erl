-module(torerlo).
-behavior(gen_server).

-include_lib("deps/epgsql/include/pgsql.hrl").

-define(SERVER, ?MODULE).

-export([start/0, stop/0]).

%-export([init/1,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-compile(export_all).

% gen_server control
start() ->
    gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).

stop() ->
    gen_server:cast(?SERVER, stop).

%add_torrent(DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent) ->
 %   gen_server:cast(?SERVER, {add_torrent, [DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent]}).

auth(UserName, UserPass) ->
    gen_server:call(?SERVER, {auth, UserName, UserPass}).

% gen_server callback
init([]) ->
    {ok, Servername, Port, Database_server, Database_user, Database_passwd} = torerlo_config:gets("src/torerlo.cfg"),
    io:format("connect to database...~n",[]),
    {ok, DB} = torerlo_pgsql:db_connect(Servername, Database_user, Database_passwd, "torerlo"),
    io:format("Table checking...~n",[]),
    case torerlo_pgsql:db_check_tables(DB, "peers") of
        {ok, 0} -> torerlo_pgsql:db_create(DB, "peers");
        {ok, 1} -> io:format("table is exist...~n", []);
	_ -> io:format("tables are broken!~n", [])
    end,
    Pid_response = spawn(fun() -> process_flag(trap_exit,true), torerlo_listen:loop() end),
    Pid_database = spawn(fun() -> process_flag(trap_exit,true), torerlo_pgsql:loop(DB, Pid_response) end),
    spawn(fun() -> process_flag(trap_exit,true), torerlo_pgsql:clean(DB, "peers") end),
    Pid_request = spawn(fun() -> process_flag(trap_exit,true), torerlo_listen:listen(Port, Pid_database) end),
    {ok, start}.

handle_call({auth, UserName, UserPass}, _From, State) ->
    io:format("user auth would be here...\n",[]),
    {reply, {UserName, UserPass}, State}.

%handle_cast({add_torrent, [DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent]}, State) ->
%    Pid ! "{add_torrent, [Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent]}",
 %   {noreply, DB};
 %   {norepy};

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    {ok, _Reason}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
