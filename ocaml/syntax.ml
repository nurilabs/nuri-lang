(** Module Syntax contains the Abstract Syntax Tree (AST) of
    the Nuri language with some functions to convert the AST
    or its element to string.

    Module dependencies:
    - Common

    @author Herry (herry13\@gmail.com)
    @since 2014
*)

open Common

(** Abstract Syntax Tree of the Nuri language. *)

(** core syntax **)
type nuri          = context
and  context       = AssignmentContext of assignment * context
                   | SchemaContext     of schema * context
                   | EnumContext       of enum * context
                   | TrajectoryContext of trajectory * context
                   | EmptyContext
and  block         = AssignmentBlock   of assignment * block
                   | TrajectoryBlock   of trajectory * block
                   | EmptyBlock
and  assignment    = TypeValue of reference * t * value
                   | RefIndexValue of reference * string list * value
and  expression    = Basic           of basic_value
                   | Exp_Index       of expression * string list
                   | Shell           of string
                   | Exp_Eager       of expression 
                   | Exp_IString     of string
                   | Exp_Not         of expression
                   | Exp_Equal       of expression * expression
                   | Exp_NotEqual    of expression * expression
                   | Exp_And         of expression * expression
                   | Exp_Or          of expression * expression
                   | Exp_Imply       of expression * expression
                   | Exp_MatchRegexp of expression * string
                   | Exp_Add         of expression * expression
                   | Exp_Subtract    of expression * expression
                   | Exp_Multiply    of expression * expression
                   | Exp_Divide      of expression * expression
                   | Exp_Modulo      of expression * expression
                   | Exp_IfThenElse  of expression * expression * expression
and  value         = Expression of expression
                   | Link       of reference
                   | Prototype  of super * prototype
                   | Action     of action
                   | TBD
                   | Unknown
                   | None
and  prototype     = ReferencePrototype of reference * prototype
                   | BlockPrototype     of block * prototype
                   | EmptyPrototype
and  basic_value   = Boolean   of string
                   | Int       of string
                   | Float     of string
                   | String    of string
                   | Null
                   | Vector    of vector
                   | Reference of reference
                   | RefIndex  of reference * string list
and  vector        = basic_value list
and  reference     = string list

(** schema syntax **)
and schema = string * super * block
and super  = SID of string
           | EmptySchema

(** enum syntax **)
and enum = string * string list

(** type syntax **)
and t = T_Bool
      | T_Int
      | T_Float
      | T_String
      | T_Null
      | T_Undefined
      | T_Any
      | T_Action
      | T_Constraint
      | T_Enum      of string * string list
      | T_Symbol    of string
      | T_List      of t
      | T_Schema    of t_object
      | T_Object    of t_object
      | T_Reference of t_object
      | T_Forward   of t_forward
    
and t_object = T_Plain
             | T_User of string * t_object
    
and t_forward = T_Link      of reference
              | T_Ref of reference

(** state-trajectory syntax **)
and trajectory = Global of _constraint

(** constraint syntax **)
and _constraint = C_Equal        of reference * basic_value
                | C_NotEqual     of reference * basic_value
				| C_Greater      of reference * basic_value
				| C_GreaterEqual of reference * basic_value
				| C_Less         of reference * basic_value
				| C_LessEqual    of reference * basic_value
                | C_Not          of _constraint
                | C_Imply        of _constraint * _constraint
                | C_And          of _constraint list
                | C_Or           of _constraint list
                | C_In           of reference * vector

(** action syntax **)
and action     = parameter list * cost * conditions * effect list
and parameter  = string * t
and cost       = Cost of string
               | EmptyCost
and conditions = Condition of _constraint
               | EmptyCondition
and effect     = reference * basic_value


(*******************************************************************
 * exception and error handling function
 *******************************************************************)

exception SyntaxError of int * string

let error code message =
  match message with
  | "" -> raise (SyntaxError (code, "[err" ^ (string_of_int code) ^ "]"))
  | _  -> raise (SyntaxError (code, "[err" ^ (string_of_int code) ^ "] - " ^
                                    message))
;;


(*******************************************************************
 * functions to convert elements of abstract syntax tree to string
 *******************************************************************)

(** convert a type into a string **)
let string_of_type t =
  let buf = Buffer.create 5 in
  let rec _type t = match t with
    | T_Bool         -> buf << "bool"
    | T_Int          -> buf << "int"
    | T_Float        -> buf << "float"
    | T_String       -> buf << "string"
    | T_Null         -> buf << "null"
    | T_Undefined    -> buf << "undefined"
    | T_Any          -> buf << "any"
    | T_Action       -> buf << "action"
    | T_Constraint   -> buf << "global"
    | T_Enum (id, _) -> buf <<| "enum(" <<| id <. ')'
    | T_Symbol id    -> buf <<| "enum:" << id
    | T_List t ->
      begin
        buf << "[]";
        _type t
      end
    | T_Schema t ->
      begin
        buf << "schema~";
        type_object t
      end
    | T_Object t -> type_object t
    | T_Reference t ->
      begin
        buf <. '*';
        type_object t
      end
    | T_Forward T_Link r -> buf <<| "forward(" <<| !^r <. ')'
    | T_Forward T_Ref r -> buf <<| "forward*(" <<| !^r <. ')'

  and type_object t = match t with
    | T_Plain            -> buf << "object"
    | T_User (id, super) ->
      begin
        buf <<| id <. '<';
        type_object super
      end
  in
  _type t;
  Buffer.contents buf
