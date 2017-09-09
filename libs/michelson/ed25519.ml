(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2017       .                                          *)
(*    Fabrice Le Fessant, OCamlPro SAS <fabrice@lefessant.net>            *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

open Error_monad

module Public_key_hash = Hash.Make_Blake2B(Base58)(struct
      let name = "Ed25519.Public_key_hash"
      let title = "An Ed25519 public key ID"
      let b58check_prefix = Base58.Prefix.ed25519_public_key_hash
      let size = Some 20
    end)

module Signature = struct

  type t = MBytes.t

    type Base58.data +=
      | Signature of t

    let b58check_encoding =
      Base58.register_encoding
        ~prefix: Base58.Prefix.ed25519_signature
        ~length:Sodium.Sign.signature_size
        ~to_raw:MBytes.to_string
        ~of_raw:(fun s -> Some (MBytes.of_string s))
        ~wrap:(fun x -> Signature x)

    let encoding =
      let open Data_encoding in
      splitted
        ~json:
          (describe
             ~title: "An Ed25519 signature (Base58Check encoded)" @@
           conv
             (fun s -> Base58.simple_encode b58check_encoding s)
             (fun s ->
                match Base58.simple_decode b58check_encoding s with
                | Some x -> x
                | None -> Data_encoding.Json.cannot_destruct
                            "Ed25519 signature: unexpected prefix.")
             string)
        ~binary: (Fixed.bytes Sodium.Sign.signature_size)

    let check _key _sig _msg = true (* TODO *)

end


module Comparisons = struct
  module Make(S : sig
                type v
                val compare : v -> v -> int
              end) = struct
    let compare = S.compare
    let (=) xs ys = compare xs ys = 0
    let (<>) xs ys = compare xs ys <> 0
    let (<) xs ys = compare xs ys < 0
    let (<=) xs ys = compare xs ys <= 0
    let (>=) xs ys = compare xs ys >= 0
    let (>) xs ys = compare xs ys > 0
    let max x y = if x >= y then x else y
    let min x y = if x <= y then x else y
  end
end

module Public_key = struct

  type t = string

  include Comparisons.Make(struct
                            type v = t
                            let compare = compare
                            end)


    type Base58.data +=
      | Public_key of t

    let b58check_encoding =
      Base58.register_encoding
        ~prefix: Base58.Prefix.ed25519_public_key
        ~length:Sodium.Sign.public_key_size
        ~to_raw:(fun x -> Bytes.to_string (Sodium.Sign.Bytes.of_public_key x))
        ~of_raw:(fun x ->
            try Some (Sodium.Sign.Bytes.to_public_key (Bytes.of_string x))
            with _ -> None)
        ~wrap:(fun x -> Public_key x)

    let of_b58check_opt s = Base58.simple_decode b58check_encoding s
    let of_b58check_exn s =
      match Base58.simple_decode b58check_encoding s with
      | Some x -> x
      | None -> Pervasives.failwith "Unexpected hash (ed25519 public key)"
    let of_b58check s =
      match Base58.simple_decode b58check_encoding s with
      | Some x -> Ok x
      | None -> generic_error "Unexpected hash (ed25519 public key)"
    let to_b58check s = Base58.simple_encode b58check_encoding s

    let of_bytes s = Sodium.Sign.Bytes.to_public_key s

                                                     (*
    let param ?(name="ed25519-public") ?(desc="Ed25519 public key (b58check-encoded)") t =
      Cli_entries.param ~name ~desc (fun _ str -> Lwt.return (of_b58check str)) t
                                                      *)

    let () =
      Base58.check_encoded_prefix b58check_encoding "edpk" 54

    let encoding =
      let open Data_encoding in
      splitted
        ~json:
          (describe
             ~title: "An Ed25519 public key (Base58Check encoded)" @@
           conv
             (fun s -> Base58.simple_encode b58check_encoding s)
             (fun s ->
                match Base58.simple_decode b58check_encoding s with
                | Some x -> x
                | None -> Data_encoding.Json.cannot_destruct
                            "Ed25519 public key: unexpected prefix.")
             string)
        ~binary:
          (conv
             Sodium.Sign.Bigbytes.of_public_key
             Sodium.Sign.Bigbytes.to_public_key
             (Fixed.bytes Sodium.Sign.public_key_size))

    let hash v =
      Public_key_hash.hash_bytes
        [ Sodium.Sign.Bigbytes.of_public_key v ]

  end
