(** Module [ElGamal] *)

open Helios_datatypes_t

module type GROUP = sig
  type t
  val one : t
  val g : t
  val q : Z.t
  val p : Z.t
  val ( *~ ) : t -> t -> t
  val ( **~ ) : t -> Z.t -> t
  val ( =~ ) : t -> t -> bool
  val inv : t -> t
  val check_exponent : Z.t -> bool
  val check_element : t -> bool
  val hash : t list -> Z.t
end
  (** Signature of an abstract group suitable for ElGamal *)

val make_ff_msubgroup : Z.t -> Z.t -> Z.t -> (module GROUP with type t = Z.t)
  (** [make_ff_msubgroup p q g] builds the multiplicative subgroup of
      F[p], generated by [g], of order [q]. *)

module type ELGAMAL_CRYPTO = sig
  type t
  val verify_public_key : t public_key -> bool
  val verify_private_key : t private_key -> bool
  val verify_pok : t -> t pok -> bool
  val verify_election_key : t -> t trustee_public_key array -> bool
  val verify_disjunction : t -> t -> t array -> t proof array -> bool
  val verify_range : t -> int -> int -> t -> t -> t proof array -> bool
  val verify_answer : t -> question -> t answer -> bool
  val verify_vote : t election -> string -> t vote -> bool
  val verify_equality : t -> t -> t -> t proof -> bool
  val verify_partial_decryption :
    t election -> t tally -> t trustee_public_key -> t partial_decryption -> bool
  val verify_partial_decryptions : t election -> t election_public_data -> bool
  val verify_result : t election -> t election_public_data -> bool
  val compute_encrypted_tally : t election -> t vote array -> t encrypted_tally
end

module Make (G : GROUP) : ELGAMAL_CRYPTO with type t := G.t
