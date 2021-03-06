(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! Core
module F = Format

module type Config = sig
  val limit : int
  (** the maximum number [N] of bindings to keep around *)
end

(** A functional map interface where only the [N] most recently-accessed elements are guaranteed to
    be persisted, similarly to an LRU cache. The map stores at most [2*N] elements.

    Operations on the map have the same asymptotic complexity as {!Map.Make}. *)
module type S = sig
  type t [@@deriving compare]

  type key

  type value

  val equal : (value -> value -> bool) -> t -> t -> bool

  val pp : F.formatter -> t -> unit

  val empty : t

  val add : key -> value -> t -> t

  val find_opt : key -> t -> value option

  val fold : t -> init:'acc -> f:('acc -> key -> value -> 'acc) -> 'acc

  val fold_bindings : t -> init:'acc -> f:('acc -> key * value -> 'acc) -> 'acc
  (** convenience function based on [fold] *)

  val fold_map : t -> init:'acc -> f:('acc -> value -> 'acc * value) -> 'acc * t

  val is_empty : t -> bool

  val bindings : t -> (key * value) list

  val union : f:(key -> value -> value -> value option) -> t -> t -> t
  (** same caveat as {!merge} *)

  val merge : f:(key -> value option -> value option -> value option) -> t -> t -> t
  (** if the maps passed as arguments disagree over which keys are the most recent and there are
      more than [2*N] different keys between the two maps then some bindings will be arbitrarily
      lost *)
end

module Make
    (Key : PrettyPrintable.PrintableOrderedType)
    (Value : PrettyPrintable.PrintableOrderedType)
    (Config : Config) : S with type key = Key.t and type value = Value.t
