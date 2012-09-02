-module(torerlo_parser).

-import(string, [tokens/2]).

%-export([parser/2]).
-compile(export_all).

parser(Request, Pid) ->
    io:format("request parsing...", []),
    [GET, AnnounceURL | _] = tokens(Request, " "),
    [Announce, URLReqPairs] = tokens(AnnounceURL, "?"),
    Mode = lists:last(tokens(Announce, "/")),
    ReqPairs = tokens(URLReqPairs, "&"),
    case Mode of
        "announce" -> 
            io:format("announce parser\n", []),
            Pairs = lists:map(fun(Pair) -> list_to_tuple(retype(string:tokens(Pair, "="))) end, ReqPairs);
        "scrape" ->
            io:format("scrape parser\n", []),
            Pairs = [{"info_hash", lists:map(fun(Pair) -> lists:last(string:tokens(Pair, "=")) end, ReqPairs)}]
    end,
    ReqDict = dict:from_list(Pairs),
    {ok, Mode, ReqDict}.

retype([Key, Value]) ->
    case Key of
        "info_hash"       -> [Key, decoded_list_to_string(http_uri:decode(Value), " ")];
        "peer_id"         -> [Key, Value];
%        "peer_port"       -> [Key, list_to_integer(Value)];
%	"peer_uploaded"   -> [Key, list_to_integer(Value)];
%	"peer_downloaded" -> [Key, list_to_integer(Value)];
%	"peer_left"       -> [Key, list_to_integer(Value)];
	_ -> [Key, Value]
    end.

decoded_list_to_string([First_symbol | Tail_decoded_value], " ") ->
    decoded_list_to_string(Tail_decoded_value, integer_to_list(First_symbol));
decoded_list_to_string([First_symbol | Tail_decoded_value], Acc) ->
    decoded_list_to_string(Tail_decoded_value, string:concat(Acc, integer_to_list(First_symbol)));
decoded_list_to_string([], Acc) ->
    Acc.

    
