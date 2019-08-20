open Base
module Sys = Caml.Sys
module Uchar = Caml.Uchar

let debug_log debug message = if debug then Stdio.print_endline @@ Printf.sprintf "Dotenv debug: %s" message

let env_var_regex =
  Str.regexp
    "^[\\012\\r\\t\\f\\v ]*\\([a-zA-Z0-9_]+\\)[\\012\\r\\t\\f\\v ]*=[\\012\\r\\t\\f\\v ]*\\(.*\\)?[\\012\\r\\t\\f\\v \
     ]*$"

(*
  Lines function shamelessly copied from https://github.com/dbuenzli/uutf/blob/master/test/examples.ml
  and renamed to read_lines
 *)
let read_lines ?encoding src =
  let rec loop d buf acc =
    match Uutf.decode d with
    | `Uchar u ->
      ( match Uchar.to_int u with
      | 0x000A ->
        let line = Buffer.contents buf in
        Buffer.clear buf;
        loop d buf (line :: acc)
      | _ ->
        Uutf.Buffer.add_utf_8 buf u;
        loop d buf acc )
    | `End -> List.rev (Buffer.contents buf :: acc)
    | `Malformed _ ->
      Uutf.Buffer.add_utf_8 buf Uutf.u_rep;
      loop d buf acc
    | `Await -> assert false
  in
  let nln = `Readline (Uchar.of_int 0x000A) in
  loop (Uutf.decoder ~nln ?encoding src) (Buffer.create 512) []

let get_exports ?(path = ".env") ?encoding debug =
  debug_log debug @@ Printf.sprintf "Reading environment from path \"%s\"" path;
  if Sys.file_exists path then (
    let env_str = Stdio.In_channel.read_all path in
    Some (read_lines ?encoding (`String env_str)) )
  else (
    debug_log debug @@ Printf.sprintf "\"%s\" file not found." path;
    None )

let parse_var_lines debug ~f parsed export =
  match Str.string_match env_var_regex export 0 with
  | true ->
    ( try
        let transform_rules =
          [ Caml.String.trim;
            String.substr_replace_all ~pattern:"'" ~with_:"\"" (*replace single quotes for double quotes *)
          ]
        in
        let name = String.uppercase (Str.matched_group 1 export) in
        let value = List.fold transform_rules ~init:(Str.matched_group 2 export) ~f:(fun acc f -> f acc) in
        f debug parsed name value
      with _ ->
        debug_log debug @@ Printf.sprintf "Parse Error: \"%s\"" export;
        parsed )
  | false -> parsed

let create_vars_list debug parsed name value =
  debug_log debug @@ Printf.sprintf "Processing variable %s with value %s." name value;
  List.rev @@ List.Assoc.add parsed ~equal:String.equal name value

let add_to_env debug unnit name value =
  match Sys.getenv_opt name with
  | None ->
    debug_log debug @@ Printf.sprintf "Processing variable %s with value %s." name value;
    Unix.putenv name value
  | Some _ ->
    debug_log debug @@ Printf.sprintf "Environment variable %s already set. Skipping this one." name;
    unnit

let parse ?(debug = false) ?path ?encoding () =
  match get_exports ?path ?encoding debug with
  | None -> []
  | Some exports -> List.fold ~init:[] ~f:(parse_var_lines ~f:create_vars_list debug) exports

let export ?(debug = false) ?path ?encoding () =
  match get_exports ?path ?encoding debug with
  | None -> ()
  | Some exports -> List.iter ~f:(parse_var_lines ~f:add_to_env debug ()) exports
