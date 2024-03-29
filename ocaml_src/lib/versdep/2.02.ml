(* camlp5r pa_macro.cmo *)
(* versdep.ml,v *)
(* Copyright (c) INRIA 2007-2016 *)

open Parsetree;;
open Longident;;
open Asttypes;;

type ('a, 'b) choice =
    Left of 'a
  | Right of 'b
;;

let sys_ocaml_version = "2.02";;

let ocaml_location (fname, lnum, bolp, lnuml, bolpl, bp, ep) =
  {Location.loc_start = bp; Location.loc_end = ep}
;;

(* *)

let mkloc loc txt = txt;;
let mknoloc txt = txt;;

let ocaml_id_or_li_of_string_list loc sl =
  match List.rev sl with
    [s] -> Some s
  | _ -> None
;;

let list_map_check f l =
  let rec loop rev_l =
    function
      x :: l ->
        begin match f x with
          Some s -> loop (s :: rev_l) l
        | None -> None
        end
    | [] -> Some (List.rev rev_l)
  in
  loop [] l
;;

(* *)

(* *)

let ocaml_value_description vn t p = {pval_type = t; pval_prim = p};;

let ocaml_class_type_field loc ctfd = ctfd;;

let ocaml_class_field loc cfd = cfd;;

let ocaml_mktyp loc x = {ptyp_desc = x; ptyp_loc = loc};;
let ocaml_mkpat loc x = {ppat_desc = x; ppat_loc = loc};;
let ocaml_mkexp loc x = {pexp_desc = x; pexp_loc = loc};;
let ocaml_mkmty loc x = {pmty_desc = x; pmty_loc = loc};;
let ocaml_mkmod loc x = {pmod_desc = x; pmod_loc = loc};;
let ocaml_mkfield loc (lab, x) fl =
  {pfield_desc = Pfield (lab, x); pfield_loc = loc} :: fl
;;
let ocaml_mkfield_var loc = [{pfield_desc = Pfield_var; pfield_loc = loc}];;

(* *)

let ocaml_type_declaration tn params cl tk pf tm loc variance =
  match list_map_check (fun s_opt -> s_opt) params with
    Some params ->
      Right
        {ptype_params = params; ptype_cstrs = cl; ptype_kind = tk;
         ptype_manifest = tm; ptype_loc = loc}
  | None -> Left "no '_' type param in this ocaml version"
;;

let ocaml_class_type = Some (fun d loc -> {pcty_desc = d; pcty_loc = loc});;

let ocaml_class_expr = Some (fun d loc -> {pcl_desc = d; pcl_loc = loc});;

let ocaml_class_structure p cil = p, cil;;

let ocaml_pmty_ident loc li = Pmty_ident (mkloc loc li);;

let ocaml_pmty_functor sloc s mt1 mt2 =
  Pmty_functor (mkloc sloc s, mt1, mt2)
;;

let ocaml_pmty_typeof = None;;

let ocaml_pmty_with mt lcl =
  let lcl = List.map (fun (s, c) -> mknoloc s, c) lcl in Pmty_with (mt, lcl)
;;

let ocaml_ptype_abstract = Ptype_abstract;;

let ocaml_ptype_record ltl priv =
  let ltl = List.map (fun (n, m, t, _) -> n, m, t) ltl in Ptype_record ltl
;;

let ocaml_ptype_variant ctl priv =
  try
    let ctl =
      List.map
        (fun (c, tl, rto, loc) -> if rto <> None then raise Exit else c, tl)
        ctl
    in
    Some (Ptype_variant ctl)
  with Exit -> None
;;

let ocaml_ptyp_arrow lab t1 t2 = Ptyp_arrow (t1, t2);;

let ocaml_ptyp_class li tl ll = Ptyp_class (li, tl);;

let ocaml_ptyp_constr loc li tl = Ptyp_constr (mkloc loc li, tl);;

let ocaml_ptyp_object ml = Ptyp_object ml;;

let ocaml_ptyp_package = None;;

let ocaml_ptyp_poly = None;;

let ocaml_ptyp_variant catl clos sl_opt = None;;

let ocaml_package_type li ltl =
  mknoloc li, List.map (fun (li, t) -> mkloc t.ptyp_loc li, t) ltl
;;

let ocaml_pconst_char c = Const_char c;;
let ocaml_pconst_int i = Const_int i;;
let ocaml_pconst_float s = Const_float s;;

let ocaml_const_string s = Const_string s;;
let ocaml_pconst_string s so = Const_string s;;

