-define(NETSIM_CLOCK, netsim_cirka).

-record('event', {
        time :: netsim_types:latency(),
        action :: netsim_types:action(),
        resource :: netsim_types:resource()
    }).

-record(route, {
    action :: change | del,
    nodeid :: netsim_types:nodeid(), % from
    time :: netsim_types:latency(),
    route :: [netsim_types:route()],
    resource :: netsim_types:resource()
}).

-record(stat, {
        tick :: netsim_types:latency(),
        action :: add | del | stop,
        resource :: netsim_types:resource(), % for which resource statistics
        nodeid :: netsim_types:nodeid(), % who sent this data
        tx :: bandwidth(), % bits
        rx :: bandwidth()
    }).
