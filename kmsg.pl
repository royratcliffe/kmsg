:- use_module(library(dcg/basics)).

:- setting(rediscli_host, atom, env('REDISCLI_HOST', localhost), 'Host of the Redis server').

:- initialization(redis_server, after_load).

% Connect to Redis server at Host:6379 with version 3 compatibility.
% This assumes the Redis server is running on the default port 6379.
redis_server :-
    setting(rediscli_host, Host),
    redis_server(default, Host:6379, [version(3)]).

opt_type(v, verbose, boolean).
opt_type(verbose, verbose, boolean).

opt_help(verbose, 'Enable verbose output').

% Reads kernel messages from /dev/kmsg and stores them in a Redis stream named
% "kmsg". Uses a repeat-fail loop to continuously read messages until the
% program is terminated. Perform automatic trimming of the Redis stream to keep
% only the most recent (roughly) 1000 messages, preventing unbounded growth.
main(Argv) :-
    argv_options(Argv, [], Options),
    option(verbose(Verbose), Options, false),
    repeat,
    kmsg(Priority, Sequence, TimeStamp, Flags, Message),
    redis(default, xadd(kmsg, maxlen, ~, 1000, *,
                        priority, Priority,
                        sequence, Sequence,
                        timestamp, TimeStamp,
                        flags, Flags,
                        message, Message), RedisStamp),
    (   Verbose == true
    ->  format('~w ~w ~w ~w ~w ~w~n', [RedisStamp, Priority, Sequence, TimeStamp, Flags, Message])
    ;   true
    ),
    fail.

:- initialization(main, main).

%! kmsg(-Priority, -Sequence, -TimeStamp, -Flags, -Message) is semidet.
% Reads a line from /dev/kmsg and parses it into its components. Opens the
% stream if it is not already open, then reads a line and parses it using DCG
% rules. The stream is kept open for subsequent calls to avoid the overhead of
% opening and closing it repeatedly. Its type is text, so it is read as a stream
% of characters (codes) and then parsed into its components. Encoding is UTF-8
% by default, so it can handle a wide range of characters in the log messages.
kmsg(Priority, Sequence, TimeStamp, Flags, Message) :-
    (   stream_property(_, alias(kmsg))
    ->  true
    ;   open_kmsg
    ),
    read_kmsg_to_codes(Codes),
    once(phrase(kmsg(Priority, Sequence, TimeStamp, Flags_, Message_), Codes)),
    % Convert Flags and Message from codes to strings.
    string_codes(Flags, Flags_),
    string_codes(Message, Message_).

open_kmsg :- open('/dev/kmsg', read, _, [alias(kmsg)]).

read_kmsg_to_codes(Codes) :- read_line_to_codes(kmsg, Codes).

%! kmsg(-Priority, -Sequence, -TimeStamp, -Flags, -Message)// is semidet.
% Parses a line from /dev/kmsg into its components. The format of each line is:
%
% Priority,Sequence,TimeStamp,Flags;Message
%
% Where:
% - Priority: An integer representing the log level (0-7).
% - Sequence: An integer representing the sequence number of the log message.
% - TimeStamp: An integer representing the timestamp of the log message in microseconds.
% - Flags: A string containing any flags associated with the log message (e.g., "", "C", "D").
% - Message: The actual log message string.
kmsg(Priority, Sequence, TimeStamp, Flags, Message) -->
    integer(Priority),
    ",",
    integer(Sequence),
    ",",
    integer(TimeStamp),
    ",",
    string_without(";", Flags),
    ";",
    string(Message).