let pconst_of_const =
  function
    Const_int i -> ocaml_pconst_int i
  | Const_char c -> ocaml_pconst_char c
  | Const_string s -> ocaml_pconst_string s None
  | Const_float s -> ocaml_pconst_float s
;;

let ocaml_const_int32 = None;;

let ocaml_const_int64 = None;;

let ocaml_const_nativeint = None;;

let ocaml_pexp_apply f lel = Pexp_apply (f, List.map snd lel);;

let ocaml_pexp_assertfalse fname loc =
  let ghexp d = {pexp_desc = d; pexp_loc = loc} in
  let triple =
    ghexp
      (Pexp_tuple
         [ghexp (Pexp_constant (Const_string fname));
          ghexp (Pexp_constant (Const_int loc.Location.loc_start));
          ghexp (Pexp_constant (Const_int loc.Location.loc_end))])
  in
  let excep = Ldot (Lident "Pervasives", "Assert_failure") in
  let bucket = ghexp (Pexp_construct (excep, Some triple, false)) in
  let raise_ = ghexp (Pexp_ident (Ldot (Lident "Pervasives", "raise"))) in
  ocaml_pexp_apply raise_ ["", bucket]
;;

let ocaml_pexp_assert fname loc e =
  let ghexp d = {pexp_desc = d; pexp_loc = loc} in
  let ghpat d = {ppat_desc = d; ppat_loc = loc} in
  let triple =
    ghexp
      (Pexp_tuple
         [ghexp (Pexp_constant (Const_string fname));
          ghexp (Pexp_constant (Const_int loc.Location.loc_start));
          ghexp (Pexp_constant (Const_int loc.Location.loc_end))])
  in
  let excep = Ldot (Lident "Pervasives", "Assert_failure") in
  let bucket = ghexp (Pexp_construct (excep, Some triple, false)) in
  let raise_ = ghexp (Pexp_ident (Ldot (Lident "Pervasives", "raise"))) in
  let raise_af = ghexp (ocaml_pexp_apply raise_ ["", bucket]) in
  let under = ghpat Ppat_any in
  let false_ = ghexp (Pexp_construct (Lident "false", None, false)) in
  let try_e = ghexp (Pexp_try (e, [under, false_])) in
  let not_ = ghexp (Pexp_ident (Ldot (Lident "Pervasives", "not"))) in
  let not_try_e = ghexp (ocaml_pexp_apply not_ ["", try_e]) in
  Pexp_ifthenelse (not_try_e, raise_af, None)
;;

let ocaml_pexp_constraint e ot1 ot2 = Pexp_constraint (e, ot1, ot2);;

let ocaml_pexp_construct loc li po chk_arity =
  Pexp_construct (mkloc loc li, po, chk_arity)
;;

let ocaml_pexp_construct_args =
  function
    Pexp_construct (li, po, chk_arity) -> Some (li, 0, po, chk_arity)
  | _ -> None
;;

let mkexp_ocaml_pexp_construct_arity loc li_loc li al =
  let a = ocaml_mkexp loc (Pexp_tuple al) in
  ocaml_mkexp loc (ocaml_pexp_construct li_loc li (Some a) true)
;;

let ocaml_pexp_field loc e li = Pexp_field (e, mkloc loc li);;

let ocaml_pexp_for i e1 e2 df e = Pexp_for (mknoloc i, e1, e2, df, e);;

let ocaml_case (p, wo, loc, e) =
  match wo with
    Some w -> p, ocaml_mkexp loc (Pexp_when (w, e))
  | None -> p, e
;;

let ocaml_pexp_function lab eo pel = Pexp_function pel;;

let ocaml_pexp_lazy = None;;

let ocaml_pexp_ident li = Pexp_ident (mknoloc li);;

let ocaml_pexp_letmodule =
  Some (fun i me e -> Pexp_letmodule (mknoloc i, me, e))
;;

let ocaml_pexp_new loc li = Pexp_new (mkloc loc li);;

let ocaml_pexp_newtype = None;;

let ocaml_pexp_object = None;;

let ocaml_pexp_open = None;;

let ocaml_pexp_override sel =
  let sel = List.map (fun (s, e) -> mknoloc s, e) sel in Pexp_override sel
;;

let ocaml_pexp_pack = None;;

let ocaml_pexp_poly = None;;

let ocaml_pexp_record lel eo =
  let lel = List.map (fun (li, loc, e) -> mkloc loc li, e) lel in
  Pexp_record (lel, eo)
