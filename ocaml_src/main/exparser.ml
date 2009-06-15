(* camlp5r q_MLast.cmo *)
(***********************************************************************)
(*                                                                     *)
(*                             Camlp5                                  *)
(*                                                                     *)
(*                Daniel de Rauglaudre, INRIA Rocquencourt             *)
(*                                                                     *)
(*  Copyright 2007 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

(* This file has been generated by program: do not edit! *)

type spat_comp =
    SpTrm of MLast.loc * MLast.patt * MLast.expr option
  | SpNtr of MLast.loc * MLast.patt * MLast.expr
  | SpLet of MLast.loc * MLast.patt * MLast.expr
  | SpLhd of MLast.loc * MLast.patt list list
  | SpStr of MLast.loc * MLast.patt
;;
type sexp_comp =
    SeTrm of MLast.loc * MLast.expr
  | SeNtr of MLast.loc * MLast.expr
;;

type spat_comp_opt =
    SpoNoth
  | SpoBang
  | SpoQues of MLast.expr
;;

let strm_n = "strm__";;
let peek_fun loc =
  MLast.ExAcc (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "peek"))
;;
let junk_fun loc =
  MLast.ExAcc (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "junk"))
;;

(* Parsers *)

let rec pattern_eq_expression p e =
  match p, e with
    MLast.PaLid (_, a), MLast.ExLid (_, b) -> a = b
  | MLast.PaUid (_, a), MLast.ExUid (_, b) -> a = b
  | MLast.PaApp (_, p1, p2), MLast.ExApp (_, e1, e2) ->
      pattern_eq_expression p1 e1 && pattern_eq_expression p2 e2
  | _ -> false
;;

let is_raise e =
  match e with
    MLast.ExApp (_, MLast.ExLid (_, "raise"), _) -> true
  | _ -> false
;;

let is_raise_failure e =
  match e with
    MLast.ExApp
      (_, MLast.ExLid (_, "raise"),
       MLast.ExAcc
         (_, MLast.ExUid (_, "Stream"), MLast.ExUid (_, "Failure"))) ->
      true
  | _ -> false
;;

let rec handle_failure e =
  match e with
    MLast.ExTry
      (_, te,
       [MLast.PaAcc
          (_, MLast.PaUid (_, "Stream"), MLast.PaUid (_, "Failure")),
        None, e]) ->
      handle_failure e
  | MLast.ExMat (_, me, pel) ->
      handle_failure me &&
      List.for_all
        (function
           _, None, e -> handle_failure e
         | _ -> false)
        pel
  | MLast.ExLet (_, false, pel, e) ->
      List.for_all (fun (p, e) -> handle_failure e) pel && handle_failure e
  | MLast.ExSeq (_, el) -> List.for_all handle_failure el
  | MLast.ExAcc (_, MLast.ExUid (_, _), _) | MLast.ExLid (_, _) |
    MLast.ExInt (_, _, "") | MLast.ExStr (_, _) | MLast.ExChr (_, _) |
    MLast.ExFun (_, _) | MLast.ExUid (_, _) ->
      true
  | MLast.ExApp (_, MLast.ExLid (_, "raise"), e) ->
      begin match e with
        MLast.ExAcc
          (_, MLast.ExUid (_, "Stream"), MLast.ExUid (_, "Failure")) ->
          false
      | _ -> true
      end
  | MLast.ExApp (_, f, x) ->
      no_raising_failure_fun f && handle_failure f && handle_failure x
  | _ -> false
and no_raising_failure_fun =
  function
    MLast.ExUid (_, _) -> true
  | MLast.ExLid (_, _) -> false
  | MLast.ExAcc (_, MLast.ExUid (_, "Stream"), MLast.ExLid (_, "peek")) |
    MLast.ExAcc (_, MLast.ExUid (_, "Stream"), MLast.ExLid (_, "junk")) ->
      true
  | MLast.ExApp (_, x, y) -> no_raising_failure_fun x && handle_failure y
  | _ -> false
;;

let rec subst v e =
  let loc = MLast.loc_of_expr e in
  match e with
    MLast.ExLid (_, x) ->
      let x = if x = v then strm_n else x in MLast.ExLid (loc, x)
  | MLast.ExUid (_, _) -> e
  | MLast.ExInt (_, _, "") -> e
  | MLast.ExChr (_, _) -> e
  | MLast.ExStr (_, _) -> e
  | MLast.ExAcc (_, _, _) -> e
  | MLast.ExLet (_, rf, pel, e) ->
      MLast.ExLet (loc, rf, List.map (subst_pe v) pel, subst v e)
  | MLast.ExApp (_, e1, e2) -> MLast.ExApp (loc, subst v e1, subst v e2)
  | MLast.ExTup (_, el) -> MLast.ExTup (loc, List.map (subst v) el)
  | _ -> raise Not_found
