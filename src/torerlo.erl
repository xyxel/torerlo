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

request(Msg) ->
    gen_server:cast(?SERVER, {request, Msg}).

%add_torrent(DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent) ->
 %   gen_server:cast(?SERVER, {add_torrent, [DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent]}).

auth(UserName, UserPass) ->
    gen_server:call(?SERVER, {auth, UserName, UserPass}).

% gen_server callback
init([]) ->
    {ok, Servername, Port, Database_server, Database_user, Database_passwd} = torerlo_config:gets("src/torerlo.cfg"),
    io:format("connect to database...~n",[]),
    {ok, DB} = torerlo_pgsql:db_connect(Servername, Database_user, Database_passwd, "torerlo"),
    io:format("port is listening...~n",[]),
    io:format("Tables checking...~n",[]),
    case torerlo_pgsql:db_check_tables(DB, "torerlo", "peers", "seeds") of
        {ok, 0} -> torerlo_pgsql:db_create(DB, "torerlo", "peers", "seeds");
        {ok, 3} -> io:format("tables are exist...~n", []);
	_ -> io:format("tables are broken!~n", [])
    end,
    Pid = spawn(fun() -> process_flag(trap_exit,true), torerlo_listen:listen(DB, Servername, Database_user, Database_passwd, Port) end),
    {ok, Pid}.

handle_call({auth, UserName, UserPass}, _From, State) ->
    io:format("user auth would be here...\n",[]),
    {reply, {UserName, UserPass}, State}.

handle_cast({request, Msg}, State) ->
    io:format("receiving torren-request would be here...\n",[]),
    {noreply, Msg};

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
