(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2017       .                                          *)
(*    Fabrice Le Fessant, OCamlPro SAS <fabrice@lefessant.net>            *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

module Generichash = struct
  let primitive = "blake2b"
  type hash = string
  let compare = compare

  let init ~size () =
    Nocrypto.blake2b_init ~size ()
  let final = Nocrypto.blake2b_final


  module Bytes = struct
    let hash = Nocrypto.blake2b
    let to_hash s = s
    let of_hash s = s
    let update = Nocrypto.blake2b_update
  end

  module Bigbytes = Bytes
end


module Sign = struct
  let signature_size = 64
  let public_key_size = 32

  module Bytes = struct
    let of_public_key s = s
    let to_public_key s = s
  end
  module Bigbytes = Bytes
end