;;

let ocaml_pexp_setinstvar s e = Pexp_setinstvar (mknoloc s, e);;

let ocaml_pexp_variant = None;;

let ocaml_value_binding loc p e = p, e;;

let ocaml_ppat_alias p i iloc = Ppat_alias (p, mkloc iloc i);;

let ocaml_ppat_array = Some (fun pl -> Ppat_array pl);;

let ocaml_ppat_construct loc li po chk_arity =
  Ppat_construct (li, po, chk_arity)
;;

let ocaml_ppat_construct_args =
  function
    Ppat_construct (li, po, chk_arity) -> Some (li, 0, po, chk_arity)
  | _ -> None
;;

let mkpat_ocaml_ppat_construct_arity loc li_loc li al =
  let a = ocaml_mkpat loc (Ppat_tuple al) in
  ocaml_mkpat loc (ocaml_ppat_construct li_loc li (Some a) true)
;;

let ocaml_ppat_lazy = None;;

let ocaml_ppat_record lpl is_closed =
  let lpl = List.map (fun (li, loc, p) -> mkloc loc li, p) lpl in
  Ppat_record lpl
;;

let ocaml_ppat_type = None;;

let ocaml_ppat_unpack = None;;

let ocaml_ppat_var loc s = Ppat_var (mkloc loc s);;

let ocaml_ppat_variant = None;;

let ocaml_psig_class_type = Some (fun ctl -> Psig_class_type ctl);;

let ocaml_psig_exception loc s ed = Psig_exception (mkloc loc s, ed);;

let ocaml_psig_include loc mt = Psig_include mt;;

let ocaml_psig_module loc s mt = Psig_module (mknoloc s, mt);;

let ocaml_psig_modtype loc s mto =
  let mtd =
    match mto with
      None -> Pmodtype_abstract
    | Some t -> Pmodtype_manifest t
  in
  Psig_modtype (mknoloc s, mtd)
;;

let ocaml_psig_open loc li = Psig_open (mkloc loc li);;

let ocaml_psig_recmodule = None;;

let ocaml_psig_type stl =
  let stl = List.map (fun (s, t) -> mknoloc s, t) stl in Psig_type stl
;;

let ocaml_psig_value s vd = Psig_value (mknoloc s, vd);;

let ocaml_pstr_class_type = Some (fun ctl -> Pstr_class_type ctl);;

let ocaml_pstr_eval e = Pstr_eval e;;

let ocaml_pstr_exception loc s ed = Pstr_exception (mkloc loc s, ed);;

let ocaml_pstr_exn_rebind = None;;

let ocaml_pstr_include = None;;

let ocaml_pstr_modtype loc s mt = Pstr_modtype (mkloc loc s, mt);;

let ocaml_pstr_module loc s me = Pstr_module (mkloc loc s, me);;

let ocaml_pstr_open loc li = Pstr_open (mknoloc li);;

let ocaml_pstr_primitive s vd = Pstr_primitive (mknoloc s, vd);;

let ocaml_pstr_recmodule = None;;

let ocaml_pstr_type stl = Pstr_type stl;;

let ocaml_class_infos =
  Some
    (fun virt params name expr loc variance ->
       {pci_virt = virt; pci_params = params; pci_name = name;
        pci_expr = expr; pci_loc = loc})
;;

let ocaml_pmod_ident li = Pmod_ident (mknoloc li);;

let ocaml_pmod_functor s mt me = Pmod_functor (mknoloc s, mt, me);;

let ocaml_pmod_unpack = None;;

let ocaml_pcf_cstr = Some (fun (t1, t2, loc) -> Pcf_cstr (t1, t2, loc));;

let ocaml_pcf_inher ce pb = Pcf_inher (ce, pb);;

let ocaml_pcf_init = Some (fun e -> Pcf_init e);;

let ocaml_pcf_meth (s, pf, ovf, e, loc) =
  let pf = if pf then Private else Public in Pcf_meth (s, pf, e, loc)
;;

let ocaml_pcf_val (s, mf, ovf, e, loc) =
  let mf = if mf then Mutable else Immutable in Pcf_val (s, mf, e, loc)
;;

let ocaml_pcf_valvirt = None;;

let ocaml_pcf_virt (s, pf, t, loc) = Pcf_virt (s, pf, t, loc);;

let ocaml_pcl_apply = Some (fun ce lel -> Pcl_apply (ce, List.map snd lel));;

