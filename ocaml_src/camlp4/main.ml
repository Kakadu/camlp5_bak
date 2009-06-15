(* camlp4r q_MLast.cmo *)
(* This file has been generated by program: do not edit! *)

open Printf;;

let loc_fmt =
  match Sys.os_type with
    "MacOS" ->
      format_of_string "File \"%s\"; line %d; characters %d to %d\n### "
  | _ -> format_of_string "File \"%s\", line %d, characters %d-%d:\n"
;;

let print_location loc =
  if !(Pcaml.input_file) <> "-" then
    let (fname, line, bp, ep) = Stdpp.line_of_loc !(Pcaml.input_file) loc in
    eprintf loc_fmt fname line bp ep
  else
    let bp = Stdpp.first_pos loc in
    let ep = Stdpp.last_pos loc in eprintf "At location %d-%d\n" bp ep
;;

let print_warning loc s =
  print_location loc; eprintf "Warning: %s\n" s; flush stderr
;;

let report_error =
  function
    Odyl_main.Error (fname, msg) ->
      Format.print_string "Error while loading \"";
      Format.print_string fname;
      Format.print_string "\": ";
      Format.print_string msg
  | exc -> Pcaml.report_error exc
;;

let report_error_and_exit exc =
  Format.set_formatter_out_channel stderr;
  Format.open_vbox 0;
  let exc =
    match exc with
      Stdpp.Exc_located (loc, exc) -> print_location loc; exc
    | _ -> exc
  in
  report_error exc; Format.close_box (); Format.print_newline (); exit 2
;;

Pcaml.add_directive "load"
  (function
     Some (MLast.ExStr (_, s)) -> Odyl_main.loadfile s
   | Some _ | None -> raise Not_found);;

Pcaml.add_directive "directory"
  (function
     Some (MLast.ExStr (_, s)) -> Odyl_main.directory s
   | Some _ | None -> raise Not_found);;

let rec parse_file pa getdir useast =
  let name = !(Pcaml.input_file) in
  Pcaml.warning := print_warning;
  let ic = if name = "-" then stdin else open_in_bin name in
  let cs = Stream.of_channel ic in
  let clear () = if name = "-" then () else close_in ic in
  let phr =
    try
      let rec loop () =
        let (pl, stopped_at_directive) = pa cs in
        if stopped_at_directive then
          let lexing_info = !(!(Token.line_nb)), !(!(Token.bol_pos)) in
          let pl =
            let rpl = List.rev pl in
            match getdir rpl with
              Some x ->
                begin match x with
                  loc, "use", Some (MLast.ExStr (_, s)) ->
                    List.rev_append rpl
                      [useast loc s (use_file pa getdir useast s), loc]
                | loc, x, eo ->
                    begin try let f = Pcaml.find_directive x in f eo with
                      Not_found ->
                        Stdpp.raise_with_loc loc
                          (Stream.Error "bad directive")
                    end;
                    pl
                end
            | None -> pl
          in
          Token.restore_lexing_info := Some lexing_info; pl @ loop ()
        else pl
      in
      loop ()
    with x -> clear (); raise x
  in
  clear (); phr
and use_file pa getdir useast s =
  let v_input_file = !(Pcaml.input_file) in
  Pcaml.input_file := s;
  try
    let r = parse_file pa getdir useast in Pcaml.input_file := v_input_file; r
  with e -> report_error_and_exit e
;;

let process pa pr getdir useast = pr (parse_file pa getdir useast);;

let gind =
  function
    (MLast.SgDir (loc, n, dp), _) :: _ -> Some (loc, n, dp)
  | _ -> None
;;

let gimd =
  function
    (MLast.StDir (loc, n, dp), _) :: _ -> Some (loc, n, dp)
  | _ -> None
;;

let usesig loc fname ast = MLast.SgUse (loc, fname, ast);;
let usestr loc fname ast = MLast.StUse (loc, fname, ast);;

let process_intf () =
  process !(Pcaml.parse_interf) !(Pcaml.print_interf) gind usesig
;;
let process_impl () =
  process !(Pcaml.parse_implem) !(Pcaml.print_implem) gimd usestr
;;

type file_kind = Intf | Impl;;
let file_kind = ref Intf;;
let file_kind_of_name name =
  if Filename.check_suffix name ".mli" then Intf
  else if Filename.check_suffix name ".ml" then Impl
  else raise (Arg.Bad ("don't know what to do with " ^ name))
;;

let print_version () =
  eprintf "Camlp4s version %s (ocaml %s)\n" Pcaml.version
    Pconfig.ocaml_version;
  flush stderr;
  exit 0
;;

let initial_spec_list =
  ["-intf", Arg.String (fun x -> file_kind := Intf; Pcaml.input_file := x),
   "<file>  Parse <file> as an interface, whatever its extension.";
   "-impl", Arg.String (fun x -> file_kind := Impl; Pcaml.input_file := x),
   "<file>  Parse <file> as an implementation, whatever its extension.";
   "-unsafe", Arg.Set Ast2pt.fast,
   "Generate unsafe accesses to array and strings.";
   "-verbose", Arg.Set Grammar.error_verbose,
   "More verbose in parsing errors.";
   "-loc", Arg.String (fun x -> Stdpp.loc_name := x),
   "<name>   Name of the location variable (default: " ^ !(Stdpp.loc_name) ^
   ")";
   "-QD", Arg.String (fun x -> Pcaml.quotation_dump_file := Some x),
   "<file> Dump quotation expander result in case of syntax error.";
   "-o", Arg.String (fun x -> Pcaml.output_file := Some x),
   "<file> Output on <file> instead of standard output.";
   "-v", Arg.Unit print_version, "Print Camlp4s version and exit."]
;;

let anon_fun x = Pcaml.input_file := x; file_kind := file_kind_of_name x;;

let remaining_args =
  let rec loop l i =
    if i == Array.length Sys.argv then l else loop (Sys.argv.(i) :: l) (i + 1)
  in
  List.rev (loop [] (!(Arg.current) + 1))
;;

let go () =
  let ext_spec_list = Pcaml.arg_spec_list () in
  let arg_spec_list = initial_spec_list @ ext_spec_list in
  begin try
    match Argl.parse arg_spec_list anon_fun remaining_args with
      [] -> ()
    | "-help" :: sl -> Argl.usage initial_spec_list ext_spec_list; exit 0
    | s :: sl ->
        eprintf "%s: unknown or misused option\n" s;
        eprintf "Use option -help for usage\n";
        exit 2
  with Arg.Bad s ->
    eprintf "Error: %s\n" s;
    eprintf "Use option -help for usage\n";
    flush stderr;
    exit 2
  end;
  try
    if !(Pcaml.input_file) <> "" then
      match !file_kind with
        Intf -> process_intf ()
      | Impl -> process_impl ()
  with exc -> report_error_and_exit exc
;;

Odyl_main.name := "camlp4";;
Odyl_main.go := go;;
