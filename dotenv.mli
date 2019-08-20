(** [parse ~debug ~path ~encoding ()] reads the env file on the path with the defined encoding
    and returns an association list with pairs of var names and values. 
    For the encoding Uutf decoder encodings can be used:
    [ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 | `US_ASCII | `ISO_8859_1] . *)
val parse
  :  ?debug:bool (** defaults to [false] *) ->
  ?path:string ->
  ?encoding:[< Uutf.decoder_encoding ] ->
  unit ->
  (string, string) Base.List.Assoc.t

(** [export ~debug ~path ~encoding ()] reads the env file on the path with the defined encoding
    and adds the read variables onto the environment. They will then be available under Sys.get_env 
    For the encoding Uutf decoder encodings can be used:
    [ `UTF_16 | `UTF_16BE | `UTF_16LE | `UTF_8 | `US_ASCII | `ISO_8859_1] . *)
val export
  :  ?debug:bool (** defaults to [false] *) ->
  ?path:string ->
  ?encoding:[< Uutf.decoder_encoding ] ->
  unit ->
  unit
