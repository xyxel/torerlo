-module(torerlo_parser).

-import(string, [tokens/2]).

-export([parser/2]).

parser(Request, Pid) ->
    [URL, URLReqPairs] = tokens(Request, "?"),
    ReqPairs = tokens(URLReqPairs, "&"),
    Pairs = lists:map(fun(Pair) -> list_to_tuple(retype(string:tokens(Pair, "="))) end, ReqPairs),
    ReqDict = dict:from_list(Pairs),
    {ok, ReqDict}.

retype([Key, Value]) ->
    case Key of
        "peer_port" -> [Key, list_to_integer(Value)];
	"peer_uploaded" -> [Key, list_to_integer(Value)];
	"peer_downloaded" -> [Key, list_to_integer(Value)];
	"peer_left" -> [Key, list_to_integer(Value)];
	_ -> [Key, Value]
    end.
      
