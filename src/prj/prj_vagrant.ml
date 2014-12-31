open Core.Std
open Core_extended.Std
open Async.Std

type errors =
  | No_vagrant_file
  | Invalid_ip with sexp

exception Vagrant_error of errors with sexp

type cache = {last_start: Time.t;
              last_ip: String.t Option.t} with sexp

type ip = String.t

let project_root () =
  Sys.getcwd ()
  >>= fun base_dir ->
  Prj_common.search_dominating_file ~base_dir ~dominating:"Vagrantfile" ()
  >>| function
  | Some path ->
    Ok (Filename.normalize @@ Filename.make_absolute path)
  | None ->
    Error (Vagrant_error No_vagrant_file)

let remote_ip () =
  Async_shell.sh_lines "vagrant ssh-config | grep HostName | awk -F\" \" '{print $2}'"
  >>| function
  | [ip] ->
    Ok ip
  | _ ->
    Error (Vagrant_error Invalid_ip)

let cache_path dir =
  Filename.implode [dir; ".vcache"]

let get_cache dir =
  let cache_path = cache_path dir in
  Sys.file_exists cache_path
  >>= function
  | `Yes ->
    (Reader.with_file
       cache_path
       ~f:(fun body ->
           Reader.read_sexp body))
    >>| (function
        | `Ok sexp ->
          Ok (cache_of_sexp sexp)
        | _ ->
          Ok {last_start=Time.now (); last_ip=None})
  | _ ->
    return @@ Ok {last_start=Time.now (); last_ip=None}

let store_cache root cache =
  let cache_path = cache_path root in
  let sexp = sexp_of_cache cache in
  Writer.with_file
    cache_path
    ~f:(fun t ->
        return @@ Writer.write_sexp t sexp)
  >>| fun _ ->
  Ok ()

let raw_start root =
  Async_shell.sh ~verbose:true "vagrant up --provider=aws  --no-provision"
  >>= fun _ ->
  remote_ip ()
  >>=? fun ip ->
  store_cache root {last_start=Time.now (); last_ip=Some ip}
  >>|? fun _ ->
  ip

let test_connectivity project_root ip =
  Monitor.try_with
    (fun () ->
       Async_shell.sh "nc -n -z -w2 %s 22" ip)
  >>= function
  | Ok () ->
    return @@ Ok ip
  | Error _ ->
    raw_start project_root

let start root cache =
  match cache.last_ip with
  | Some ip ->
    test_connectivity root ip
  | None ->
    raw_start root

let start_vagrant project_root =
  let open Deferred.Result.Monad_infix in
  get_cache project_root
  >>= start project_root

let internal_rsync ~identity ~project_root ~ip () =
  Async_shell.sh
    ~echo:true
    ~verbose:true
    "rsync -avz -e \"ssh -l ubuntu -i %s\" \
     --delete --exclude '_build' --exclude '.#*' %s/ \"%s:/vagrant/\""
    identity project_root ip
  >>| fun _ ->
  Ok ()

let rsync ~identity ~project_root ~ip () =
  test_connectivity project_root ip
  >>=? fun new_ip ->
  internal_rsync ~identity ~project_root ~ip:new_ip ()
  >>| fun _ ->
  Ok new_ip
