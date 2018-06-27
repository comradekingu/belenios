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

open Web_serializable_t

module type AUTH_SERVICES = sig

  val get_auth_systems : unit -> string list Lwt.t
  val get_user : unit -> user option Lwt.t

end

module type AUTH_LINKS = sig

  val login :
    string option ->
    (unit, unit, Eliom_service.get, Eliom_service.att,
     Eliom_service.non_co, Eliom_service.non_ext,
     Eliom_service.non_reg, [ `WithoutSuffix ], unit, unit,
     Eliom_service.non_ocaml) Eliom_service.t

  val logout :
    (unit, unit, Eliom_service.get, Eliom_service.att,
     Eliom_service.non_co, Eliom_service.non_ext,
     Eliom_service.non_reg, [ `WithoutSuffix ], unit, unit,
     Eliom_service.non_ocaml) Eliom_service.t

end

type content =
    Eliom_registration.browser_content Eliom_registration.kind Lwt.t

module type WEB_BALLOT_BOX = sig
  val cast : string -> user * datetime -> string Lwt.t
end