let ocaml_pcl_constr = Some (fun li ctl -> Pcl_constr (mknoloc li, ctl));;

let ocaml_pcl_constraint = Some (fun ce ct -> Pcl_constraint (ce, ct));;

let ocaml_pcl_fun = Some (fun lab ceo p ce -> Pcl_fun (p, ce));;

let ocaml_pcl_let = Some (fun rf pel ce -> Pcl_let (rf, pel, ce));;

let ocaml_pcl_structure = Some (fun cs -> Pcl_structure cs);;

let ocaml_pctf_cstr = Some (fun (t1, t2, loc) -> Pctf_cstr (t1, t2, loc));;

let ocaml_pctf_inher ct = Pctf_inher ct;;

let ocaml_pctf_meth (s, pf, t, loc) = Pctf_meth (s, pf, t, loc);;

let ocaml_pctf_val (s, mf, t, loc) = Pctf_val (s, mf, Some t, loc);;

let ocaml_pctf_virt (s, pf, t, loc) = Pctf_virt (s, pf, t, loc);;

let ocaml_pcty_constr = Some (fun li ltl -> Pcty_constr (mknoloc li, ltl));;

let ocaml_pcty_fun = Some (fun lab t ct -> Pcty_fun (t, ct));;

let ocaml_pcty_signature = Some (fun (t, cil) -> Pcty_signature (t, cil));;

let ocaml_pdir_bool = None;;
let ocaml_pdir_int i s = Pdir_int s;;

let ocaml_pwith_modsubst = None;;

let ocaml_pwith_type loc (i, td) = Pwith_type td;;

let ocaml_pwith_module loc me = Pwith_module (mkloc loc me);;

let ocaml_pwith_typesubst = None;;

let module_prefix_can_be_in_first_record_label_only = false;;

let split_or_patterns_with_bindings = true;;

let has_records_with_with = true;;

(* *)

let jocaml_pstr_def : (_ -> _) option = None;;

let jocaml_pexp_def : (_ -> _ -> _) option = None;;

let jocaml_pexp_par : (_ -> _ -> _) option = None;;

let jocaml_pexp_reply : (_ -> _ -> _ -> _) option = None;;

let jocaml_pexp_spawn : (_ -> _) option = None;;

let arg_rest =
  function
    Arg.Rest r -> Some r
  | _ -> None
;;

let arg_set_string _ = None;;

let arg_set_int _ = None;;

let arg_set_float _ = None;;

let arg_symbol _ = None;;

let arg_tuple _ = None;;

let arg_bool _ = None;;

let char_escaped =
  function
    '\r' -> "\\r"
  | c -> Char.escaped c
;;

let hashtbl_mem = Hashtbl.mem;;

let list_rev_append = List.rev_append;;

let list_rev_map f =
  let rec loop r =
    function
      x :: l -> loop (f x :: r) l
    | [] -> r
  in
  loop []
;;

let list_sort f l = Sort.list (fun x y -> f x y <= 0) l;;

let pervasives_set_binary_mode_out = Pervasives.set_binary_mode_out;;

let scan_format fmt i kont =
  match fmt.[i+1] with
    'c' -> Obj.magic (fun (c : char) -> kont (String.make 1 c) (i + 2))
  | 'd' -> Obj.magic (fun (d : int) -> kont (string_of_int d) (i + 2))
  | 's' -> Obj.magic (fun (s : string) -> kont s (i + 2))
  | c ->
      failwith (Printf.sprintf "Pretty.sprintf \"%s\" '%%%c' not impl" fmt c)
;;
let printf_ksprintf kont fmt =
  let fmt : string = Obj.magic fmt in
  let len = String.length fmt in
  let rec doprn rev_sl i =
    if i >= len then
      let s = String.concat "" (List.rev rev_sl) in Obj.magic (kont s)
    else
      match fmt.[i] with
        '%' -> scan_format fmt i (fun s -> doprn (s :: rev_sl))
      | c -> doprn (String.make 1 c :: rev_sl) (i + 1)
  in
  doprn [] 0
;;

let char_uppercase = Char.uppercase;;

let string_capitalize = String.capitalize;;

let string_contains = String.contains;;

let string_copy = String.copy;;

let string_create = String.create;;

let string_lowercase = String.lowercase;;

let string_unsafe_set = String.unsafe_set;;

let string_uncapitalize = String.uncapitalize;;

let string_uppercase = String.uppercase;;

let string_set = String.set;;

let array_create = Array.create;;
