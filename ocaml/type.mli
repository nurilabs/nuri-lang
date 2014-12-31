(** Module Type contains the type environment (list and map)
    as well as its algebra functions.

    Module dependencies:
    - Common

    @author Herry (herry13\@gmail.com)
    @since 2014
*)

open Common
open Syntax

type environment = variable_type list

and variable_type = Domain.reference * t

and map = t MapRef.t

exception Error of int * string

val error : ?env:environment -> ?map:map -> int -> string -> 'a


val string_of_map : map -> string

val type_of : Domain.reference -> map -> t

val map_of : environment -> map

val well_formed : map -> map -> bool


val string_of_environment : environment -> string

val initial_environment : environment

val find : Domain.reference -> environment -> t

val (@:) : Domain.reference -> environment -> t

val subtype : t -> t -> bool

val (<:) : t -> t -> bool

val (=:=) : t -> t -> bool



val bind : ?t_variable:t -> t -> t -> Domain.reference -> environment ->
           environment

val variables_with_prefix : ?remove_prefix:bool -> Domain.reference ->
                            environment -> environment

val copy : Domain.reference -> Domain.reference -> environment -> environment

val resolve : Domain.reference -> Domain.reference -> environment ->
              (Domain.reference * t)

val _inherit : Domain.reference -> Domain.reference -> Domain.reference ->
               environment -> environment



val main_of : Domain.reference -> environment -> environment

val replace_forward_type : Domain.reference -> environment -> environment


val symbol_of_enum : string -> environment -> string -> bool


module MapType : Map.S with type key = t

type type_values = Domain.SetValue.t MapType.t

val values_of : t -> type_values -> Domain.SetValue.t

(*val add_value : t -> Domain.value -> type_values -> type_values*)

val make_type_values : map -> Domain.flatstore -> map -> Domain.flatstore ->
                       type_values
