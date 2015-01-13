open Core.Std
open Async.Std


exception Info_no_secret_key
exception Info_no_access_key_id
exception Info_no_region

let region =
  Common.Cmd.cmd_simply_print_response
    ~name:"aws-region"
    ~desc:"Prints the current aws default region"
    ~exn:Info_no_region
    "grep region ~/.aws/config | awk -F\" \" '{print $3}'"

let access_key =
  Common.Cmd.cmd_simply_print_response
    ~name:"aws-access-key-id"
    ~desc:"Prints the users access key id if it exists"
    ~exn:Info_no_access_key_id
    "grep aws_access_key_id ~/.aws/config | awk -F\" \" '{print $3}'"

let secret_key =
  Common.Cmd.cmd_simply_print_response
    ~name:"aws-secret-key"
    ~desc:"Prints the users aws access key id if it exists"
    ~exn: Info_no_secret_key
    "grep aws_secret_access_key ~/.aws/config | awk -F\" \" '{print $3}'"

let name = "info"

let command =
  Command.group ~summary:"Provides information useful in the system"
    [Info_user.desc;
     Info_identity.desc;
     access_key;
     secret_key;
     region]

let desc = (name, command)
