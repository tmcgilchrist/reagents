(*
 * Copyright (c) 2015, Théo Laurent <theo.laurent@ens.fr>
 * Copyright (c) 2015, KC Sivaramakrishnan <sk826@cl.cam.ac.uk>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

module type S = sig
  type ('a,'b) endpoint
  (** The type of endpoint which accepts value of type ['a] and return value of
      type ['b]. *)

  type ('a,'b) reagent
  (** The type of reagent. See {!Reagents.S.t}. *)

  val mk_chan : ?name:string -> unit -> ('a,'b) endpoint * ('b,'a) endpoint
  (** Make a new channel. Returns a pair of dual endpoints. *)

  val swap : ('a,'b) endpoint -> ('a,'b) reagent
  (** Swap on the channel. *)

end

module Make (Sched : Scheduler.S) : S with
  type ('a,'b) reagent = ('a,'b) Core.Make(Sched).t
