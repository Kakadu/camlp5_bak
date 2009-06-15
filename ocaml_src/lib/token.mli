(* camlp5r *)
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

(** Lexing for Camlp5 grammars.

   This module defines the Camlp5 lexer type to be used in extensible
   grammars (see module [Grammar]). It also provides some useful functions
   to create lexers (this module should be renamed [Plexing] one day). *)

type pattern = string * string;;
    (* Type for values used by the generated code of the EXTEND
       statement to represent terminals in entry rules.
-      The first string is the constructor name (must start with
       an uppercase character). When it is empty, the second string
       is supposed to be a keyword.
-      The second string is the constructor parameter. Empty if it
       has no parameter (corresponding to the 'wildcard' pattern).
-      The way tokens patterns are interpreted to parse tokens is done
       by the lexer, function [tok_match] below. *)

exception Error of string;;
    (** A lexing error exception to be used by lexers. *)

(** {6 Lexer type} *)

type 'te glexer =
  { tok_func : 'te lexer_func;
    tok_using : pattern -> unit;
    tok_removing : pattern -> unit;
    mutable tok_match : pattern -> 'te -> string;
    tok_text : pattern -> string;
    mutable tok_comm : Stdpp.location list option }
and 'te lexer_func = char Stream.t -> 'te Stream.t * location_function
and location_function = int -> Stdpp.location;;
  (**>The type of a function giving the location of a token in the
      source from the token number in the stream (starting from zero). *)

type location = Stdpp.location;;
val make_loc : int * int -> location;;
val dummy_loc : location;;
  (** compatibility camlp5 distributed with ocaml *)

val lexer_text : pattern -> string;;
   (** A simple [tok_text] function for lexers *)

val default_match : pattern -> string * string -> string;;
   (** A simple [tok_match] function for lexers, appling to token type
       [(string * string)] *)

(** {6 Lexers from char stream parsers or ocamllex function}

   The functions below create lexer functions either from a [char stream]
   parser or for an [ocamllex] function. With the returned function [f],
   the simplest [Token.lexer] can be written:
   {[
          { Token.tok_func = f;
            Token.tok_using = (fun _ -> ());
            Token.tok_removing = (fun _ -> ());
            Token.tok_match = Token.default_match;
            Token.tok_text = Token.lexer_text }
   ]}
   Note that a better [tok_using] function should check the used tokens
   and raise [Token.Error] for incorrect ones. The other functions
   [tok_removing], [tok_match] and [tok_text] may have other implementations
   as well. *)

val lexer_func_of_parser :
  (char Stream.t * int ref * int ref -> 'te * location) -> 'te lexer_func;;
   (** A lexer function from a lexer written as a char stream parser
       returning the next token and its location. The two references
       with the char stream contain the current line number and the
       position of the beginning of the current line. *)
val lexer_func_of_ocamllex : (Lexing.lexbuf -> 'te) -> 'te lexer_func;;
   (** A lexer function from a lexer created by [ocamllex] *)

val make_stream_and_location :
  (unit -> 'te * location) -> 'te Stream.t * location_function;;
   (** General function *)

(** {6 Useful functions and values} *)

val eval_char : string -> char;;
val eval_string : location -> string -> string;;
   (** Convert a char or a string token, where the backslashes had not
       been interpreted into a real char or string; raise [Failure] if
       bad backslash sequence found; [Token.eval_char (Char.escaped c)]
       returns [c] and [Token.eval_string (String.escaped s)] returns [s] *)

val restore_lexing_info : (int * int) option ref;;
val line_nb : int ref ref;;
val bol_pos : int ref ref;;
   (** Special variables used to reinitialize line numbers and position
       of beginning of line with their correct current values when a parser
       is called several times with the same character stream. Necessary
       for directives (e.g. #load or #use) which interrupt the parsing.
       Without usage of these variables, locations after the directives
       can be wrong. *)