and subst_pe v (p, e) =
  match p with
    MLast.PaLid (_, v') when v <> v' -> p, subst v e
  | _ -> raise Not_found
;;

let optim = ref true;;

let stream_pattern_component skont ckont =
  function
    SpTrm (loc, p, wo) ->
      MLast.ExMat
        (loc, MLast.ExApp (loc, peek_fun loc, MLast.ExLid (loc, strm_n)),
         [MLast.PaApp (loc, MLast.PaUid (loc, "Some"), p), wo,
          MLast.ExSeq
            (loc,
             [MLast.ExApp (loc, junk_fun loc, MLast.ExLid (loc, strm_n));
              skont]);
          MLast.PaAny loc, None, ckont])
  | SpNtr (loc, p, e) ->
      let e =
        match e with
          MLast.ExFun
            (_,
             [MLast.PaTyc
                (_, MLast.PaLid (_, v),
                 MLast.TyApp
                   (_,
                    MLast.TyAcc
                      (_, MLast.TyUid (_, "Stream"), MLast.TyLid (_, "t")),
                    MLast.TyAny _)),
              None, e])
          when v = strm_n ->
            e
        | _ -> MLast.ExApp (loc, e, MLast.ExLid (loc, strm_n))
      in
      if !optim then
        if pattern_eq_expression p skont then
          if is_raise_failure ckont then e
          else if handle_failure e then e
          else
            MLast.ExTry
              (loc, e,
               [MLast.PaAcc
                  (loc, MLast.PaUid (loc, "Stream"),
                   MLast.PaUid (loc, "Failure")),
                None, ckont])
        else if is_raise_failure ckont then
          MLast.ExLet (loc, false, [p, e], skont)
        else if
          pattern_eq_expression
            (MLast.PaApp (loc, MLast.PaUid (loc, "Some"), p)) skont
        then
          MLast.ExTry
            (loc, MLast.ExApp (loc, MLast.ExUid (loc, "Some"), e),
             [MLast.PaAcc
                (loc, MLast.PaUid (loc, "Stream"),
                 MLast.PaUid (loc, "Failure")),
              None, ckont])
        else if is_raise ckont then
          let tst =
            if handle_failure e then e
            else
              MLast.ExTry
                (loc, e,
                 [MLast.PaAcc
                    (loc, MLast.PaUid (loc, "Stream"),
                     MLast.PaUid (loc, "Failure")),
                  None, ckont])
          in
          MLast.ExLet (loc, false, [p, tst], skont)
        else
          MLast.ExMat
            (loc,
             MLast.ExTry
               (loc, MLast.ExApp (loc, MLast.ExUid (loc, "Some"), e),
                [MLast.PaAcc
                   (loc, MLast.PaUid (loc, "Stream"),
                    MLast.PaUid (loc, "Failure")),
                 None, MLast.ExUid (loc, "None")]),
             [MLast.PaApp (loc, MLast.PaUid (loc, "Some"), p), None, skont;
              MLast.PaAny loc, None, ckont])
      else
        MLast.ExMat
          (loc,
           MLast.ExTry
             (loc, MLast.ExApp (loc, MLast.ExUid (loc, "Some"), e),
              [MLast.PaAcc
                 (loc, MLast.PaUid (loc, "Stream"),
                  MLast.PaUid (loc, "Failure")),
               None, MLast.ExUid (loc, "None")]),
           [MLast.PaApp (loc, MLast.PaUid (loc, "Some"), p), None, skont;
            MLast.PaAny loc, None, ckont])
  | SpLet (_, _, _) -> assert false
  | SpLhd (loc, pl :: pll) ->
      let mklistpat loc pl =
        List.fold_right
          (fun p1 p2 ->
             MLast.PaApp
               (loc, MLast.PaApp (loc, MLast.PaUid (loc, "::"), p1), p2))
          pl (MLast.PaUid (loc, "[]"))
      in
      let len = List.length pl in
      if List.exists (fun pl -> List.length pl <> len) pll then
        Stdpp.raise_with_loc loc
          (Stream.Error "lookahead patterns must be of the same lengths")
      else
        let p =
          let p = mklistpat loc pl in
          let pl = List.map (mklistpat loc) pll in
          List.fold_left (fun p1 p2 -> MLast.PaOrp (loc, p1, p2)) p pl
        in
        MLast.ExMat
          (loc,
           MLast.ExApp
             (loc,
              MLast.ExApp
                (loc,
                 MLast.ExAcc
                   (loc, MLast.ExUid (loc, "Stream"),
                    MLast.ExLid (loc, "npeek")),
                 MLast.ExInt (loc, string_of_int len, "")),
              MLast.ExLid (loc, "strm__")),
           [p, None, skont; MLast.PaAny loc, None, ckont])
  | SpLhd (loc, []) -> ckont
  | SpStr (loc, p) ->
      try
        match p with
          MLast.PaLid (_, v) -> subst v skont
        | _ -> raise Not_found
      with Not_found ->
        MLast.ExLet (loc, false, [p, MLast.ExLid (loc, strm_n)], skont)
;;

let rec stream_pattern loc epo e ekont =
  function
    [] ->
      begin match epo with
        Some ep ->
          MLast.ExLet
            (loc, false,
             [ep,
              MLast.ExApp
                (loc,
                 MLast.ExAcc
                   (loc, MLast.ExUid (loc, "Stream"),
                    MLast.ExLid (loc, "count")),
                 MLast.ExLid (loc, strm_n))],
             e)
      | _ -> e
      end
  | (SpLet (loc, p1, e1), _) :: spcl ->
      let skont = stream_pattern loc epo e ekont spcl in
      MLast.ExLet (loc, false, [p1, e1], skont)
  | (spc, err) :: spcl ->
      let skont =
        let ekont =
          function
            SpoQues estr ->
              MLast.ExApp
                (loc, MLast.ExLid (loc, "raise"),
                 MLast.ExApp
                   (loc,
                    MLast.ExAcc
                      (loc, MLast.ExUid (loc, "Stream"),
                       MLast.ExUid (loc, "Error")),
                    estr))
          | SpoBang ->
              MLast.ExApp
                (loc, MLast.ExLid (loc, "raise"),
                 MLast.ExAcc
                   (loc, MLast.ExUid (loc, "Stream"),
                    MLast.ExUid (loc, "Failure")))
          | SpoNoth ->
              MLast.ExApp
                (loc, MLast.ExLid (loc, "raise"),
                 MLast.ExApp
                   (loc,
                    MLast.ExAcc
                      (loc, MLast.ExUid (loc, "Stream"),
                       MLast.ExUid (loc, "Error")),
                    MLast.ExStr (loc, "")))
        in
        stream_pattern loc epo e ekont spcl
      in
      let ckont = ekont err in stream_pattern_component skont ckont spc
;;

let stream_patterns_term loc ekont tspel =
  let pel =
    List.map
      (fun (p, w, loc, spcl, epo, e) ->
         let p = MLast.PaApp (loc, MLast.PaUid (loc, "Some"), p) in
         let e =
           let ekont =
             function
               SpoQues estr ->
                 MLast.ExApp
                   (loc, MLast.ExLid (loc, "raise"),
                    MLast.ExApp
                      (loc,
                       MLast.ExAcc
                         (loc, MLast.ExUid (loc, "Stream"),
                          MLast.ExUid (loc, "Error")),
                       estr))
             | SpoBang ->
                 MLast.ExApp
                   (loc, MLast.ExLid (loc, "raise"),
                    MLast.ExAcc
                      (loc, MLast.ExUid (loc, "Stream"),
                       MLast.ExUid (loc, "Failure")))
             | SpoNoth ->
                 MLast.ExApp
                   (loc, MLast.ExLid (loc, "raise"),
                    MLast.ExApp
                      (loc,
                       MLast.ExAcc
                         (loc, MLast.ExUid (loc, "Stream"),
                          MLast.ExUid (loc, "Error")),
                       MLast.ExStr (loc, "")))
           in
           let skont = stream_pattern loc epo e ekont spcl in
           MLast.ExSeq
             (loc,
              [MLast.ExApp (loc, junk_fun loc, MLast.ExLid (loc, strm_n));
               skont])
         in
         p, w, e)
      tspel
  in
  let pel = pel @ [MLast.PaAny loc, None, ekont ()] in
  MLast.ExMat
    (loc, MLast.ExApp (loc, peek_fun loc, MLast.ExLid (loc, strm_n)), pel)
;;

let rec group_terms =
  function
    ((SpTrm (loc, p, w), SpoNoth) :: spcl, epo, e) :: spel ->
      let (tspel, spel) = group_terms spel in
      (p, w, loc, spcl, epo, e) :: tspel, spel
  | spel -> [], spel
;;

let rec parser_cases loc =
  function
    [] ->
      MLast.ExApp
        (loc, MLast.ExLid (loc, "raise"),
         MLast.ExAcc
           (loc, MLast.ExUid (loc, "Stream"), MLast.ExUid (loc, "Failure")))
  | spel ->
      if !optim then
        match group_terms spel with
          [], (spcl, epo, e) :: spel ->
            stream_pattern loc epo e (fun _ -> parser_cases loc spel) spcl
        | tspel, spel ->
            stream_patterns_term loc (fun _ -> parser_cases loc spel) tspel
      else
        match spel with
          (spcl, epo, e) :: spel ->
            stream_pattern loc epo e (fun _ -> parser_cases loc spel) spcl
        | [] ->
            MLast.ExApp
              (loc, MLast.ExLid (loc, "raise"),
               MLast.ExAcc
                 (loc, MLast.ExUid (loc, "Stream"),
                  MLast.ExUid (loc, "Failure")))
;;

let cparser loc bpo pc =
  let e = parser_cases loc pc in
  let e =
    match bpo with
      Some bp ->
        MLast.ExLet
          (loc, false,
           [bp,
            MLast.ExApp
              (loc,
               MLast.ExAcc
                 (loc, MLast.ExUid (loc, "Stream"),
                  MLast.ExLid (loc, "count")),
               MLast.ExLid (loc, strm_n))],
           e)
    | None -> e
  in
  let p =
    MLast.PaTyc
      (loc, MLast.PaLid (loc, strm_n),
       MLast.TyApp
         (loc,
          MLast.TyAcc
            (loc, MLast.TyUid (loc, "Stream"), MLast.TyLid (loc, "t")),
          MLast.TyAny loc))
  in
  MLast.ExFun (loc, [p, None, e])
;;

let cparser_match loc me bpo pc =
  let pc = parser_cases loc pc in
  let e =
    match bpo with
      Some bp ->
        MLast.ExLet
          (loc, false,
           [bp,
            MLast.ExApp
              (loc,
               MLast.ExAcc
                 (loc, MLast.ExUid (loc, "Stream"),
                  MLast.ExLid (loc, "count")),
               MLast.ExLid (loc, strm_n))],
           pc)
    | None -> pc
  in
  match me with
    MLast.ExLid (_, x) when x = strm_n -> e
  | _ ->
      MLast.ExLet
        (loc, false,
         [MLast.PaTyc
            (loc, MLast.PaLid (loc, strm_n),
             MLast.TyApp
               (loc,
                MLast.TyAcc
                  (loc, MLast.TyUid (loc, "Stream"), MLast.TyLid (loc, "t")),
                MLast.TyAny loc)),
          me],
         e)
;;

(* Streams *)

let rec not_computing =
  function
    MLast.ExLid (_, _) | MLast.ExUid (_, _) | MLast.ExInt (_, _, "") |
    MLast.ExFlo (_, _) | MLast.ExChr (_, _) | MLast.ExStr (_, _) ->
      true
  | MLast.ExApp (_, x, y) -> is_cons_apply_not_computing x && not_computing y
  | _ -> false
and is_cons_apply_not_computing =
  function
    MLast.ExUid (_, _) -> true
  | MLast.ExLid (_, _) -> false
  | MLast.ExApp (_, x, y) -> is_cons_apply_not_computing x && not_computing y
  | _ -> false
;;

let slazy loc e =
  match e with
    MLast.ExApp (_, f, MLast.ExUid (_, "()")) ->
      begin match f with
        MLast.ExLid (_, _) -> f
      | _ -> MLast.ExFun (loc, [MLast.PaAny loc, None, e])
      end
  | _ -> MLast.ExFun (loc, [MLast.PaAny loc, None, e])
;;

let rec cstream gloc =
  function
    [] ->
      let loc = gloc in
      MLast.ExAcc
        (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "sempty"))
  | [SeTrm (loc, e)] ->
      if not_computing e then
        MLast.ExApp
          (loc,
           MLast.ExAcc
             (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "ising")),
           e)
      else
        MLast.ExApp
          (loc,
           MLast.ExAcc
             (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "lsing")),
           slazy loc e)
  | SeTrm (loc, e) :: secl ->
      if not_computing e then
        MLast.ExApp
          (loc,
           MLast.ExApp
             (loc,
              MLast.ExAcc
                (loc, MLast.ExUid (loc, "Stream"),
                 MLast.ExLid (loc, "icons")),
              e),
           cstream gloc secl)
      else
        MLast.ExApp
          (loc,
           MLast.ExApp
             (loc,
              MLast.ExAcc
                (loc, MLast.ExUid (loc, "Stream"),
                 MLast.ExLid (loc, "lcons")),
              slazy loc e),
           cstream gloc secl)
  | [SeNtr (loc, e)] ->
      if not_computing e then e
      else
        MLast.ExApp
          (loc,
           MLast.ExAcc
             (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "slazy")),
           slazy loc e)
  | SeNtr (loc, e) :: secl ->
      if not_computing e then
        MLast.ExApp
          (loc,
           MLast.ExApp
             (loc,
              MLast.ExAcc
                (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "iapp")),
              e),
           cstream gloc secl)
      else
        MLast.ExApp
          (loc,
           MLast.ExApp
             (loc,
              MLast.ExAcc
                (loc, MLast.ExUid (loc, "Stream"), MLast.ExLid (loc, "lapp")),
              slazy loc e),
           cstream gloc secl)
;;