open Util
open Serializable_t
open Eliom_service
open Eliom_parameter

let home = service
  ~path:[]
  ~get_params:unit
  ()

let login = service
  ~path:["login"]
  ~get_params:unit
  ()

let cas_server = "https://cas.inria.fr"

let cas_login = external_service
  ~prefix:cas_server
  ~path:["cas"; "login"]
  ~get_params:Eliom_parameter.(string "service")
  ()

let cas_logout = external_service
  ~prefix:cas_server
  ~path:["cas"; "logout"]
  ~get_params:Eliom_parameter.(string "service")
  ()

let cas_validate = external_service
  ~prefix:cas_server
  ~path:["cas"; "validate"]
  ~get_params:Eliom_parameter.(string "service" ** string "ticket")
  ()

let login_cas = service
  ~path:["login-cas"]
  ~get_params:Eliom_parameter.(opt (string "ticket"))
  ()

let logout = service
  ~path:["logout"]
  ~get_params:unit
  ()

let perform_login () =
  Eliom_service.post_coservice
    ~csrf_safe:true
    ~csrf_scope:Eliom_common.default_session_scope
    ~fallback:login
    ~post_params:Eliom_parameter.(string "username")
    ()

let auth_systems = [
  "dummy";
]

let user = Eliom_reference.eref
  ~scope:Eliom_common.default_session_scope
  (None : Common.user option)

let uuid = Eliom_parameter.user_type
  (fun x -> match Uuidm.of_string x with
    | Some x -> x
    | None -> invalid_arg "uuid")
  Uuidm.to_string
  "uuid"

(* FIXME: decide whether uuid should be a directory or a GET parameter *)

let election_raw = service
  ~path:["election"; ""]
  ~get_params:uuid
  ()

let election_view = service
  ~path:["election"; "view"]
  ~get_params:uuid
  ()

let election_booth = static_dir_with_params
  ~get_params:(string "election_url")
  ()

let make_booth uuid =
  let service = Eliom_service.preapply election_raw uuid in
  Eliom_service.preapply election_booth (
    ["booth"; "vote.html"],
    Eliom_uri.make_string_uri ~absolute_path:true ~service ()
  )

let election_vote = service
  ~path:["election"; "vote"]
  ~get_params:uuid
  ()

let election_cast = service
  ~path:["election"; "cast"]
  ~get_params:uuid
  ()

let election_ballots = service
  ~path:["election"; "ballots"]
  ~get_params:uuid
  ()

let election_cast_post = post_service
  ~fallback:election_cast
  ~post_params:(string "encrypted_vote")
  ()

let get_randomness = service
  ~path:["get-randomness"]
  ~get_params:unit
  ()

(* FIXME: should be elsewhere... *)

let preapply_uuid s e = Eliom_service.preapply s e.Common.election.e_uuid

let is_eligible (uuid : Uuidm.t) (user : Common.user) =
  Lwt.return (String.startswith user.Common.user_name "special-")