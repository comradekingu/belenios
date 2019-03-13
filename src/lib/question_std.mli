(**************************************************************************)
(*                                BELENIOS                                *)
(*                                                                        *)
(*  Copyright © 2012-2019 Inria                                           *)
(*                                                                        *)
(*  This program is free software: you can redistribute it and/or modify  *)
(*  it under the terms of the GNU Affero General Public License as        *)
(*  published by the Free Software Foundation, either version 3 of the    *)
(*  License, or (at your option) any later version, with the additional   *)
(*  exemption that compiling, linking, and/or using OpenSSL is allowed.   *)
(*                                                                        *)
(*  This program is distributed in the hope that it will be useful, but   *)
(*  WITHOUT ANY WARRANTY; without even the implied warranty of            *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *)
(*  Affero General Public License for more details.                       *)
(*                                                                        *)
(*  You should have received a copy of the GNU Affero General Public      *)
(*  License along with this program.  If not, see                         *)
(*  <http://www.gnu.org/licenses/>.                                       *)
(**************************************************************************)

open Signatures_core
open Serializable_builtin_t
open Question_std_t

val question_length : question -> int

module type S = sig
  type elt
  type 'a m

  val create_answer : question -> public_key:elt -> prefix:string -> int array -> elt answer m
  val verify_answer : question -> public_key:elt -> prefix:string -> elt answer -> bool

  val extract_ciphertexts : elt answer -> elt ciphertext shape

  val compute_result : num_tallied:int -> question -> elt shape -> int shape
  val check_result : question -> elt shape -> int shape -> bool
end

module Make (M : RANDOM) (G : GROUP) : S with type 'a m = 'a M.t and type elt = G.t