;;

(** convert an abstract syntax tree into a string **)
let rec string_of nuri =
  let buf = Buffer.create 40 in
  let rec context ctx = match ctx with
    | AssignmentContext (a, c) ->
      begin
        assignment a;
        buf <. '\n';
        context c
      end
    | SchemaContext (s, c) ->
      begin
        schema s;
        buf <. '\n';
        context c
      end
    | EnumContext (e, c) ->
      begin
      enum e;
        buf <. '\n';
        context c
      end
    | TrajectoryContext (t, c) ->
      begin
        trajectory t;
        buf <. '\n';
        context c
      end
    | EmptyContext -> ()

  and block b = match b with
    | AssignmentBlock (a, b) ->
      begin
        assignment a;
        buf <. '\n';
        block b
      end
    | TrajectoryBlock (t, b) ->
      begin
        trajectory t;
        buf <. '\n';
        block b
      end
    | EmptyBlock -> ()

  and assignment = function
    | TypeValue (r, t, v) ->
      begin
        reference r;
        buf <. ':';
        _type t;
        value v;
        buf <. ';'
      end
    | RefIndexValue (r, indexes, v) ->
      begin
        reference r;
        buf <. ' ';
        List.iter (fun index -> buf <.| '[' <<| index <. ']') indexes;
        value v;
        buf <. ';'
      end

  and expression e = match e with
    | Basic v -> basic_value v
    | Exp_Index (exp, indexes) ->
      begin
        buf <. ' ';
        expression e;
        List.iter (fun index -> buf <.| '[' <<| index <. ']') indexes
      end
    | Shell s -> buf <<| " `" <<| s <. '`'
      (* TODO: use escape (\) for every backtick character *)

    | Exp_Eager e ->
      begin
        buf << " $(";
        expression e;
        buf <. ')'
      end
    | Exp_IString s -> buf <<| " \"" <<| s <. '"'
    | Exp_Not e ->
      begin
        buf << " !(";
        expression e;
        buf <. ')'
      end
    | Exp_Equal (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " = ";
        expression e2;
        buf <. ')'
      end
    | Exp_NotEqual (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " != ";
        expression e2;
        buf <. ')'
      end
    | Exp_And (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " && ";
        expression e2;
        buf <. ')'
      end
    | Exp_Or (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " || ";
        expression e2;
        buf <. ')'
      end
    | Exp_Imply (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " => ";
        expression e2;
        buf <. ')'
      end
    | Exp_MatchRegexp (exp, regexp) ->
      begin
        buf << " (";
        expression exp;
        buf <<| " =~ /" <<| regexp << "/)"
      end
    | Exp_Add (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " + ";
        expression e2;
        buf <. ')'
      end
    | Exp_Subtract (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " - ";
        expression e2;
        buf <. ')'
      end
    | Exp_Multiply (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " - ";
        expression e2;
        buf <. ')'
      end
    | Exp_Divide (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " - ";
        expression e2;
        buf <. ')'
      end
    | Exp_Modulo (e1, e2) ->
      begin
        buf << " (";
        expression e1;
        buf << " - ";
        expression e2;
        buf <. ')'
      end
    | Exp_IfThenElse (e1, e2, e3) ->
      begin
        buf << " (if ";
        expression e1;
        buf << " then ";
        expression e2;
        buf << " else ";
        expression e3;
        buf <. ')'
      end

  and value v = match v with
    | Expression e ->
      begin
        buf <. ' ';
        expression e
      end
    | Link lr ->
      begin
        buf <. ' ';
        reference lr
      end
    | Prototype (sid, p) ->
      begin
        super_schema sid;
        prototype p
      end
    | Action a -> action a
    | TBD      -> buf << " TBD"
    | Unknown  -> buf << " Unknown"
    | None     -> buf << " None"

  and prototype proto = match proto with
    | ReferencePrototype (r, p) ->
      begin
        buf << " extends ";
        reference r;
        prototype p
      end
    | BlockPrototype (b, p) ->
      begin
        buf << " extends {\n";
        block b;
        prototype p
      end
    | EmptyPrototype -> ()

  and basic_value bv = match bv with
    | Boolean x | Int x | Float x -> buf << x
    | String x    -> buf <<| "'" <<| x << "'"
    | Null        -> buf << "null"
    | Vector vec  ->
      begin
        buf <. '[';
        vector vec;
        buf <. ']'
      end
    | Reference r ->
      begin
        buf <. ' ';
        reference r
      end
    | RefIndex (ref, index) ->
      begin
        buf <. ' ';
        reference ref;
        List.iter (fun i -> buf <.| '[' <<| i <. ']') index
      end

  and vector vec = match vec with
    | []           -> ()
    | head :: []   -> basic_value head
    | head :: tail ->
      begin
        basic_value head;
        buf <. ',';
        vector tail
      end

  and reference r = buf << !^r

  and _type t = match t with
    | T_Bool         -> buf << "bool"
    | T_Int          -> buf << "int"
    | T_Float        -> buf << "float"
    | T_String       -> buf << "string"
    | T_Null         -> buf << "null"
    | T_Undefined    -> buf << "undefined"
    | T_Any          -> buf << "any"
    | T_Action       -> buf << "action"
    | T_Constraint   -> buf << "global"
    | T_Enum (id, _) -> buf << id
    | T_Symbol id    -> buf << id
    | T_List t ->
      begin
        buf << "[]";
        _type t
      end
    | T_Schema t    -> type_object t
    | T_Object t    -> type_object t
    | T_Reference t ->
      begin
        buf <. '*';
        type_object t
      end
    | T_Forward T_Link r ->
      error 301 "T_Link is not allowed."

    | T_Forward T_Ref r ->
      error 302 "T_Ref is not allowed."

  and type_object t = match t with
    | T_Plain        -> buf << "object"
    | T_User (id, _) -> buf << id;

  and super_schema ss = match ss with
    | SID id      -> buf <<| " isa " << id
    | EmptySchema -> ()

  and schema (sid, super, b) =
    buf <<| "schema " << sid;
    super_schema super;
    buf << " {\n";
    block b;
    buf <. '}'

  and enum (id, symbols) =
    buf <<| "enum " <<| id <<| " {\n" <<| (String.concat ", " symbols) << "\n}"

  (*** constraints ***)

  and trajectory t = match t with
    | Global g -> global g

  and global g =
    buf << "global ";
    constraints g;
    buf <. '\n'

  and constraints c = match c with
    | C_Equal (r, bv) ->
      begin
        reference r;
        buf << " = ";
        basic_value bv;
        buf <. ';'
      end
    | C_NotEqual (r, bv) ->
      begin
        reference r;
        buf << " != ";
        basic_value bv;
        buf <. ';'
      end
    | C_Not c ->
      begin
        buf << "not ";
        constraints c
      end
    | C_Imply (c1, c2) ->
      begin
        buf << "if ";
        constraints c1;
        buf << " then ";
        constraints c2
      end
    | C_And cs ->
      begin
        buf << "{\n";
        List.iter (fun c ->
          constraints c;
          buf <. '\n'
        ) cs;
        buf <. '}'
      end
    | C_Or cs ->
      begin
        buf << "(\n";
        List.iter (fun c ->
          constraints c;
          buf <. '\n'
        ) cs;
        buf <. ')'
      end
    | C_In (r, vec) ->
      begin
        reference r;
        buf << " in ";
        vector vec;
        buf <. ';'
      end
    | C_Greater (r, v) ->
      begin
        reference r;
        buf << " > ";
        basic_value v;
        buf <. ';'
      end
    | C_GreaterEqual (r, v) ->
      begin
        reference r;
        buf << " >= ";
        basic_value v;
        buf <. ';'
      end
    | C_Less (r, v) ->
      begin
        reference r;
        buf << " < ";
        basic_value v;
        buf <. ';'
      end
    | C_LessEqual (r, v) ->
      begin
        reference r;
        buf << " <= ";
        basic_value v;
        buf <. ';'
      end

  and effect (r, v) =
    reference r;
    buf << " = ";
    basic_value v;
    buf <. ';'

  and effects effs =
    buf << "{\n";
    List.iter (fun e ->
      effect e;
      buf <. '\n'
    ) effs;
    buf <. '}'

  and conditions c = match c with
    | EmptyCondition -> ()
    | Condition c ->
      begin
        buf << "conditions ";
        constraints c
      end

  and cost c = match c with
    | EmptyCost -> ()
    | Cost n -> buf <<| "cost = " <<| n <. ';'

  and parameter (id, t) =
    buf <<| id <. ';';
    _type t

  and parameters params = match params with
    | [] -> ()
    | head :: [] ->
      begin
        buf <. '(';
        parameter head;
        buf <. ')'
      end
    | head :: tail ->
      begin
        buf <. '(';
        parameter head;
        List.iter (fun p ->
          buf <. ',';
          parameter p
        ) tail;
        buf <. ')'
      end

  and action (params, c, cond, effs) : unit =
    buf << "def ";
    parameters params;
    buf << " {\n";
    cost c;
    conditions cond;
    effects effs;
    buf <. '}'

  in
  context nuri;
  Buffer.contents buf
;;


