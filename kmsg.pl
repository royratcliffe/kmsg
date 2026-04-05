:- use_module(library(dcg/basics)).

% Reads kernel messages from /dev/kmsg and stores them in a Redis stream named "kmsg".
% Uses a repeat-fail loop to continuously read messages until the program is terminated.
main :-
    repeat,
    kmsg(Priority, Sequence, TimeStamp, Flags, Message),
    redis(default, xadd(kmsg, *,
                        priority, Priority,
                        sequence, Sequence,
                        timestamp, TimeStamp,
                        flags, Flags,
                        message, Message)),
    fail.

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
