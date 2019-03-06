(**************************************************************************)
(*                                BELENIOS                                *)
(*                                                                        *)
(*  Copyright © 2012-2018 Inria                                           *)
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

(** Signatures *)

open Platform
open Serializable_t

(** Helpers for interacting with atd stuff *)

type 'a reader = Yojson.Safe.lexer_state -> Lexing.lexbuf -> 'a
type 'a writer = Bi_outbuf.t -> 'a -> unit

(** A group suitable for discrete logarithm-based cryptography. *)
module type GROUP = sig
  (** The following interface is redundant: it is assumed, but not
      checked, that usual mathematical relations hold. *)

  type t
  (** The type of elements. Note that it may be larger than the group
      itself, hence the [check] function below. *)

  val check : t -> bool
  (** Check group membership. *)

  val one : t
  (** The neutral element of the group. *)

  val g : t
  (** A generator of the group. *)

  val q : Z.t
  (** The order of [g]. *)

  val ( *~ ) : t -> t -> t
  (** Multiplication. *)

  val ( **~ ) : t -> Z.t -> t
  (** Exponentiation. *)

  val ( =~ ) : t -> t -> bool
  (** Equality test. *)

  val invert : t -> t
  (** Inversion. *)

  val to_string : t -> string
  (** Conversion to string. *)

  val of_string : string -> t
  (** Conversion from string. *)

  val read : t reader
  (** Reading from a stream. *)

  val write : t writer
  (** Writing to a stream. *)

  val hash : string -> t array -> Z.t
  (** Hash an array of elements into an integer mod [q]. The string
      argument is a string that is prepended before computing the hash. *)

  val compare : t -> t -> int
  (** A total ordering over the elements of the group. *)

  type group
  (** Serializable description of the group. *)

  val group : group
  val write_group : group writer

end

(** A public key with its group *)
module type WRAPPED_PUBKEY = sig
  module G : GROUP
  val y : G.t
end

(** Monad signature. *)
module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val fail : exn -> 'a t
end

(** Random number generation. *)
module type RANDOM = sig
  include MONAD

  val random : Z.t -> Z.t t
  (** [random q] returns a random number modulo [q]. *)
end

(** Election data needed for cryptographic operations. *)
type 'a election = {
  e_params : 'a params;
  (** Parameters of the election. *)

  e_fingerprint : string;
  (** Fingerprint of the election. *)
}

(** Election data bundled with a group. *)
module type ELECTION_DATA = sig
  module G : GROUP
  val election : G.t election
end

(** Cryptographic primitives for an election with homomorphic tally. *)
module type ELECTION = sig

  type 'a m
  (** The type of monadic values. *)

  (** {2 Election parameters} *)

  (** Ballots are encrypted using public-key cryptography secured by
      the discrete logarithm problem. Here, we suppose private keys
      are integers modulo a large prime number. Public keys are
      members of a suitably chosen group. *)

  type elt

  module G : GROUP with type t = elt
  val election : elt election

  type private_key = Z.t
  type public_key = elt

  (** {2 Ciphertexts} *)

  type ciphertext = elt Serializable_t.ciphertext array array
  (** A ciphertext that can be homomorphically combined. *)

  val neutral_ciphertext : unit -> ciphertext
  (** The neutral element for [combine_ciphertext] below. *)

  val combine_ciphertexts : ciphertext -> ciphertext -> ciphertext
  (** Combine two ciphertexts. The encrypted tally of an election is
      the combination of all ciphertexts of valid cast ballots. *)

  (** {2 Ballots} *)

  type plaintext = Serializable_t.plaintext
  (** The plaintext equivalent of [ciphertext], i.e. the contents of a
      ballot. When [x] is such a value, [x.(i).(j)] is the weight (0
      or 1) given to answer [j] in question [i]. *)

  type ballot = elt Serializable_t.ballot
  (** A ballot ready to be transmitted, containing the encrypted
      answers and cryptographic proofs that they satisfy the election
      constraints. *)

  val create_ballot : ?sk:private_key -> plaintext -> ballot m
  (** [create_ballot r answers] creates a ballot, or raises
      [Invalid_argument] if [answers] doesn't satisfy the election
      constraints. The private key, if given, will be used to sign
      the ballot. *)

  val check_ballot : ballot -> bool
  (** [check_ballot b] checks all the cryptographic proofs in [b]. All
      ballots produced by [create_ballot] should pass this check. *)

  val extract_ciphertext : ballot -> ciphertext
  (** Extract the ciphertext from a ballot. *)

  (** {2 Partial decryptions} *)

  type factor = elt partial_decryption
  (** A decryption share. It is computed by a trustee from his or her
      private key share and the encrypted tally, and contains a
      cryptographic proof that he or she didn't cheat. *)

  val compute_factor : ciphertext -> private_key -> factor m

  val check_factor : ciphertext -> public_key -> factor -> bool
  (** [check_factor c pk f] checks that [f], supposedly submitted by a
      trustee whose public_key is [pk], is valid with respect to the
      encrypted tally [c]. *)

  (** {2 Result} *)

  type result = elt Serializable_t.election_result
  (** The election result. It contains the needed data to validate the
      result from the encrypted tally. *)

  type combinator = factor list -> elt array array

  val compute_result : int -> ciphertext -> factor list -> combinator -> result
  (** Combine the encrypted tally and the factors from all trustees to
      produce the election result. The first argument is the number of
      tallied ballots. May raise [Invalid_argument]. *)

  val check_result : combinator -> result -> bool

  val extract_tally : result -> plaintext
  (** Extract the plaintext result of the election. *)
end

module type PKI = sig
  type 'a m
  type private_key
  type public_key
  val genkey : unit -> string m
  val derive_sk : string -> private_key
  val derive_dk : string -> private_key
  val sign : private_key -> string -> signed_msg m
  val verify : public_key -> signed_msg -> bool
  val encrypt : public_key -> string -> string m
  val decrypt : private_key -> string -> string
  val make_cert : sk:private_key -> dk:private_key -> cert m
  val verify_cert : cert -> bool
end

module type CHANNELS = sig
  type 'a m
  type private_key
  type public_key
  val send : private_key -> public_key -> string -> string m
  val recv : private_key -> public_key -> string -> string
end

module type PEDERSEN = sig
  type 'a m
  type elt

  val step1 : unit -> (string * cert) m
  val step1_check : cert -> bool
  val step2 : certs -> unit
  val step3 : certs -> string -> int -> polynomial m
  val step3_check : certs -> int -> polynomial -> bool
  val step4 : certs -> polynomial array -> vinput array
  val step5 : certs -> string -> vinput -> elt voutput m
  val step5_check : certs -> int -> polynomial array -> elt voutput -> bool
  val step6 : certs -> polynomial array -> elt voutput array -> elt threshold_parameters

  val check : elt threshold_parameters -> bool
  val combine : elt threshold_parameters -> elt

  type checker = elt -> elt partial_decryption -> bool
  val combine_factors : checker -> elt threshold_parameters -> elt partial_decryption list -> elt array array
end
