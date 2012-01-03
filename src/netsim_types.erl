-module(netsim_types).

-type latency() :: pos_integer().
-type nodeid() :: atom().
-type price() :: integer().
-type bandwidth() :: pos_integer().
-type resource() :: pos_integer().
-type metric_attribute() :: {latency, latency()} | {price, price()} |
                            {bandwidth, bandwidth()}.
-type metrics() :: [metric_attribute()].
-type link() :: {From :: nodeid(), To :: nodeid(), Metrics :: metrics()}.
-type path() :: [link()].
-type cost() :: {latency(), price()}.
-type route() :: {resource(), path(), cost()}.
-type route_table() :: [{route(), History :: route()}].
-type msg_queue() :: {link(), [{TimeLeft :: pos_integer(), Msg :: term()}]}.

-type simulation_event() :: {
    latency(),
    add_resource | del_resource,
    nodeid(),
    resource()
}.

-export_types([latency/0, nodeid/0, metric_attribute/0, metrics/0,
        resource/0, path/0, cost/0, route/0, route_table/0,
        price/0, msg_queue/0, simulation_event/0]).
