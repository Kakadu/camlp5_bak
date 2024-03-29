(* camlp5r *)
(* pa_r.ml,v *)
(* Copyright (c) INRIA 2007-2016 *)

(* #load "pa_extend.cmo" *)
(* #load "q_MLast.cmo" *)
(* #load "pa_macro.cmo" *)

open Pcaml;;

Pcaml.syntax_name := "Revised";;
Pcaml.no_constructors_arity := false;;

let odfa = !(Plexer.dollar_for_antiquotation) in
let odni = !(Plexer.dot_newline_is) in
Plexer.dollar_for_antiquotation := false;
Plexer.utf8_lexing := true;
Plexer.dot_newline_is := ";";
Grammar.Unsafe.gram_reinit gram (Plexer.gmake ());
Plexer.dot_newline_is := odni;
Plexer.dollar_for_antiquotation := odfa;
Grammar.Unsafe.clear_entry interf;
Grammar.Unsafe.clear_entry implem;
Grammar.Unsafe.clear_entry top_phrase;
Grammar.Unsafe.clear_entry use_file;
Grammar.Unsafe.clear_entry module_type;
Grammar.Unsafe.clear_entry module_expr;
Grammar.Unsafe.clear_entry sig_item;
Grammar.Unsafe.clear_entry str_item;
Grammar.Unsafe.clear_entry signature;
Grammar.Unsafe.clear_entry structure;
Grammar.Unsafe.clear_entry expr;
Grammar.Unsafe.clear_entry patt;
Grammar.Unsafe.clear_entry ipatt;
Grammar.Unsafe.clear_entry ctyp;
Grammar.Unsafe.clear_entry let_binding;
Grammar.Unsafe.clear_entry type_decl;
Grammar.Unsafe.clear_entry constructor_declaration;
Grammar.Unsafe.clear_entry label_declaration;
Grammar.Unsafe.clear_entry match_case;
Grammar.Unsafe.clear_entry with_constr;
Grammar.Unsafe.clear_entry poly_variant;
Grammar.Unsafe.clear_entry class_type;
Grammar.Unsafe.clear_entry class_expr;
Grammar.Unsafe.clear_entry class_sig_item;
Grammar.Unsafe.clear_entry class_str_item;;

Pcaml.parse_interf := Grammar.Entry.parse interf;;
Pcaml.parse_implem := Grammar.Entry.parse implem;;

Pcaml.add_option "-ignloaddir"
  (Arg.Unit (fun _ -> add_directive "load" (fun _ -> ())))
  "Ignore the #load directives in the input file.";;

let mksequence2 loc =
  function
    [e] -> e
  | seq -> MLast.ExSeq (loc, seq)
;;

let mksequence loc =
  function
    [e] -> e
  | el -> MLast.ExSeq (loc, el)
;;

let mkmatchcase loc p aso w e =
  let p =
    match aso with
      Some p2 -> MLast.PaAli (loc, p, p2)
    | None -> p
  in
  p, w, e
;;

let neg_string n =
  let len = String.length n in
  if len > 0 && n.[0] = '-' then String.sub n 1 (len - 1) else "-" ^ n
;;

let mklistexp loc last =
  let rec loop top =
    function
      [] ->
        begin match last with
          Some e -> e
        | None -> MLast.ExUid (loc, "[]")
        end
    | e1 :: el ->
        let loc = if top then loc else Ploc.encl (MLast.loc_of_expr e1) loc in
        MLast.ExApp
          (loc, MLast.ExApp (loc, MLast.ExUid (loc, "::"), e1), loop false el)
  in
  loop true
;;

let mklistpat loc last =
  let rec loop top =
    function
      [] ->
        begin match last with
          Some p -> p
        | None -> MLast.PaUid (loc, "[]")
        end
    | p1 :: pl ->
        let loc = if top then loc else Ploc.encl (MLast.loc_of_patt p1) loc in
        MLast.PaApp
          (loc, MLast.PaApp (loc, MLast.PaUid (loc, "::"), p1), loop false pl)
  in
  loop true
;;

let mktupexp loc e el = MLast.ExTup (loc, e :: el);;
let mktuppat loc p pl = MLast.PaTup (loc, p :: pl);;
let mktuptyp loc t tl = MLast.TyTup (loc, t :: tl);;

let mklabdecl loc i mf t = loc, i, mf, t;;
let mkident i : string = i;;

let rec generalized_type_of_type =
  function
    MLast.TyArr (_, t1, t2) ->
      let (tl, rt) = generalized_type_of_type t2 in t1 :: tl, rt
  | t -> [], t
;;

let warned = ref false;;
let warning_deprecated_since_6_00 loc =
  if not !warned then
    begin
      !(Pcaml.warning) loc "syntax deprecated since version 6.00";
      warned := true
    end
;;

(* -- begin copy from pa_r to q_MLast -- *)

Grammar.extend
  (let _ = (sig_item : 'sig_item Grammar.Entry.e)
   and _ = (str_item : 'str_item Grammar.Entry.e)
   and _ = (ctyp : 'ctyp Grammar.Entry.e)
   and _ = (patt : 'patt Grammar.Entry.e)
   and _ = (expr : 'expr Grammar.Entry.e)
   and _ = (module_type : 'module_type Grammar.Entry.e)
   and _ = (module_expr : 'module_expr Grammar.Entry.e)
   and _ = (signature : 'signature Grammar.Entry.e)
   and _ = (structure : 'structure Grammar.Entry.e)
   and _ = (class_type : 'class_type Grammar.Entry.e)
   and _ = (class_expr : 'class_expr Grammar.Entry.e)
   and _ = (class_sig_item : 'class_sig_item Grammar.Entry.e)
   and _ = (class_str_item : 'class_str_item Grammar.Entry.e)
   and _ = (let_binding : 'let_binding Grammar.Entry.e)
   and _ = (type_decl : 'type_decl Grammar.Entry.e)
   and _ =
     (constructor_declaration : 'constructor_declaration Grammar.Entry.e)
   and _ = (label_declaration : 'label_declaration Grammar.Entry.e)
   and _ = (match_case : 'match_case Grammar.Entry.e)
   and _ = (ipatt : 'ipatt Grammar.Entry.e)
   and _ = (with_constr : 'with_constr Grammar.Entry.e)
   and _ = (poly_variant : 'poly_variant Grammar.Entry.e) in
   let grammar_entry_create s =
     Grammar.create_local_entry (Grammar.of_entry sig_item) s
   in
   let rebind_exn : 'rebind_exn Grammar.Entry.e =
     grammar_entry_create "rebind_exn"
   and mod_binding : 'mod_binding Grammar.Entry.e =
     grammar_entry_create "mod_binding"
   and mod_fun_binding : 'mod_fun_binding Grammar.Entry.e =
     grammar_entry_create "mod_fun_binding"
   and mod_type_fun_binding : 'mod_type_fun_binding Grammar.Entry.e =
     grammar_entry_create "mod_type_fun_binding"
   and mod_decl_binding : 'mod_decl_binding Grammar.Entry.e =
     grammar_entry_create "mod_decl_binding"
   and module_declaration : 'module_declaration Grammar.Entry.e =
     grammar_entry_create "module_declaration"
   and closed_case_list : 'closed_case_list Grammar.Entry.e =
     grammar_entry_create "closed_case_list"
   and cons_expr_opt : 'cons_expr_opt Grammar.Entry.e =
     grammar_entry_create "cons_expr_opt"
   and dummy : 'dummy Grammar.Entry.e = grammar_entry_create "dummy"
   and sequence : 'sequence Grammar.Entry.e = grammar_entry_create "sequence"
   and fun_binding : 'fun_binding Grammar.Entry.e =
     grammar_entry_create "fun_binding"
   and as_patt_opt : 'as_patt_opt Grammar.Entry.e =
     grammar_entry_create "as_patt_opt"
   and when_expr : 'when_expr Grammar.Entry.e =
     grammar_entry_create "when_expr"
   and label_expr : 'label_expr Grammar.Entry.e =
     grammar_entry_create "label_expr"
   and fun_def : 'fun_def Grammar.Entry.e = grammar_entry_create "fun_def"
   and paren_patt : 'paren_patt Grammar.Entry.e =
     grammar_entry_create "paren_patt"
   and cons_patt_opt : 'cons_patt_opt Grammar.Entry.e =
     grammar_entry_create "cons_patt_opt"
   and label_patt : 'label_patt Grammar.Entry.e =
     grammar_entry_create "label_patt"
   and patt_label_ident : 'patt_label_ident Grammar.Entry.e =
     grammar_entry_create "patt_label_ident"
   and paren_ipatt : 'paren_ipatt Grammar.Entry.e =
     grammar_entry_create "paren_ipatt"
   and label_ipatt : 'label_ipatt Grammar.Entry.e =
     grammar_entry_create "label_ipatt"
   and type_patt : 'type_patt Grammar.Entry.e =
     grammar_entry_create "type_patt"
   and constrain : 'constrain Grammar.Entry.e =
     grammar_entry_create "constrain"
   and type_parameter : 'type_parameter Grammar.Entry.e =
     grammar_entry_create "type_parameter"
   and simple_type_parameter : 'simple_type_parameter Grammar.Entry.e =
     grammar_entry_create "simple_type_parameter"
   and ident : 'ident Grammar.Entry.e = grammar_entry_create "ident"
   and mod_ident : 'mod_ident Grammar.Entry.e =
     grammar_entry_create "mod_ident"
   and class_declaration : 'class_declaration Grammar.Entry.e =
     grammar_entry_create "class_declaration"
   and class_fun_binding : 'class_fun_binding Grammar.Entry.e =
     grammar_entry_create "class_fun_binding"
   and class_type_parameters : 'class_type_parameters Grammar.Entry.e =
     grammar_entry_create "class_type_parameters"
   and class_fun_def : 'class_fun_def Grammar.Entry.e =
     grammar_entry_create "class_fun_def"
   and class_structure : 'class_structure Grammar.Entry.e =
     grammar_entry_create "class_structure"
   and class_self_patt : 'class_self_patt Grammar.Entry.e =
     grammar_entry_create "class_self_patt"
   and as_lident : 'as_lident Grammar.Entry.e =
     grammar_entry_create "as_lident"
   and polyt : 'polyt Grammar.Entry.e = grammar_entry_create "polyt"
   and cvalue_binding : 'cvalue_binding Grammar.Entry.e =
     grammar_entry_create "cvalue_binding"
   and lident : 'lident Grammar.Entry.e = grammar_entry_create "lident"
   and class_self_type : 'class_self_type Grammar.Entry.e =
     grammar_entry_create "class_self_type"
   and class_description : 'class_description Grammar.Entry.e =
     grammar_entry_create "class_description"
   and class_type_declaration : 'class_type_declaration Grammar.Entry.e =
     grammar_entry_create "class_type_declaration"
   and field_expr : 'field_expr Grammar.Entry.e =
     grammar_entry_create "field_expr"
   and field : 'field Grammar.Entry.e = grammar_entry_create "field"
   and typevar : 'typevar Grammar.Entry.e = grammar_entry_create "typevar"
   and class_longident : 'class_longident Grammar.Entry.e =
     grammar_entry_create "class_longident"
   and poly_variant_list : 'poly_variant_list Grammar.Entry.e =
     grammar_entry_create "poly_variant_list"
   and name_tag : 'name_tag Grammar.Entry.e = grammar_entry_create "name_tag"
   and patt_tcon_opt_eq_patt : 'patt_tcon_opt_eq_patt Grammar.Entry.e =
     grammar_entry_create "patt_tcon_opt_eq_patt"
   and patt_tcon : 'patt_tcon Grammar.Entry.e =
     grammar_entry_create "patt_tcon"
   and ipatt_tcon_opt_eq_patt : 'ipatt_tcon_opt_eq_patt Grammar.Entry.e =
     grammar_entry_create "ipatt_tcon_opt_eq_patt"
   and ipatt_tcon : 'ipatt_tcon Grammar.Entry.e =
     grammar_entry_create "ipatt_tcon"
   and patt_option_label : 'patt_option_label Grammar.Entry.e =
     grammar_entry_create "patt_option_label"
   and ipatt_tcon_fun_binding : 'ipatt_tcon_fun_binding Grammar.Entry.e =
     grammar_entry_create "ipatt_tcon_fun_binding"
   and direction_flag : 'direction_flag Grammar.Entry.e =
     grammar_entry_create "direction_flag"
   in
   [Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "struct");
       Gramext.Snterm
         (Grammar.Entry.obj (structure : 'structure Grammar.Entry.e));
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (st : 'structure) _ (loc : Ploc.t) ->
           (MLast.MeStr (loc, st) : 'module_expr));
      [Gramext.Stoken ("", "functor"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")"); Gramext.Stoken ("", "->"); Gramext.Sself],
      Gramext.action
        (fun (me : 'module_expr) _ _ (t : 'module_type) _ (i : string) _ _
             (loc : Ploc.t) ->
           (MLast.MeFun (loc, i, t, me) : 'module_expr))];
     None, None,
     [[Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (me2 : 'module_expr) (me1 : 'module_expr) (loc : Ploc.t) ->
           (MLast.MeApp (loc, me1, me2) : 'module_expr))];
     None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (me2 : 'module_expr) _ (me1 : 'module_expr) (loc : Ploc.t) ->
           (MLast.MeAcc (loc, me1, me2) : 'module_expr))];
     Some "simple", None,
     [[Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (me : 'module_expr) _ (loc : Ploc.t) -> (me : 'module_expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (mt : 'module_type) _ (me : 'module_expr) _ (loc : Ploc.t) ->
           (MLast.MeTyc (loc, me, mt) : 'module_expr));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("", "value");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ _ (loc : Ploc.t) ->
           (MLast.MeUnp (loc, e, None) : 'module_expr));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("", "value");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (mt : 'module_type) _ (e : 'expr) _ _ (loc : Ploc.t) ->
           (MLast.MeUnp (loc, e, Some mt) : 'module_expr));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.MeUid (loc, i) : 'module_expr))]];
    Grammar.Entry.obj (structure : 'structure Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'str_item) (loc : Ploc.t) -> (s : 'e__1))])],
      Gramext.action
        (fun (st : 'e__1 list) (loc : Ploc.t) -> (st : 'structure))]];
    Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e), None,
    [Some "top", None,
     [[Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) (loc : Ploc.t) ->
           (MLast.StExp (loc, e) : 'str_item));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("STRING", "");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e))],
             Gramext.action
               (fun (si : 'str_item) (loc : Ploc.t) -> (si, loc : 'e__3))])],
      Gramext.action
        (fun (sil : 'e__3 list) (s : string) _ (loc : Ploc.t) ->
           (MLast.StUse (loc, s, sil) : 'str_item));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)))],
      Gramext.action
        (fun (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           (MLast.StDir (loc, n, dp) : 'str_item));
      [Gramext.Stoken ("", "value");
       Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (l : 'let_binding list) (r : bool) _ (loc : Ploc.t) ->
           (MLast.StVal (loc, r, l) : 'str_item));
      [Gramext.Stoken ("", "type");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (type_decl : 'type_decl Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (tdl : 'type_decl list) _ (loc : Ploc.t) ->
           (MLast.StTyp (loc, tdl) : 'str_item));
      [Gramext.Stoken ("", "open");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.StOpn (loc, i) : 'str_item));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("", "type");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj
            (mod_type_fun_binding : 'mod_type_fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'mod_type_fun_binding) (i : 'ident) _ _ (loc : Ploc.t) ->
           (MLast.StMty (loc, i, mt) : 'str_item));
      [Gramext.Stoken ("", "module");
       Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (mod_binding : 'mod_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (l : 'mod_binding list) (r : bool) _ (loc : Ploc.t) ->
           (MLast.StMod (loc, r, l) : 'str_item));
      [Gramext.Stoken ("", "include");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ (loc : Ploc.t) ->
           (MLast.StInc (loc, me) : 'str_item));
      [Gramext.Stoken ("", "external"); Gramext.Stoken ("LIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Slist1 (Gramext.Stoken ("STRING", ""))],
      Gramext.action
        (fun (pd : string list) _ (t : 'ctyp) _ (i : string) _
             (loc : Ploc.t) ->
           (MLast.StExt (loc, i, t, pd) : 'str_item));
      [Gramext.Stoken ("", "exception");
       Gramext.Snterm
         (Grammar.Entry.obj
            (constructor_declaration :
             'constructor_declaration Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (rebind_exn : 'rebind_exn Grammar.Entry.e))],
      Gramext.action
        (fun (b : 'rebind_exn) (_, c, tl, _ : 'constructor_declaration) _
             (loc : Ploc.t) ->
           (MLast.StExc (loc, c, tl, b) : 'str_item));
      [Gramext.Stoken ("", "declare");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'str_item) (loc : Ploc.t) -> (s : 'e__2))]);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (st : 'e__2 list) _ (loc : Ploc.t) ->
           (MLast.StDcl (loc, st) : 'str_item))]];
    Grammar.Entry.obj (rebind_exn : 'rebind_exn Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Ploc.t) -> ([] : 'rebind_exn));
      [Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e))],
      Gramext.action
        (fun (a : 'mod_ident) _ (loc : Ploc.t) -> (a : 'rebind_exn))]];
    Grammar.Entry.obj (mod_binding : 'mod_binding Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("UIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (mod_fun_binding : 'mod_fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'mod_fun_binding) (i : string) (loc : Ploc.t) ->
           (i, me : 'mod_binding))]];
    Grammar.Entry.obj (mod_fun_binding : 'mod_fun_binding Grammar.Entry.e),
    None,
    [None, Some Gramext.RightA,
     [[Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ (loc : Ploc.t) -> (me : 'mod_fun_binding));
      [Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ (mt : 'module_type) _ (loc : Ploc.t) ->
           (MLast.MeTyc (loc, me, mt) : 'mod_fun_binding));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("UIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")"); Gramext.Sself],
      Gramext.action
        (fun (mb : 'mod_fun_binding) _ (mt : 'module_type) _ (m : string) _
             (loc : Ploc.t) ->
           (MLast.MeFun (loc, m, mt, mb) : 'mod_fun_binding))]];
    Grammar.Entry.obj
      (mod_type_fun_binding : 'mod_type_fun_binding Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (loc : Ploc.t) ->
           (mt : 'mod_type_fun_binding));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("UIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")"); Gramext.Sself],
      Gramext.action
        (fun (mt2 : 'mod_type_fun_binding) _ (mt1 : 'module_type) _
             (m : string) _ (loc : Ploc.t) ->
           (MLast.MtFun (loc, m, mt1, mt2) : 'mod_type_fun_binding))]];
    Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "functor"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", ":"); Gramext.Sself;
       Gramext.Stoken ("", ")"); Gramext.Stoken ("", "->"); Gramext.Sself],
      Gramext.action
        (fun (mt : 'module_type) _ _ (t : 'module_type) _ (i : string) _ _
             (loc : Ploc.t) ->
           (MLast.MtFun (loc, i, t, mt) : 'module_type))];
     None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "with");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (with_constr : 'with_constr Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (wcl : 'with_constr list) _ (mt : 'module_type) (loc : Ploc.t) ->
           (MLast.MtWit (loc, mt, wcl) : 'module_type))];
     None, None,
     [[Gramext.Stoken ("", "module"); Gramext.Stoken ("", "type");
       Gramext.Stoken ("", "of");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ _ _ (loc : Ploc.t) ->
           (MLast.MtTyo (loc, me) : 'module_type));
      [Gramext.Stoken ("", "sig");
       Gramext.Snterm
         (Grammar.Entry.obj (signature : 'signature Grammar.Entry.e));
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (sg : 'signature) _ (loc : Ploc.t) ->
           (MLast.MtSig (loc, sg) : 'module_type))];
     None, None,
     [[Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (m2 : 'module_type) (m1 : 'module_type) (loc : Ploc.t) ->
           (MLast.MtApp (loc, m1, m2) : 'module_type))];
     None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (m2 : 'module_type) _ (m1 : 'module_type) (loc : Ploc.t) ->
           (MLast.MtAcc (loc, m1, m2) : 'module_type))];
     Some "simple", None,
     [[Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (mt : 'module_type) _ (loc : Ploc.t) -> (mt : 'module_type));
      [Gramext.Stoken ("", "'");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'ident) _ (loc : Ploc.t) ->
           (MLast.MtQuo (loc, i) : 'module_type));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.MtLid (loc, i) : 'module_type));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.MtUid (loc, i) : 'module_type))]];
    Grammar.Entry.obj (signature : 'signature Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'sig_item) (loc : Ploc.t) -> (s : 'e__4))])],
      Gramext.action
        (fun (st : 'e__4 list) (loc : Ploc.t) -> (st : 'signature))]];
    Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e), None,
    [Some "top", None,
     [[Gramext.Stoken ("", "#"); Gramext.Stoken ("STRING", "");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e))],
             Gramext.action
               (fun (si : 'sig_item) (loc : Ploc.t) -> (si, loc : 'e__6))])],
      Gramext.action
        (fun (sil : 'e__6 list) (s : string) _ (loc : Ploc.t) ->
           (MLast.SgUse (loc, s, sil) : 'sig_item));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)))],
      Gramext.action
        (fun (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           (MLast.SgDir (loc, n, dp) : 'sig_item));
      [Gramext.Stoken ("", "value"); Gramext.Stoken ("LIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (i : string) _ (loc : Ploc.t) ->
           (MLast.SgVal (loc, i, t) : 'sig_item));
      [Gramext.Stoken ("", "type");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (type_decl : 'type_decl Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (tdl : 'type_decl list) _ (loc : Ploc.t) ->
           (MLast.SgTyp (loc, tdl) : 'sig_item));
      [Gramext.Stoken ("", "open");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.SgOpn (loc, i) : 'sig_item));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("", "type");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (i : 'ident) _ _ (loc : Ploc.t) ->
           (MLast.SgMty (loc, i, mt) : 'sig_item));
      [Gramext.Stoken ("", "module");
       Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (mod_decl_binding : 'mod_decl_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (l : 'mod_decl_binding list) (rf : bool) _ (loc : Ploc.t) ->
           (MLast.SgMod (loc, rf, l) : 'sig_item));
      [Gramext.Stoken ("", "include");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (loc : Ploc.t) ->
           (MLast.SgInc (loc, mt) : 'sig_item));
      [Gramext.Stoken ("", "external"); Gramext.Stoken ("LIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Slist1 (Gramext.Stoken ("STRING", ""))],
      Gramext.action
        (fun (pd : string list) _ (t : 'ctyp) _ (i : string) _
             (loc : Ploc.t) ->
           (MLast.SgExt (loc, i, t, pd) : 'sig_item));
      [Gramext.Stoken ("", "exception");
       Gramext.Snterm
         (Grammar.Entry.obj
            (constructor_declaration :
             'constructor_declaration Grammar.Entry.e))],
      Gramext.action
        (fun (_, c, tl, _ : 'constructor_declaration) _ (loc : Ploc.t) ->
           (MLast.SgExc (loc, c, tl) : 'sig_item));
      [Gramext.Stoken ("", "declare");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'sig_item) (loc : Ploc.t) -> (s : 'e__5))]);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (st : 'e__5 list) _ (loc : Ploc.t) ->
           (MLast.SgDcl (loc, st) : 'sig_item))]];
    Grammar.Entry.obj (mod_decl_binding : 'mod_decl_binding Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("UIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (module_declaration : 'module_declaration Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_declaration) (i : string) (loc : Ploc.t) ->
           (i, mt : 'mod_decl_binding))]];
    Grammar.Entry.obj
      (module_declaration : 'module_declaration Grammar.Entry.e),
    None,
    [None, Some Gramext.RightA,
     [[Gramext.Stoken ("", "("); Gramext.Stoken ("UIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")"); Gramext.Sself],
      Gramext.action
        (fun (mt : 'module_declaration) _ (t : 'module_type) _ (i : string) _
             (loc : Ploc.t) ->
           (MLast.MtFun (loc, i, t, mt) : 'module_declaration));
      [Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (loc : Ploc.t) ->
           (mt : 'module_declaration))]];
    Grammar.Entry.obj (with_constr : 'with_constr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "module");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e));
       Gramext.Stoken ("", ":=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ (i : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.WcMos (loc, i, me) : 'with_constr));
      [Gramext.Stoken ("", "module");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e))],
      Gramext.action
        (fun (me : 'module_expr) _ (i : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.WcMod (loc, i, me) : 'with_constr));
      [Gramext.Stoken ("", "type");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e));
       Gramext.Slist0
         (Gramext.Snterm
            (Grammar.Entry.obj
               (type_parameter : 'type_parameter Grammar.Entry.e)));
       Gramext.Stoken ("", ":=");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (tpl : 'type_parameter list) (i : 'mod_ident) _
             (loc : Ploc.t) ->
           (MLast.WcTys (loc, i, tpl, t) : 'with_constr));
      [Gramext.Stoken ("", "type");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e));
       Gramext.Slist0
         (Gramext.Snterm
            (Grammar.Entry.obj
               (type_parameter : 'type_parameter Grammar.Entry.e)));
       Gramext.Stoken ("", "=");
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) (pf : bool) _ (tpl : 'type_parameter list)
             (i : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.WcTyp (loc, i, tpl, pf, t) : 'with_constr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), None,
    [Some "top", Some Gramext.RightA,
     [[Gramext.Stoken ("", "while"); Gramext.Sself; Gramext.Stoken ("", "do");
       Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (sequence : 'sequence Grammar.Entry.e));
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (seq : 'sequence) _ _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExWhi (loc, e, seq) : 'expr));
      [Gramext.Stoken ("", "for"); Gramext.Stoken ("LIDENT", "");
       Gramext.Stoken ("", "="); Gramext.Sself;
       Gramext.Snterm
         (Grammar.Entry.obj
            (direction_flag : 'direction_flag Grammar.Entry.e));
       Gramext.Sself; Gramext.Stoken ("", "do"); Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (sequence : 'sequence Grammar.Entry.e));
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (seq : 'sequence) _ _ (e2 : 'expr) (df : 'direction_flag)
             (e1 : 'expr) _ (i : string) _ (loc : Ploc.t) ->
           (MLast.ExFor (loc, i, e1, e2, df, seq) : 'expr));
      [Gramext.Stoken ("", "do"); Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (sequence : 'sequence Grammar.Entry.e));
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (seq : 'sequence) _ _ (loc : Ploc.t) ->
           (mksequence2 loc seq : 'expr));
      [Gramext.Stoken ("", "if"); Gramext.Sself; Gramext.Stoken ("", "then");
       Gramext.Sself; Gramext.Stoken ("", "else"); Gramext.Sself],
      Gramext.action
        (fun (e3 : 'expr) _ (e2 : 'expr) _ (e1 : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExIfe (loc, e1, e2, e3) : 'expr));
      [Gramext.Stoken ("", "try"); Gramext.Sself; Gramext.Stoken ("", "with");
       Gramext.Snterm
         (Grammar.Entry.obj (match_case : 'match_case Grammar.Entry.e))],
      Gramext.action
        (fun (mc : 'match_case) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExTry (loc, e, [mc]) : 'expr));
      [Gramext.Stoken ("", "try"); Gramext.Sself; Gramext.Stoken ("", "with");
       Gramext.Snterm
         (Grammar.Entry.obj
            (closed_case_list : 'closed_case_list Grammar.Entry.e))],
      Gramext.action
        (fun (l : 'closed_case_list) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExTry (loc, e, l) : 'expr));
      [Gramext.Stoken ("", "match"); Gramext.Sself;
       Gramext.Stoken ("", "with");
       Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Stoken ("", "->"); Gramext.Sself],
      Gramext.action
        (fun (e1 : 'expr) _ (p1 : 'ipatt) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExMat (loc, e, [p1, None, e1]) : 'expr));
      [Gramext.Stoken ("", "match"); Gramext.Sself;
       Gramext.Stoken ("", "with");
       Gramext.Snterm
         (Grammar.Entry.obj
            (closed_case_list : 'closed_case_list Grammar.Entry.e))],
      Gramext.action
        (fun (l : 'closed_case_list) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExMat (loc, e, l) : 'expr));
      [Gramext.Stoken ("", "fun");
       Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (fun_def : 'fun_def Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'fun_def) (p : 'ipatt) _ (loc : Ploc.t) ->
           (MLast.ExFun (loc, [p, None, e]) : 'expr));
      [Gramext.Stoken ("", "fun");
       Gramext.Snterm
         (Grammar.Entry.obj
            (closed_case_list : 'closed_case_list Grammar.Entry.e))],
      Gramext.action
        (fun (l : 'closed_case_list) _ (loc : Ploc.t) ->
           (MLast.ExFun (loc, l) : 'expr));
      [Gramext.Stoken ("", "let"); Gramext.Stoken ("", "module");
       Gramext.Stoken ("UIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (mod_fun_binding : 'mod_fun_binding Grammar.Entry.e));
       Gramext.Stoken ("", "in"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (mb : 'mod_fun_binding) (m : string) _ _
             (loc : Ploc.t) ->
           (MLast.ExLmd (loc, m, mb, e) : 'expr));
      [Gramext.Stoken ("", "let"); Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false);
       Gramext.Stoken ("", "in"); Gramext.Sself],
      Gramext.action
        (fun (x : 'expr) _ (l : 'let_binding list) (r : bool) _
             (loc : Ploc.t) ->
           (MLast.ExLet (loc, r, l, x) : 'expr))];
     Some "where", None,
     [[Gramext.Sself; Gramext.Stoken ("", "where");
       Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Snterm
         (Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e))],
      Gramext.action
        (fun (lb : 'let_binding) (rf : bool) _ (e : 'expr) (loc : Ploc.t) ->
           (MLast.ExLet (loc, rf, [lb], e) : 'expr))];
     Some ":=", Some Gramext.NonA,
     [[Gramext.Sself; Gramext.Stoken ("", ":="); Gramext.Sself;
       Gramext.Snterm (Grammar.Entry.obj (dummy : 'dummy Grammar.Entry.e))],
      Gramext.action
        (fun _ (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExAss (loc, e1, e2) : 'expr))];
     Some "||", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "||"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "||"), e1), e2) :
            'expr))];
     Some "&&", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "&&"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "&&"), e1), e2) :
            'expr))];
     Some "<", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "!="); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "!="), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "=="); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "=="), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "<>"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "<>"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "="); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "="), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", ">="); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, ">="), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "<="); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "<="), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", ">"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, ">"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "<"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "<"), e1), e2) :
            'expr))];
     Some "^", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "@"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "@"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "^"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "^"), e1), e2) :
            'expr))];
     Some "+", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "-."); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "-."), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "+."); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "+."), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "-"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "-"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "+"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "+"), e1), e2) :
            'expr))];
     Some "*", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "mod"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "mod"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "lxor"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "lxor"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "lor"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "lor"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "land"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "land"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "/."); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "/."), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "*."); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "*."), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "/"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "/"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "*"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "*"), e1), e2) :
            'expr))];
     Some "**", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "lsr"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "lsr"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "lsl"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "lsl"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "asr"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "asr"), e1), e2) :
            'expr));
      [Gramext.Sself; Gramext.Stoken ("", "**"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp
              (loc, MLast.ExApp (loc, MLast.ExLid (loc, "**"), e1), e2) :
            'expr))];
     Some "unary minus", Some Gramext.NonA,
     [[Gramext.Stoken ("", "-."); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExApp (loc, MLast.ExLid (loc, "-."), e) : 'expr));
      [Gramext.Stoken ("", "-"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExApp (loc, MLast.ExLid (loc, "-"), e) : 'expr))];
     Some "apply", Some Gramext.LeftA,
     [[Gramext.Stoken ("", "lazy"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) -> (MLast.ExLaz (loc, e) : 'expr));
      [Gramext.Stoken ("", "assert"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) -> (MLast.ExAsr (loc, e) : 'expr));
      [Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExApp (loc, e1, e2) : 'expr))];
     Some ".", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExAcc (loc, e1, e2) : 'expr));
      [Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (el : 'expr list) _ _ (e : 'expr) (loc : Ploc.t) ->
           (MLast.ExBae (loc, e, el) : 'expr));
      [Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Stoken ("", "[");
       Gramext.Sself; Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (e2 : 'expr) _ _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExSte (loc, e1, e2) : 'expr));
      [Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Stoken ("", "(");
       Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e2 : 'expr) _ _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExAre (loc, e1, e2) : 'expr))];
     Some "~-", Some Gramext.NonA,
     [[Gramext.Stoken ("", "~-."); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExApp (loc, MLast.ExLid (loc, "~-."), e) : 'expr));
      [Gramext.Stoken ("", "~-"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExApp (loc, MLast.ExLid (loc, "~-"), e) : 'expr))];
     Some "simple", None,
     [[Gramext.Stoken ("", "(");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (el : 'expr list) _ (loc : Ploc.t) ->
           (MLast.ExTup (loc, el) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action (fun _ (e : 'expr) _ (loc : Ploc.t) -> (e : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ",");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (el : 'expr list) _ (e : 'expr) _ (loc : Ploc.t) ->
           (mktupexp loc e el : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExTyc (loc, e, t) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("", "module");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (me : 'module_expr) _ _ (loc : Ploc.t) ->
           (MLast.ExPck (loc, me, None) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("", "module");
       Gramext.Snterm
         (Grammar.Entry.obj (module_expr : 'module_expr Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (mt : 'module_type) _ (me : 'module_expr) _ _ (loc : Ploc.t) ->
           (MLast.ExPck (loc, me, Some mt) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ _ (loc : Ploc.t) -> (MLast.ExUid (loc, "()") : 'expr));
      [Gramext.Stoken ("", "{"); Gramext.Stoken ("", "("); Gramext.Sself;
       Gramext.Stoken ("", ")"); Gramext.Stoken ("", "with");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (label_expr : 'label_expr Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lel : 'label_expr list) _ _ (e : 'expr) _ _ (loc : Ploc.t) ->
           (MLast.ExRec (loc, lel, Some e) : 'expr));
      [Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (label_expr : 'label_expr Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lel : 'label_expr list) _ (loc : Ploc.t) ->
           (MLast.ExRec (loc, lel, None) : 'expr));
      [Gramext.Stoken ("", "[|");
       Gramext.Slist0sep
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "|]")],
      Gramext.action
        (fun _ (el : 'expr list) _ (loc : Ploc.t) ->
           (MLast.ExArr (loc, el) : 'expr));
      [Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Snterm
         (Grammar.Entry.obj (cons_expr_opt : 'cons_expr_opt Grammar.Entry.e));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (last : 'cons_expr_opt) (el : 'expr list) _ (loc : Ploc.t) ->
           (mklistexp loc last el : 'expr));
      [Gramext.Stoken ("", "["); Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ _ (loc : Ploc.t) -> (MLast.ExUid (loc, "[]") : 'expr));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (MLast.ExUid (loc, i) : 'expr));
      [Gramext.Stoken ("GIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (MLast.ExLid (loc, i) : 'expr));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (MLast.ExLid (loc, i) : 'expr));
      [Gramext.Stoken ("CHAR", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.ExChr (loc, s) : 'expr));
      [Gramext.Stoken ("STRING", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.ExStr (loc, s) : 'expr));
      [Gramext.Stoken ("FLOAT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.ExFlo (loc, s) : 'expr));
      [Gramext.Stoken ("INT_n", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.ExInt (loc, s, "n") : 'expr));
      [Gramext.Stoken ("INT_L", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.ExInt (loc, s, "L") : 'expr));
      [Gramext.Stoken ("INT_l", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.ExInt (loc, s, "l") : 'expr));
      [Gramext.Stoken ("INT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.ExInt (loc, s, "") : 'expr))]];
    Grammar.Entry.obj (closed_case_list : 'closed_case_list Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "|");
       Gramext.Slist0sep
         (Gramext.Snterm
            (Grammar.Entry.obj (match_case : 'match_case Grammar.Entry.e)),
          Gramext.Stoken ("", "|"), false);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (l : 'match_case list) _ (loc : Ploc.t) ->
           (l : 'closed_case_list));
      [Gramext.Stoken ("", "[");
       Gramext.Slist0sep
         (Gramext.Snterm
            (Grammar.Entry.obj (match_case : 'match_case Grammar.Entry.e)),
          Gramext.Stoken ("", "|"), false);
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (l : 'match_case list) _ (loc : Ploc.t) ->
           (l : 'closed_case_list))]];
    Grammar.Entry.obj (cons_expr_opt : 'cons_expr_opt Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Ploc.t) -> (None : 'cons_expr_opt));
      [Gramext.Stoken ("", "::");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) -> (Some e : 'cons_expr_opt))]];
    Grammar.Entry.obj (dummy : 'dummy Grammar.Entry.e), None,
    [None, None, [[], Gramext.action (fun (loc : Ploc.t) -> (() : 'dummy))]];
    Grammar.Entry.obj (sequence : 'sequence Grammar.Entry.e), None,
    [None, Some Gramext.RightA,
     [[Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action (fun (e : 'expr) (loc : Ploc.t) -> ([e] : 'sequence));
      [Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ";")],
      Gramext.action (fun _ (e : 'expr) (loc : Ploc.t) -> ([e] : 'sequence));
      [Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ";"); Gramext.Sself],
      Gramext.action
        (fun (el : 'sequence) _ (e : 'expr) (loc : Ploc.t) ->
           (e :: el : 'sequence));
      [Gramext.Stoken ("", "let"); Gramext.Stoken ("", "module");
       Gramext.Stoken ("UIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (mod_fun_binding : 'mod_fun_binding Grammar.Entry.e));
       Gramext.Stoken ("", "in"); Gramext.Sself],
      Gramext.action
        (fun (el : 'sequence) _ (mb : 'mod_fun_binding) (m : string) _ _
             (loc : Ploc.t) ->
           ([MLast.ExLmd (loc, m, mb, mksequence loc el)] : 'sequence));
      [Gramext.Stoken ("", "let"); Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false);
       Gramext.Stoken ("", "in"); Gramext.Sself],
      Gramext.action
        (fun (el : 'sequence) _ (l : 'let_binding list) (rf : bool) _
             (loc : Ploc.t) ->
           ([MLast.ExLet (loc, rf, l, mksequence loc el)] : 'sequence))]];
    Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (fun_binding : 'fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'fun_binding) (p : 'ipatt) (loc : Ploc.t) ->
           (p, e : 'let_binding))]];
    Grammar.Entry.obj (fun_binding : 'fun_binding Grammar.Entry.e), None,
    [None, Some Gramext.RightA,
     [[Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.ExTyc (loc, e, t) : 'fun_binding));
      [Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'fun_binding));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (e : 'fun_binding) (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.ExFun (loc, [p, None, e]) : 'fun_binding))]];
    Grammar.Entry.obj (match_case : 'match_case Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (as_patt_opt : 'as_patt_opt Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj (when_expr : 'when_expr Grammar.Entry.e)));
       Gramext.Stoken ("", "->");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (w : 'when_expr option) (aso : 'as_patt_opt)
             (p : 'patt) (loc : Ploc.t) ->
           (mkmatchcase loc p aso w e : 'match_case))]];
    Grammar.Entry.obj (as_patt_opt : 'as_patt_opt Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Ploc.t) -> (None : 'as_patt_opt));
      [Gramext.Stoken ("", "as");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'patt) _ (loc : Ploc.t) -> (Some p : 'as_patt_opt))]];
    Grammar.Entry.obj (when_expr : 'when_expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "when");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'when_expr))]];
    Grammar.Entry.obj (label_expr : 'label_expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (patt_label_ident : 'patt_label_ident Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj (fun_binding : 'fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'fun_binding) (i : 'patt_label_ident) (loc : Ploc.t) ->
           (i, e : 'label_expr))]];
    Grammar.Entry.obj (fun_def : 'fun_def Grammar.Entry.e), None,
    [None, Some Gramext.RightA,
     [[Gramext.Stoken ("", "->");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'fun_def));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (e : 'fun_def) (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.ExFun (loc, [p, None, e]) : 'fun_def))]];
    Grammar.Entry.obj (patt : 'patt Grammar.Entry.e), None,
    [None, Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "|"); Gramext.Sself],
      Gramext.action
        (fun (p2 : 'patt) _ (p1 : 'patt) (loc : Ploc.t) ->
           (MLast.PaOrp (loc, p1, p2) : 'patt))];
     None, Some Gramext.NonA,
     [[Gramext.Sself; Gramext.Stoken ("", ".."); Gramext.Sself],
      Gramext.action
        (fun (p2 : 'patt) _ (p1 : 'patt) (loc : Ploc.t) ->
           (MLast.PaRng (loc, p1, p2) : 'patt))];
     None, Some Gramext.LeftA,
     [[Gramext.Stoken ("", "lazy"); Gramext.Sself],
      Gramext.action
        (fun (p : 'patt) _ (loc : Ploc.t) -> (MLast.PaLaz (loc, p) : 'patt));
      [Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (p2 : 'patt) (p1 : 'patt) (loc : Ploc.t) ->
           (MLast.PaApp (loc, p1, p2) : 'patt))];
     None, Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (p2 : 'patt) _ (p1 : 'patt) (loc : Ploc.t) ->
           (MLast.PaAcc (loc, p1, p2) : 'patt))];
     Some "simple", None,
     [[Gramext.Stoken ("", "_")],
      Gramext.action (fun _ (loc : Ploc.t) -> (MLast.PaAny loc : 'patt));
      [Gramext.Stoken ("", "(");
       Gramext.Snterm
         (Grammar.Entry.obj (paren_patt : 'paren_patt Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (p : 'paren_patt) _ (loc : Ploc.t) -> (p : 'patt));
      [Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (label_patt : 'label_patt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lpl : 'label_patt list) _ (loc : Ploc.t) ->
           (MLast.PaRec (loc, lpl) : 'patt));
      [Gramext.Stoken ("", "[|");
       Gramext.Slist0sep
         (Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "|]")],
      Gramext.action
        (fun _ (pl : 'patt list) _ (loc : Ploc.t) ->
           (MLast.PaArr (loc, pl) : 'patt));
      [Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Snterm
         (Grammar.Entry.obj (cons_patt_opt : 'cons_patt_opt Grammar.Entry.e));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (last : 'cons_patt_opt) (pl : 'patt list) _ (loc : Ploc.t) ->
           (mklistpat loc last pl : 'patt));
      [Gramext.Stoken ("", "["); Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ _ (loc : Ploc.t) -> (MLast.PaUid (loc, "[]") : 'patt));
      [Gramext.Stoken ("", "-"); Gramext.Stoken ("FLOAT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaFlo (loc, neg_string s) : 'patt));
      [Gramext.Stoken ("", "-"); Gramext.Stoken ("INT_n", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaInt (loc, neg_string s, "n") : 'patt));
      [Gramext.Stoken ("", "-"); Gramext.Stoken ("INT_L", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaInt (loc, neg_string s, "L") : 'patt));
      [Gramext.Stoken ("", "-"); Gramext.Stoken ("INT_l", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaInt (loc, neg_string s, "l") : 'patt));
      [Gramext.Stoken ("", "-"); Gramext.Stoken ("INT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaInt (loc, neg_string s, "") : 'patt));
      [Gramext.Stoken ("CHAR", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaChr (loc, s) : 'patt));
      [Gramext.Stoken ("STRING", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaStr (loc, s) : 'patt));
      [Gramext.Stoken ("FLOAT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaFlo (loc, s) : 'patt));
      [Gramext.Stoken ("INT_n", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.PaInt (loc, s, "n") : 'patt));
      [Gramext.Stoken ("INT_L", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.PaInt (loc, s, "L") : 'patt));
      [Gramext.Stoken ("INT_l", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.PaInt (loc, s, "l") : 'patt));
      [Gramext.Stoken ("INT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) ->
           (MLast.PaInt (loc, s, "") : 'patt));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaUid (loc, s) : 'patt));
      [Gramext.Stoken ("GIDENT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaLid (loc, s) : 'patt));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaLid (loc, s) : 'patt))]];
    Grammar.Entry.obj (paren_patt : 'paren_patt Grammar.Entry.e), None,
    [None, None,
     [[],
      Gramext.action
        (fun (loc : Ploc.t) -> (MLast.PaUid (loc, "()") : 'paren_patt));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaUnp (loc, s, None) : 'paren_patt));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("UIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (s : string) _ (loc : Ploc.t) ->
           (MLast.PaUnp (loc, s, Some mt) : 'paren_patt));
      [Gramext.Stoken ("", "type"); Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaNty (loc, s) : 'paren_patt));
      [Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false)],
      Gramext.action
        (fun (pl : 'patt list) (loc : Ploc.t) ->
           (MLast.PaTup (loc, pl) : 'paren_patt));
      [Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action (fun (p : 'patt) (loc : Ploc.t) -> (p : 'paren_patt));
      [Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", ",");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false)],
      Gramext.action
        (fun (pl : 'patt list) _ (p : 'patt) (loc : Ploc.t) ->
           (mktuppat loc p pl : 'paren_patt));
      [Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", "as");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action
        (fun (p2 : 'patt) _ (p : 'patt) (loc : Ploc.t) ->
           (MLast.PaAli (loc, p, p2) : 'paren_patt));
      [Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (p : 'patt) (loc : Ploc.t) ->
           (MLast.PaTyc (loc, p, t) : 'paren_patt))]];
    Grammar.Entry.obj (cons_patt_opt : 'cons_patt_opt Grammar.Entry.e), None,
    [None, None,
     [[], Gramext.action (fun (loc : Ploc.t) -> (None : 'cons_patt_opt));
      [Gramext.Stoken ("", "::");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'patt) _ (loc : Ploc.t) -> (Some p : 'cons_patt_opt))]];
    Grammar.Entry.obj (label_patt : 'label_patt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (patt_label_ident : 'patt_label_ident Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'patt) _ (i : 'patt_label_ident) (loc : Ploc.t) ->
           (i, p : 'label_patt))]];
    Grammar.Entry.obj (patt_label_ident : 'patt_label_ident Grammar.Entry.e),
    None,
    [None, Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (p2 : 'patt_label_ident) _ (p1 : 'patt_label_ident)
             (loc : Ploc.t) ->
           (MLast.PaAcc (loc, p1, p2) : 'patt_label_ident))];
     Some "simple", Some Gramext.RightA,
     [[Gramext.Stoken ("", "_")],
      Gramext.action
        (fun _ (loc : Ploc.t) -> (MLast.PaAny loc : 'patt_label_ident));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.PaLid (loc, i) : 'patt_label_ident));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.PaUid (loc, i) : 'patt_label_ident))]];
    Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "_")],
      Gramext.action (fun _ (loc : Ploc.t) -> (MLast.PaAny loc : 'ipatt));
      [Gramext.Stoken ("GIDENT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaLid (loc, s) : 'ipatt));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (s : string) (loc : Ploc.t) -> (MLast.PaLid (loc, s) : 'ipatt));
      [Gramext.Stoken ("", "(");
       Gramext.Snterm
         (Grammar.Entry.obj (paren_ipatt : 'paren_ipatt Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (p : 'paren_ipatt) _ (loc : Ploc.t) -> (p : 'ipatt));
      [Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (label_ipatt : 'label_ipatt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lpl : 'label_ipatt list) _ (loc : Ploc.t) ->
           (MLast.PaRec (loc, lpl) : 'ipatt))]];
    Grammar.Entry.obj (paren_ipatt : 'paren_ipatt Grammar.Entry.e), None,
    [None, None,
     [[],
      Gramext.action
        (fun (loc : Ploc.t) -> (MLast.PaUid (loc, "()") : 'paren_ipatt));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaUnp (loc, s, None) : 'paren_ipatt));
      [Gramext.Stoken ("", "module"); Gramext.Stoken ("UIDENT", "");
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (s : string) _ (loc : Ploc.t) ->
           (MLast.PaUnp (loc, s, Some mt) : 'paren_ipatt));
      [Gramext.Stoken ("", "type"); Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (s : string) _ (loc : Ploc.t) ->
           (MLast.PaNty (loc, s) : 'paren_ipatt));
      [Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false)],
      Gramext.action
        (fun (pl : 'ipatt list) (loc : Ploc.t) ->
           (MLast.PaTup (loc, pl) : 'paren_ipatt));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e))],
      Gramext.action (fun (p : 'ipatt) (loc : Ploc.t) -> (p : 'paren_ipatt));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Stoken ("", ",");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false)],
      Gramext.action
        (fun (pl : 'ipatt list) _ (p : 'ipatt) (loc : Ploc.t) ->
           (mktuppat loc p pl : 'paren_ipatt));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Stoken ("", "as");
       Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e))],
      Gramext.action
        (fun (p2 : 'ipatt) _ (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.PaAli (loc, p, p2) : 'paren_ipatt));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.PaTyc (loc, p, t) : 'paren_ipatt))]];
    Grammar.Entry.obj (label_ipatt : 'label_ipatt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (patt_label_ident : 'patt_label_ident Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'ipatt) _ (i : 'patt_label_ident) (loc : Ploc.t) ->
           (i, p : 'label_ipatt))]];
    Grammar.Entry.obj (type_decl : 'type_decl Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (type_patt : 'type_patt Grammar.Entry.e));
       Gramext.Slist0
         (Gramext.Snterm
            (Grammar.Entry.obj
               (type_parameter : 'type_parameter Grammar.Entry.e)));
       Gramext.Stoken ("", "=");
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Slist0
         (Gramext.Snterm
            (Grammar.Entry.obj (constrain : 'constrain Grammar.Entry.e)))],
      Gramext.action
        (fun (cl : 'constrain list) (tk : 'ctyp) (pf : bool) _
             (tpl : 'type_parameter list) (n : 'type_patt) (loc : Ploc.t) ->
           ({MLast.tdNam = n; MLast.tdPrm = tpl; MLast.tdPrv = pf;
             MLast.tdDef = tk; MLast.tdCon = cl} :
            'type_decl))]];
    Grammar.Entry.obj (type_patt : 'type_patt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (n : string) (loc : Ploc.t) -> (loc, n : 'type_patt))]];
    Grammar.Entry.obj (constrain : 'constrain Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "constraint");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) _ (loc : Ploc.t) ->
           (t1, t2 : 'constrain))]];
    Grammar.Entry.obj (type_parameter : 'type_parameter Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (simple_type_parameter :
             'simple_type_parameter Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'simple_type_parameter) (loc : Ploc.t) ->
           (p, None : 'type_parameter));
      [Gramext.Stoken ("", "-");
       Gramext.Snterm
         (Grammar.Entry.obj
            (simple_type_parameter :
             'simple_type_parameter Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'simple_type_parameter) _ (loc : Ploc.t) ->
           (p, Some false : 'type_parameter));
      [Gramext.Stoken ("", "+");
       Gramext.Snterm
         (Grammar.Entry.obj
            (simple_type_parameter :
             'simple_type_parameter Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'simple_type_parameter) _ (loc : Ploc.t) ->
           (p, Some true : 'type_parameter))]];
    Grammar.Entry.obj
      (simple_type_parameter : 'simple_type_parameter Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "_")],
      Gramext.action
        (fun _ (loc : Ploc.t) -> (None : 'simple_type_parameter));
      [Gramext.Stoken ("GIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (Some (greek_ascii_equiv i) : 'simple_type_parameter));
      [Gramext.Stoken ("", "'");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'ident) _ (loc : Ploc.t) ->
           (Some i : 'simple_type_parameter))]];
    Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e), None,
    [Some "top", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "==");
       Gramext.Sflag (Gramext.Stoken ("", "private")); Gramext.Sself],
      Gramext.action
        (fun (t2 : 'ctyp) (pf : bool) _ (t1 : 'ctyp) (loc : Ploc.t) ->
           (MLast.TyMan (loc, t1, pf, t2) : 'ctyp))];
     Some "as", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "as"); Gramext.Sself],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) (loc : Ploc.t) ->
           (MLast.TyAli (loc, t1, t2) : 'ctyp))];
     None, Some Gramext.LeftA,
     [[Gramext.Stoken ("", "type");
       Gramext.Slist1 (Gramext.Stoken ("LIDENT", ""));
       Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (t : 'ctyp) _ (pl : string list) _ (loc : Ploc.t) ->
           (MLast.TyPot (loc, pl, t) : 'ctyp));
      [Gramext.Stoken ("", "!");
       Gramext.Slist1
         (Gramext.Snterm
            (Grammar.Entry.obj (typevar : 'typevar Grammar.Entry.e)));
       Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (t : 'ctyp) _ (pl : 'typevar list) _ (loc : Ploc.t) ->
           (MLast.TyPol (loc, pl, t) : 'ctyp))];
     Some "arrow", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "->"); Gramext.Sself],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) (loc : Ploc.t) ->
           (MLast.TyArr (loc, t1, t2) : 'ctyp))];
     Some "apply", Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (t2 : 'ctyp) (t1 : 'ctyp) (loc : Ploc.t) ->
           (MLast.TyApp (loc, t1, t2) : 'ctyp))];
     None, Some Gramext.LeftA,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) (loc : Ploc.t) ->
           (MLast.TyAcc (loc, t1, t2) : 'ctyp))];
     Some "simple", None,
     [[Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (label_declaration : 'label_declaration Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (ldl : 'label_declaration list) _ (loc : Ploc.t) ->
           (MLast.TyRec (loc, ldl) : 'ctyp));
      [Gramext.Stoken ("", "[");
       Gramext.Slist0sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (constructor_declaration :
                'constructor_declaration Grammar.Entry.e)),
          Gramext.Stoken ("", "|"), false);
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (cdl : 'constructor_declaration list) _ (loc : Ploc.t) ->
           (MLast.TySum (loc, cdl) : 'ctyp));
      [Gramext.Stoken ("", "(");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", "*"), false);
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (tl : 'ctyp list) _ (loc : Ploc.t) ->
           (MLast.TyTup (loc, tl) : 'ctyp));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action (fun _ (t : 'ctyp) _ (loc : Ploc.t) -> (t : 'ctyp));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", "*");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", "*"), false);
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (tl : 'ctyp list) _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (mktuptyp loc t tl : 'ctyp));
      [Gramext.Stoken ("", "module");
       Gramext.Snterm
         (Grammar.Entry.obj (module_type : 'module_type Grammar.Entry.e))],
      Gramext.action
        (fun (mt : 'module_type) _ (loc : Ploc.t) ->
           (MLast.TyPck (loc, mt) : 'ctyp));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (MLast.TyUid (loc, i) : 'ctyp));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (MLast.TyLid (loc, i) : 'ctyp));
      [Gramext.Stoken ("", "_")],
      Gramext.action (fun _ (loc : Ploc.t) -> (MLast.TyAny loc : 'ctyp));
      [Gramext.Stoken ("GIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.TyQuo (loc, greek_ascii_equiv i) : 'ctyp));
      [Gramext.Stoken ("", "'");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'ident) _ (loc : Ploc.t) ->
           (MLast.TyQuo (loc, i) : 'ctyp))]];
    Grammar.Entry.obj
      (constructor_declaration : 'constructor_declaration Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (ci : string) (loc : Ploc.t) ->
           (loc, ci, [], None : 'constructor_declaration));
      [Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (ci : string) (loc : Ploc.t) ->
           (let (tl, rt) = generalized_type_of_type t in
            loc, ci, tl, Some rt :
            'constructor_declaration));
      [Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", "of");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (cal : 'ctyp list) _ (ci : string) (loc : Ploc.t) ->
           (loc, ci, cal, None : 'constructor_declaration))]];
    Grammar.Entry.obj
      (label_declaration : 'label_declaration Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Sflag (Gramext.Stoken ("", "mutable"));
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) (mf : bool) _ (i : string) (loc : Ploc.t) ->
           (mklabdecl loc i mf t : 'label_declaration))]];
    Grammar.Entry.obj (ident : 'ident Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (mkident i : 'ident));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (mkident i : 'ident))]];
    Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e), None,
    [None, Some Gramext.RightA,
     [[Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", ".");
       Gramext.Sself],
      Gramext.action
        (fun (j : 'mod_ident) _ (i : string) (loc : Ploc.t) ->
           (mkident i :: j : 'mod_ident));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> ([mkident i] : 'mod_ident));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> ([mkident i] : 'mod_ident))]];
    (* Objects and Classes *)
    Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "class"); Gramext.Stoken ("", "type");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_type_declaration :
                'class_type_declaration Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (ctd : 'class_type_declaration list) _ _ (loc : Ploc.t) ->
           (MLast.StClt (loc, ctd) : 'str_item));
      [Gramext.Stoken ("", "class");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_declaration : 'class_declaration Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (cd : 'class_declaration list) _ (loc : Ploc.t) ->
           (MLast.StCls (loc, cd) : 'str_item))]];
    Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "class"); Gramext.Stoken ("", "type");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_type_declaration :
                'class_type_declaration Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (ctd : 'class_type_declaration list) _ _ (loc : Ploc.t) ->
           (MLast.SgClt (loc, ctd) : 'sig_item));
      [Gramext.Stoken ("", "class");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_description : 'class_description Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (cd : 'class_description list) _ (loc : Ploc.t) ->
           (MLast.SgCls (loc, cd) : 'sig_item))]];
    Grammar.Entry.obj
      (class_declaration : 'class_declaration Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Sflag (Gramext.Stoken ("", "virtual"));
       Gramext.Stoken ("LIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_type_parameters : 'class_type_parameters Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_fun_binding : 'class_fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (cfb : 'class_fun_binding) (ctp : 'class_type_parameters)
             (i : string) (vf : bool) (loc : Ploc.t) ->
           ({MLast.ciLoc = loc; MLast.ciVir = vf; MLast.ciPrm = ctp;
             MLast.ciNam = i; MLast.ciExp = cfb} :
            'class_declaration))]];
    Grammar.Entry.obj
      (class_fun_binding : 'class_fun_binding Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (cfb : 'class_fun_binding) (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.CeFun (loc, p, cfb) : 'class_fun_binding));
      [Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (class_expr : 'class_expr Grammar.Entry.e))],
      Gramext.action
        (fun (ce : 'class_expr) _ (ct : 'class_type) _ (loc : Ploc.t) ->
           (MLast.CeTyc (loc, ce, ct) : 'class_fun_binding));
      [Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (class_expr : 'class_expr Grammar.Entry.e))],
      Gramext.action
        (fun (ce : 'class_expr) _ (loc : Ploc.t) ->
           (ce : 'class_fun_binding))]];
    Grammar.Entry.obj
      (class_type_parameters : 'class_type_parameters Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (type_parameter : 'type_parameter Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (tpl : 'type_parameter list) _ (loc : Ploc.t) ->
           (loc, tpl : 'class_type_parameters));
      [],
      Gramext.action
        (fun (loc : Ploc.t) -> (loc, [] : 'class_type_parameters))]];
    Grammar.Entry.obj (class_fun_def : 'class_fun_def Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "->");
       Gramext.Snterm
         (Grammar.Entry.obj (class_expr : 'class_expr Grammar.Entry.e))],
      Gramext.action
        (fun (ce : 'class_expr) _ (loc : Ploc.t) -> (ce : 'class_fun_def));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (ce : 'class_fun_def) (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.CeFun (loc, p, ce) : 'class_fun_def))]];
    Grammar.Entry.obj (class_expr : 'class_expr Grammar.Entry.e), None,
    [Some "top", None,
     [[Gramext.Stoken ("", "let"); Gramext.Sflag (Gramext.Stoken ("", "rec"));
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (let_binding : 'let_binding Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false);
       Gramext.Stoken ("", "in"); Gramext.Sself],
      Gramext.action
        (fun (ce : 'class_expr) _ (lb : 'let_binding list) (rf : bool) _
             (loc : Ploc.t) ->
           (MLast.CeLet (loc, rf, lb, ce) : 'class_expr));
      [Gramext.Stoken ("", "fun");
       Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_fun_def : 'class_fun_def Grammar.Entry.e))],
      Gramext.action
        (fun (ce : 'class_fun_def) (p : 'ipatt) _ (loc : Ploc.t) ->
           (MLast.CeFun (loc, p, ce) : 'class_expr))];
     Some "apply", Some Gramext.LeftA,
     [[Gramext.Sself;
       Gramext.Snterml
         (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), "label")],
      Gramext.action
        (fun (e : 'expr) (ce : 'class_expr) (loc : Ploc.t) ->
           (MLast.CeApp (loc, ce, e) : 'class_expr))];
     Some "simple", None,
     [[Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (ce : 'class_expr) _ (loc : Ploc.t) -> (ce : 'class_expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (ct : 'class_type) _ (ce : 'class_expr) _ (loc : Ploc.t) ->
           (MLast.CeTyc (loc, ce, ct) : 'class_expr));
      [Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", "]");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_longident : 'class_longident Grammar.Entry.e))],
      Gramext.action
        (fun (ci : 'class_longident) _ (ctcl : 'ctyp list) _ (loc : Ploc.t) ->
           (MLast.CeCon (loc, ci, ctcl) : 'class_expr));
      [Gramext.Stoken ("", "object");
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_self_patt : 'class_self_patt Grammar.Entry.e)));
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_structure : 'class_structure Grammar.Entry.e));
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (cf : 'class_structure) (cspo : 'class_self_patt option) _
             (loc : Ploc.t) ->
           (MLast.CeStr (loc, cspo, cf) : 'class_expr));
      [Gramext.Snterm
         (Grammar.Entry.obj
            (class_longident : 'class_longident Grammar.Entry.e))],
      Gramext.action
        (fun (ci : 'class_longident) (loc : Ploc.t) ->
           (MLast.CeCon (loc, ci, []) : 'class_expr))]];
    Grammar.Entry.obj (class_structure : 'class_structure Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj
                   (class_str_item : 'class_str_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (cf : 'class_str_item) (loc : Ploc.t) ->
                  (cf : 'e__7))])],
      Gramext.action
        (fun (cf : 'e__7 list) (loc : Ploc.t) -> (cf : 'class_structure))]];
    Grammar.Entry.obj (class_self_patt : 'class_self_patt Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "(");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (p : 'patt) _ (loc : Ploc.t) ->
           (MLast.PaTyc (loc, p, t) : 'class_self_patt));
      [Gramext.Stoken ("", "(");
       Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (p : 'patt) _ (loc : Ploc.t) -> (p : 'class_self_patt))]];
    Grammar.Entry.obj (class_str_item : 'class_str_item Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "initializer");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (se : 'expr) _ (loc : Ploc.t) ->
           (MLast.CrIni (loc, se) : 'class_str_item));
      [Gramext.Stoken ("", "type");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.CrCtr (loc, t1, t2) : 'class_str_item));
      [Gramext.Stoken ("", "method");
       Gramext.Sflag (Gramext.Stoken ("", "!"));
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj (polyt : 'polyt Grammar.Entry.e)));
       Gramext.Snterm
         (Grammar.Entry.obj (fun_binding : 'fun_binding Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'fun_binding) (topt : 'polyt option) (l : 'lident)
             (pf : bool) (ovf : bool) _ (loc : Ploc.t) ->
           (MLast.CrMth (loc, ovf, pf, l, topt, e) : 'class_str_item));
      [Gramext.Stoken ("", "method"); Gramext.Stoken ("", "virtual");
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (l : 'lident) (pf : bool) _ _ (loc : Ploc.t) ->
           (MLast.CrVir (loc, pf, l, t) : 'class_str_item));
      [Gramext.Stoken ("", "value"); Gramext.Stoken ("", "virtual");
       Gramext.Sflag (Gramext.Stoken ("", "mutable"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (lab : 'lident) (mf : bool) _ _ (loc : Ploc.t) ->
           (MLast.CrVav (loc, mf, lab, t) : 'class_str_item));
      [Gramext.Stoken ("", "value"); Gramext.Sflag (Gramext.Stoken ("", "!"));
       Gramext.Sflag (Gramext.Stoken ("", "mutable"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Snterm
         (Grammar.Entry.obj
            (cvalue_binding : 'cvalue_binding Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'cvalue_binding) (lab : 'lident) (mf : bool) (ovf : bool) _
             (loc : Ploc.t) ->
           (MLast.CrVal (loc, ovf, mf, lab, e) : 'class_str_item));
      [Gramext.Stoken ("", "inherit");
       Gramext.Snterm
         (Grammar.Entry.obj (class_expr : 'class_expr Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj (as_lident : 'as_lident Grammar.Entry.e)))],
      Gramext.action
        (fun (pb : 'as_lident option) (ce : 'class_expr) _ (loc : Ploc.t) ->
           (MLast.CrInh (loc, ce, pb) : 'class_str_item));
      [Gramext.Stoken ("", "declare");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj
                   (class_str_item : 'class_str_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'class_str_item) (loc : Ploc.t) -> (s : 'e__8))]);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (st : 'e__8 list) _ (loc : Ploc.t) ->
           (MLast.CrDcl (loc, st) : 'class_str_item))]];
    Grammar.Entry.obj (as_lident : 'as_lident Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "as"); Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) _ (loc : Ploc.t) -> (mkident i : 'as_lident))]];
    Grammar.Entry.obj (polyt : 'polyt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action (fun (t : 'ctyp) _ (loc : Ploc.t) -> (t : 'polyt))]];
    Grammar.Entry.obj (cvalue_binding : 'cvalue_binding Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", ":>");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.ExCoe (loc, e, None, t) : 'cvalue_binding));
      [Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ":>");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (t2 : 'ctyp) _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.ExCoe (loc, e, Some t, t2) : 'cvalue_binding));
      [Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.ExTyc (loc, e, t) : 'cvalue_binding));
      [Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'cvalue_binding))]];
    Grammar.Entry.obj (lident : 'lident Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (mkident i : 'lident))]];
    Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e), None,
    [Some "top", Some Gramext.RightA,
     [[Gramext.Sself; Gramext.Stoken ("", "[");
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", ","), false);
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (tl : 'ctyp list) _ (ct : 'class_type) (loc : Ploc.t) ->
           (MLast.CtCon (loc, ct, tl) : 'class_type));
      [Gramext.Stoken ("", "object");
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_self_type : 'class_self_type Grammar.Entry.e)));
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj
                   (class_sig_item : 'class_sig_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (csf : 'class_sig_item) (loc : Ploc.t) ->
                  (csf : 'e__9))]);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (csf : 'e__9 list) (cst : 'class_self_type option) _
             (loc : Ploc.t) ->
           (MLast.CtSig (loc, cst, csf) : 'class_type));
      [Gramext.Stoken ("", "[");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "]"); Gramext.Stoken ("", "->"); Gramext.Sself],
      Gramext.action
        (fun (ct : 'class_type) _ _ (t : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.CtFun (loc, t, ct) : 'class_type))];
     Some "apply", None,
     [[Gramext.Sself; Gramext.Sself],
      Gramext.action
        (fun (ct2 : 'class_type) (ct1 : 'class_type) (loc : Ploc.t) ->
           (MLast.CtApp (loc, ct1, ct2) : 'class_type))];
     Some "dot", None,
     [[Gramext.Sself; Gramext.Stoken ("", "."); Gramext.Sself],
      Gramext.action
        (fun (ct2 : 'class_type) _ (ct1 : 'class_type) (loc : Ploc.t) ->
           (MLast.CtAcc (loc, ct1, ct2) : 'class_type))];
     Some "simple", None,
     [[Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (ct : 'class_type) _ (loc : Ploc.t) -> (ct : 'class_type));
      [Gramext.Stoken ("UIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.CtIde (loc, i) : 'class_type));
      [Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.CtIde (loc, i) : 'class_type))]];
    Grammar.Entry.obj (class_self_type : 'class_self_type Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "(");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (loc : Ploc.t) -> (t : 'class_self_type))]];
    Grammar.Entry.obj (class_sig_item : 'class_sig_item Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "type");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t2 : 'ctyp) _ (t1 : 'ctyp) _ (loc : Ploc.t) ->
           (MLast.CgCtr (loc, t1, t2) : 'class_sig_item));
      [Gramext.Stoken ("", "method");
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (l : 'lident) (pf : bool) _ (loc : Ploc.t) ->
           (MLast.CgMth (loc, pf, l, t) : 'class_sig_item));
      [Gramext.Stoken ("", "method"); Gramext.Stoken ("", "virtual");
       Gramext.Sflag (Gramext.Stoken ("", "private"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (l : 'lident) (pf : bool) _ _ (loc : Ploc.t) ->
           (MLast.CgVir (loc, pf, l, t) : 'class_sig_item));
      [Gramext.Stoken ("", "value");
       Gramext.Sflag (Gramext.Stoken ("", "mutable"));
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (l : 'lident) (mf : bool) _ (loc : Ploc.t) ->
           (MLast.CgVal (loc, mf, l, t) : 'class_sig_item));
      [Gramext.Stoken ("", "inherit");
       Gramext.Snterm
         (Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e))],
      Gramext.action
        (fun (cs : 'class_type) _ (loc : Ploc.t) ->
           (MLast.CgInh (loc, cs) : 'class_sig_item));
      [Gramext.Stoken ("", "declare");
       Gramext.Slist0
         (Gramext.srules
            [[Gramext.Snterm
                (Grammar.Entry.obj
                   (class_sig_item : 'class_sig_item Grammar.Entry.e));
              Gramext.Stoken ("", ";")],
             Gramext.action
               (fun _ (s : 'class_sig_item) (loc : Ploc.t) -> (s : 'e__10))]);
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (st : 'e__10 list) _ (loc : Ploc.t) ->
           (MLast.CgDcl (loc, st) : 'class_sig_item))]];
    Grammar.Entry.obj
      (class_description : 'class_description Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Sflag (Gramext.Stoken ("", "virtual"));
       Gramext.Stoken ("LIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_type_parameters : 'class_type_parameters Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm
         (Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e))],
      Gramext.action
        (fun (ct : 'class_type) _ (ctp : 'class_type_parameters) (n : string)
             (vf : bool) (loc : Ploc.t) ->
           ({MLast.ciLoc = loc; MLast.ciVir = vf; MLast.ciPrm = ctp;
             MLast.ciNam = n; MLast.ciExp = ct} :
            'class_description))]];
    Grammar.Entry.obj
      (class_type_declaration : 'class_type_declaration Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Sflag (Gramext.Stoken ("", "virtual"));
       Gramext.Stoken ("LIDENT", "");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_type_parameters : 'class_type_parameters Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj (class_type : 'class_type Grammar.Entry.e))],
      Gramext.action
        (fun (cs : 'class_type) _ (ctp : 'class_type_parameters) (n : string)
             (vf : bool) (loc : Ploc.t) ->
           ({MLast.ciLoc = loc; MLast.ciVir = vf; MLast.ciPrm = ctp;
             MLast.ciNam = n; MLast.ciExp = cs} :
            'class_type_declaration))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "apply"),
    [None, Some Gramext.LeftA,
     [[Gramext.Stoken ("", "object");
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj
               (class_self_patt : 'class_self_patt Grammar.Entry.e)));
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_structure : 'class_structure Grammar.Entry.e));
       Gramext.Stoken ("", "end")],
      Gramext.action
        (fun _ (cf : 'class_structure) (cspo : 'class_self_patt option) _
             (loc : Ploc.t) ->
           (MLast.ExObj (loc, cspo, cf) : 'expr));
      [Gramext.Stoken ("", "new");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_longident : 'class_longident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'class_longident) _ (loc : Ploc.t) ->
           (MLast.ExNew (loc, i) : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "."),
    [None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "#");
       Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e))],
      Gramext.action
        (fun (lab : 'lident) _ (e : 'expr) (loc : Ploc.t) ->
           (MLast.ExSnd (loc, e, lab) : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("", "{<");
       Gramext.Slist0sep
         (Gramext.Snterm
            (Grammar.Entry.obj (field_expr : 'field_expr Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", ">}")],
      Gramext.action
        (fun _ (fel : 'field_expr list) _ (loc : Ploc.t) ->
           (MLast.ExOvr (loc, fel) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ":>");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExCoe (loc, e, None, t) : 'expr));
      [Gramext.Stoken ("", "("); Gramext.Sself; Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ":>");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t2 : 'ctyp) _ (t : 'ctyp) _ (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExCoe (loc, e, Some t, t2) : 'expr))]];
    Grammar.Entry.obj (field_expr : 'field_expr Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (lident : 'lident Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (l : 'lident) (loc : Ploc.t) ->
           (l, e : 'field_expr))]];
    Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("", "<");
       Gramext.Slist0sep
         (Gramext.Snterm (Grammar.Entry.obj (field : 'field Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Sflag (Gramext.Stoken ("", "..")); Gramext.Stoken ("", ">")],
      Gramext.action
        (fun _ (v : bool) (ml : 'field list) _ (loc : Ploc.t) ->
           (MLast.TyObj (loc, ml, v) : 'ctyp));
      [Gramext.Stoken ("", "#");
       Gramext.Snterm
         (Grammar.Entry.obj
            (class_longident : 'class_longident Grammar.Entry.e))],
      Gramext.action
        (fun (id : 'class_longident) _ (loc : Ploc.t) ->
           (MLast.TyCls (loc, id) : 'ctyp))]];
    Grammar.Entry.obj (field : 'field Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (lab : string) (loc : Ploc.t) ->
           (mkident lab, t : 'field))]];
    Grammar.Entry.obj (typevar : 'typevar Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "'");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action (fun (i : 'ident) _ (loc : Ploc.t) -> (i : 'typevar))]];
    Grammar.Entry.obj (class_longident : 'class_longident Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> ([mkident i] : 'class_longident));
      [Gramext.Stoken ("UIDENT", ""); Gramext.Stoken ("", ".");
       Gramext.Sself],
      Gramext.action
        (fun (l : 'class_longident) _ (m : string) (loc : Ploc.t) ->
           (mkident m :: l : 'class_longident))]];
    (* Labels *)
    Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e),
    Some (Gramext.After "arrow"),
    [None, Some Gramext.NonA,
     [[Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (t : 'ctyp) (i : string) (loc : Ploc.t) ->
           (MLast.TyOlb (loc, i, t) : 'ctyp));
      [Gramext.Stoken ("TILDEIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (t : 'ctyp) (i : string) (loc : Ploc.t) ->
           (MLast.TyLab (loc, i, t) : 'ctyp))]];
    Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("", "["); Gramext.Stoken ("", "<");
       Gramext.Snterm
         (Grammar.Entry.obj
            (poly_variant_list : 'poly_variant_list Grammar.Entry.e));
       Gramext.Stoken ("", ">");
       Gramext.Slist1
         (Gramext.Snterm
            (Grammar.Entry.obj (name_tag : 'name_tag Grammar.Entry.e)));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (ntl : 'name_tag list) _ (rfl : 'poly_variant_list) _ _
             (loc : Ploc.t) ->
           (MLast.TyVrn (loc, rfl, Some (Some ntl)) : 'ctyp));
      [Gramext.Stoken ("", "["); Gramext.Stoken ("", "<");
       Gramext.Snterm
         (Grammar.Entry.obj
            (poly_variant_list : 'poly_variant_list Grammar.Entry.e));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (rfl : 'poly_variant_list) _ _ (loc : Ploc.t) ->
           (MLast.TyVrn (loc, rfl, Some (Some [])) : 'ctyp));
      [Gramext.Stoken ("", "["); Gramext.Stoken ("", ">");
       Gramext.Snterm
         (Grammar.Entry.obj
            (poly_variant_list : 'poly_variant_list Grammar.Entry.e));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (rfl : 'poly_variant_list) _ _ (loc : Ploc.t) ->
           (MLast.TyVrn (loc, rfl, Some None) : 'ctyp));
      [Gramext.Stoken ("", "["); Gramext.Stoken ("", "=");
       Gramext.Snterm
         (Grammar.Entry.obj
            (poly_variant_list : 'poly_variant_list Grammar.Entry.e));
       Gramext.Stoken ("", "]")],
      Gramext.action
        (fun _ (rfl : 'poly_variant_list) _ _ (loc : Ploc.t) ->
           (MLast.TyVrn (loc, rfl, None) : 'ctyp))]];
    Grammar.Entry.obj
      (poly_variant_list : 'poly_variant_list Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Slist0sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (poly_variant : 'poly_variant Grammar.Entry.e)),
          Gramext.Stoken ("", "|"), false)],
      Gramext.action
        (fun (rfl : 'poly_variant list) (loc : Ploc.t) ->
           (rfl : 'poly_variant_list))]];
    Grammar.Entry.obj (poly_variant : 'poly_variant Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) (loc : Ploc.t) ->
           (MLast.PvInh (loc, t) : 'poly_variant));
      [Gramext.Stoken ("", "`");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e));
       Gramext.Stoken ("", "of"); Gramext.Sflag (Gramext.Stoken ("", "&"));
       Gramext.Slist1sep
         (Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e)),
          Gramext.Stoken ("", "&"), false)],
      Gramext.action
        (fun (l : 'ctyp list) (ao : bool) _ (i : 'ident) _ (loc : Ploc.t) ->
           (MLast.PvTag (loc, i, ao, l) : 'poly_variant));
      [Gramext.Stoken ("", "`");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (i : 'ident) _ (loc : Ploc.t) ->
           (MLast.PvTag (loc, i, true, []) : 'poly_variant))]];
    Grammar.Entry.obj (name_tag : 'name_tag Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("", "`");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action (fun (i : 'ident) _ (loc : Ploc.t) -> (i : 'name_tag))]];
    Grammar.Entry.obj (patt : 'patt Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (patt_option_label : 'patt_option_label Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'patt_option_label) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in p : 'patt));
      [Gramext.Stoken ("TILDEIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.PaLab (loc, [MLast.PaLid (loc, i), None]) :
            'patt));
      [Gramext.Stoken ("TILDEIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (p : 'patt) (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.PaLab (loc, [MLast.PaLid (loc, i), Some p]) :
            'patt));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (patt_tcon : 'patt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.srules
            [[Gramext.Stoken ("", "=");
              Gramext.Snterm
                (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
             Gramext.action
               (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'e__11))]);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (eo : 'e__11 option) (p : 'patt_tcon) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb (loc, p, eo) : 'patt));
      [Gramext.Stoken ("", "~"); Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (patt_tcon_opt_eq_patt :
                'patt_tcon_opt_eq_patt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lppo : 'patt_tcon_opt_eq_patt list) _ _ (loc : Ploc.t) ->
           (MLast.PaLab (loc, lppo) : 'patt));
      [Gramext.Stoken ("", "#");
       Gramext.Snterm
         (Grammar.Entry.obj (mod_ident : 'mod_ident Grammar.Entry.e))],
      Gramext.action
        (fun (sl : 'mod_ident) _ (loc : Ploc.t) ->
           (MLast.PaTyp (loc, sl) : 'patt));
      [Gramext.Stoken ("", "`");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (s : 'ident) _ (loc : Ploc.t) ->
           (MLast.PaVrn (loc, s) : 'patt))]];
    Grammar.Entry.obj
      (patt_tcon_opt_eq_patt : 'patt_tcon_opt_eq_patt Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (patt_tcon : 'patt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.srules
            [[Gramext.Stoken ("", "=");
              Gramext.Snterm
                (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
             Gramext.action
               (fun (p : 'patt) _ (loc : Ploc.t) -> (p : 'e__12))])],
      Gramext.action
        (fun (po : 'e__12 option) (p : 'patt_tcon) (loc : Ploc.t) ->
           (p, po : 'patt_tcon_opt_eq_patt))]];
    Grammar.Entry.obj (patt_tcon : 'patt_tcon Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (p : 'patt) (loc : Ploc.t) ->
           (MLast.PaTyc (loc, p, t) : 'patt_tcon));
      [Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
      Gramext.action (fun (p : 'patt) (loc : Ploc.t) -> (p : 'patt_tcon))]];
    Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj
            (patt_option_label : 'patt_option_label Grammar.Entry.e))],
      Gramext.action
        (fun (p : 'patt_option_label) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in p : 'ipatt));
      [Gramext.Stoken ("TILDEIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.PaLab (loc, [MLast.PaLid (loc, i), None]) :
            'ipatt));
      [Gramext.Stoken ("TILDEIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (p : 'ipatt) (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.PaLab (loc, [MLast.PaLid (loc, i), Some p]) :
            'ipatt));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (ipatt_tcon : 'ipatt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.srules
            [[Gramext.Stoken ("", "=");
              Gramext.Snterm
                (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
             Gramext.action
               (fun (e : 'expr) _ (loc : Ploc.t) -> (e : 'e__13))]);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (eo : 'e__13 option) (p : 'ipatt_tcon) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb (loc, p, eo) : 'ipatt));
      [Gramext.Stoken ("", "~"); Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (ipatt_tcon_opt_eq_patt :
                'ipatt_tcon_opt_eq_patt Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lppo : 'ipatt_tcon_opt_eq_patt list) _ _ (loc : Ploc.t) ->
           (MLast.PaLab (loc, lppo) : 'ipatt))]];
    Grammar.Entry.obj
      (ipatt_tcon_opt_eq_patt : 'ipatt_tcon_opt_eq_patt Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (ipatt_tcon : 'ipatt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.srules
            [[Gramext.Stoken ("", "=");
              Gramext.Snterm
                (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e))],
             Gramext.action
               (fun (p : 'patt) _ (loc : Ploc.t) -> (p : 'e__14))])],
      Gramext.action
        (fun (po : 'e__14 option) (p : 'ipatt_tcon) (loc : Ploc.t) ->
           (p, po : 'ipatt_tcon_opt_eq_patt))]];
    Grammar.Entry.obj (ipatt_tcon : 'ipatt_tcon Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e));
       Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e))],
      Gramext.action
        (fun (t : 'ctyp) _ (p : 'ipatt) (loc : Ploc.t) ->
           (MLast.PaTyc (loc, p, t) : 'ipatt_tcon));
      [Gramext.Snterm (Grammar.Entry.obj (ipatt : 'ipatt Grammar.Entry.e))],
      Gramext.action (fun (p : 'ipatt) (loc : Ploc.t) -> (p : 'ipatt_tcon))]];
    Grammar.Entry.obj
      (patt_option_label : 'patt_option_label Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "?"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (i : string) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb (loc, MLast.PaLid (loc, i), None) :
            'patt_option_label));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ (i : string) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb (loc, MLast.PaLid (loc, i), Some e) :
            'patt_option_label));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (i : string) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaTyc (loc, MLast.PaLid (loc, i), t), None) :
            'patt_option_label));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ (t : 'ctyp) _ (i : string) _ _ (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaTyc (loc, MLast.PaLid (loc, i), t), Some e) :
            'patt_option_label));
      [Gramext.Stoken ("QUESTIONIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (MLast.PaOlb (loc, MLast.PaLid (loc, i), None) :
            'patt_option_label));
      [Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (j : string) _ (i : string) (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaLid (loc, i), Some (MLast.ExLid (loc, j))) :
            'patt_option_label));
      [Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ (j : string) _ (i : string) (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaLid (loc, i),
               Some (MLast.ExOlb (loc, MLast.PaLid (loc, j), Some e))) :
            'patt_option_label));
      [Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (t : 'ctyp) _ (j : string) _ (i : string) (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaTyc (loc, MLast.PaLid (loc, i), t),
               Some (MLast.ExOlb (loc, MLast.PaLid (loc, j), None))) :
            'patt_option_label));
      [Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Stoken ("", "(");
       Gramext.Stoken ("LIDENT", ""); Gramext.Stoken ("", ":");
       Gramext.Snterm (Grammar.Entry.obj (ctyp : 'ctyp Grammar.Entry.e));
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (e : 'expr) _ (t : 'ctyp) _ (j : string) _ (i : string)
             (loc : Ploc.t) ->
           (MLast.PaOlb
              (loc, MLast.PaTyc (loc, MLast.PaLid (loc, i), t),
               Some (MLast.ExOlb (loc, MLast.PaLid (loc, j), Some e))) :
            'patt_option_label))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.After "apply"),
    [Some "label", Some Gramext.NonA,
     [[Gramext.Stoken ("QUESTIONIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.ExOlb (loc, MLast.PaLid (loc, i), None) :
            'expr));
      [Gramext.Stoken ("QUESTIONIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.ExOlb (loc, MLast.PaLid (loc, i), Some e) :
            'expr));
      [Gramext.Stoken ("TILDEIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.ExLab (loc, [MLast.PaLid (loc, i), None]) :
            'expr));
      [Gramext.Stoken ("TILDEIDENTCOLON", ""); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) (i : string) (loc : Ploc.t) ->
           (let _ = warning_deprecated_since_6_00 loc in
            MLast.ExLab (loc, [MLast.PaLid (loc, i), Some e]) :
            'expr));
      [Gramext.Stoken ("", "?"); Gramext.Stoken ("", "{");
       Gramext.Snterm
         (Grammar.Entry.obj (ipatt_tcon : 'ipatt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj (fun_binding : 'fun_binding Grammar.Entry.e)));
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (eo : 'fun_binding option) (p : 'ipatt_tcon) _ _
             (loc : Ploc.t) ->
           (MLast.ExOlb (loc, p, eo) : 'expr));
      [Gramext.Stoken ("", "~"); Gramext.Stoken ("", "{");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (ipatt_tcon_fun_binding :
                'ipatt_tcon_fun_binding Grammar.Entry.e)),
          Gramext.Stoken ("", ";"), false);
       Gramext.Stoken ("", "}")],
      Gramext.action
        (fun _ (lpeo : 'ipatt_tcon_fun_binding list) _ _ (loc : Ploc.t) ->
           (MLast.ExLab (loc, lpeo) : 'expr))]];
    Grammar.Entry.obj
      (ipatt_tcon_fun_binding : 'ipatt_tcon_fun_binding Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (ipatt_tcon : 'ipatt_tcon Grammar.Entry.e));
       Gramext.Sopt
         (Gramext.Snterm
            (Grammar.Entry.obj
               (fun_binding : 'fun_binding Grammar.Entry.e)))],
      Gramext.action
        (fun (eo : 'fun_binding option) (p : 'ipatt_tcon) (loc : Ploc.t) ->
           (p, eo : 'ipatt_tcon_fun_binding))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("", "`");
       Gramext.Snterm (Grammar.Entry.obj (ident : 'ident Grammar.Entry.e))],
      Gramext.action
        (fun (s : 'ident) _ (loc : Ploc.t) ->
           (MLast.ExVrn (loc, s) : 'expr))]];
    Grammar.Entry.obj (direction_flag : 'direction_flag Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "downto")],
      Gramext.action (fun _ (loc : Ploc.t) -> (false : 'direction_flag));
      [Gramext.Stoken ("", "to")],
      Gramext.action (fun _ (loc : Ploc.t) -> (true : 'direction_flag))]];
    (* -- cut 1 begin -- *)
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), None,
    [None, None, []]]);;

Grammar.extend
  (let _ = (str_item : 'str_item Grammar.Entry.e)
   and _ = (expr : 'expr Grammar.Entry.e) in
   let grammar_entry_create s =
     Grammar.create_local_entry (Grammar.of_entry str_item) s
   in
   let joinautomaton : 'joinautomaton Grammar.Entry.e =
     grammar_entry_create "joinautomaton"
   and joinclause : 'joinclause Grammar.Entry.e =
     grammar_entry_create "joinclause"
   and joinpattern : 'joinpattern Grammar.Entry.e =
     grammar_entry_create "joinpattern"
   and joinident : 'joinident Grammar.Entry.e =
     grammar_entry_create "joinident"
   in
   [(* -- cut 1 end -- *)
    Grammar.
    Entry.
    obj
      (str_item : 'str_item Grammar.Entry.e),
    None,
    [None, None,
     [[Gramext.Stoken ("", "def");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (joinautomaton : 'joinautomaton Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false)],
      Gramext.action
        (fun (jal : 'joinautomaton list) _ (loc : Ploc.t) ->
           (MLast.StDef (loc, jal) : 'str_item))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "top"),
    [None, None,
     [[Gramext.Stoken ("", "def");
       Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj
               (joinautomaton : 'joinautomaton Grammar.Entry.e)),
          Gramext.Stoken ("", "and"), false);
       Gramext.Stoken ("", "in");
       Gramext.Snterml
         (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), "top")],
      Gramext.action
        (fun (e : 'expr) _ (jal : 'joinautomaton list) _ (loc : Ploc.t) ->
           (MLast.ExJdf (loc, jal, e) : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "apply"),
    [None, None,
     [[Gramext.Stoken ("", "reply");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)));
       Gramext.Stoken ("", "to");
       Gramext.Snterm
         (Grammar.Entry.obj (joinident : 'joinident Grammar.Entry.e))],
      Gramext.action
        (fun (ji : 'joinident) _ (eo : 'expr option) _ (loc : Ploc.t) ->
           (MLast.ExRpl (loc, eo, ji) : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Before ":="),
    [None, None,
     [[Gramext.Stoken ("", "spawn"); Gramext.Sself],
      Gramext.action
        (fun (e : 'expr) _ (loc : Ploc.t) ->
           (MLast.ExSpw (loc, e) : 'expr))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "&&"),
    [None, None,
     [[Gramext.Sself; Gramext.Stoken ("", "&"); Gramext.Sself],
      Gramext.action
        (fun (e2 : 'expr) _ (e1 : 'expr) (loc : Ploc.t) ->
           (MLast.ExPar (loc, e1, e2) : 'expr))]];
    Grammar.Entry.obj (joinautomaton : 'joinautomaton Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (joinclause : 'joinclause Grammar.Entry.e)),
          Gramext.Stoken ("", "or"), false)],
      Gramext.action
        (fun (jcl : 'joinclause list) (loc : Ploc.t) ->
           ({MLast.jcLoc = loc; MLast.jcVal = jcl} : 'joinautomaton))]];
    Grammar.Entry.obj (joinclause : 'joinclause Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Slist1sep
         (Gramext.Snterm
            (Grammar.Entry.obj (joinpattern : 'joinpattern Grammar.Entry.e)),
          Gramext.Stoken ("", "&"), false);
       Gramext.Stoken ("", "=");
       Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e))],
      Gramext.action
        (fun (e : 'expr) _ (jpl : 'joinpattern list) (loc : Ploc.t) ->
           (loc, jpl, e : 'joinclause))]];
    Grammar.Entry.obj (joinpattern : 'joinpattern Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (joinident : 'joinident Grammar.Entry.e));
       Gramext.Stoken ("", "(");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (patt : 'patt Grammar.Entry.e)));
       Gramext.Stoken ("", ")")],
      Gramext.action
        (fun _ (op : 'patt option) _ (ji : 'joinident) (loc : Ploc.t) ->
           (loc, ji, op : 'joinpattern))]];
    Grammar.Entry.obj (joinident : 'joinident Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("LIDENT", "")],
      Gramext.action
        (fun (i : string) (loc : Ploc.t) -> (loc, i : 'joinident))]];
    (* -- cut 2 begin -- *)
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e), None,
    [None, None, []]]);;

(* -- cut 2 end -- *)
(* -- end copy from pa_r to q_MLast -- *)

let quotation_content s =
  let rec loop i =
    if i = String.length s then "", s
    else if s.[i] = ':' || s.[i] = '@' then
      let i = i + 1 in String.sub s 0 i, String.sub s i (String.length s - i)
    else loop (i + 1)
  in
  loop 0
;;

Grammar.extend
  (let _ = (interf : 'interf Grammar.Entry.e)
   and _ = (implem : 'implem Grammar.Entry.e)
   and _ = (use_file : 'use_file Grammar.Entry.e)
   and _ = (top_phrase : 'top_phrase Grammar.Entry.e)
   and _ = (expr : 'expr Grammar.Entry.e)
   and _ = (patt : 'patt Grammar.Entry.e) in
   let grammar_entry_create s =
     Grammar.create_local_entry (Grammar.of_entry interf) s
   in
   let sig_item_semi : 'sig_item_semi Grammar.Entry.e =
     grammar_entry_create "sig_item_semi"
   and str_item_semi : 'str_item_semi Grammar.Entry.e =
     grammar_entry_create "str_item_semi"
   and phrase : 'phrase Grammar.Entry.e = grammar_entry_create "phrase" in
   [Grammar.Entry.obj (interf : 'interf Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("EOI", "")],
      Gramext.action (fun _ (loc : Ploc.t) -> ([], Some loc : 'interf));
      [Gramext.Snterm
         (Grammar.Entry.obj (sig_item_semi : 'sig_item_semi Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (sil, stopped : 'interf) (si : 'sig_item_semi) (loc : Ploc.t) ->
           (si :: sil, stopped : 'interf));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           ([MLast.SgDir (loc, n, dp), loc], None : 'interf))]];
    Grammar.Entry.obj (sig_item_semi : 'sig_item_semi Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (sig_item : 'sig_item Grammar.Entry.e));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (si : 'sig_item) (loc : Ploc.t) ->
           (si, loc : 'sig_item_semi))]];
    Grammar.Entry.obj (implem : 'implem Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("EOI", "")],
      Gramext.action (fun _ (loc : Ploc.t) -> ([], Some loc : 'implem));
      [Gramext.Snterm
         (Grammar.Entry.obj (str_item_semi : 'str_item_semi Grammar.Entry.e));
       Gramext.Sself],
      Gramext.action
        (fun (sil, stopped : 'implem) (si : 'str_item_semi) (loc : Ploc.t) ->
           (si :: sil, stopped : 'implem));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           ([MLast.StDir (loc, n, dp), loc], None : 'implem))]];
    Grammar.Entry.obj (str_item_semi : 'str_item_semi Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (si : 'str_item) (loc : Ploc.t) ->
           (si, loc : 'str_item_semi))]];
    Grammar.Entry.obj (top_phrase : 'top_phrase Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("EOI", "")],
      Gramext.action (fun _ (loc : Ploc.t) -> (None : 'top_phrase));
      [Gramext.Snterm (Grammar.Entry.obj (phrase : 'phrase Grammar.Entry.e))],
      Gramext.action
        (fun (ph : 'phrase) (loc : Ploc.t) -> (Some ph : 'top_phrase))]];
    Grammar.Entry.obj (use_file : 'use_file Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Stoken ("EOI", "")],
      Gramext.action (fun _ (loc : Ploc.t) -> ([], false : 'use_file));
      [Gramext.Snterm
         (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e));
       Gramext.Stoken ("", ";"); Gramext.Sself],
      Gramext.action
        (fun (sil, stopped : 'use_file) _ (si : 'str_item) (loc : Ploc.t) ->
           (si :: sil, stopped : 'use_file));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           ([MLast.StDir (loc, n, dp)], true : 'use_file))]];
    Grammar.Entry.obj (phrase : 'phrase Grammar.Entry.e), None,
    [None, None,
     [[Gramext.Snterm
         (Grammar.Entry.obj (str_item : 'str_item Grammar.Entry.e));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (sti : 'str_item) (loc : Ploc.t) -> (sti : 'phrase));
      [Gramext.Stoken ("", "#"); Gramext.Stoken ("LIDENT", "");
       Gramext.Sopt
         (Gramext.Snterm (Grammar.Entry.obj (expr : 'expr Grammar.Entry.e)));
       Gramext.Stoken ("", ";")],
      Gramext.action
        (fun _ (dp : 'expr option) (n : string) _ (loc : Ploc.t) ->
           (MLast.StDir (loc, n, dp) : 'phrase))]];
    Grammar.Entry.obj (expr : 'expr Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("QUOTATION", "")],
      Gramext.action
        (fun (x : string) (loc : Ploc.t) ->
           (let con = quotation_content x in
            Pcaml.handle_expr_quotation loc con :
            'expr))]];
    Grammar.Entry.obj (patt : 'patt Grammar.Entry.e),
    Some (Gramext.Level "simple"),
    [None, None,
     [[Gramext.Stoken ("QUOTATION", "")],
      Gramext.action
        (fun (x : string) (loc : Ploc.t) ->
           (let con = quotation_content x in
            Pcaml.handle_patt_quotation loc con :
            'patt))]]]);;
