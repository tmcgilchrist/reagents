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
  type ('a,'b) reagent

  val mk_chan : ?name:string -> unit -> ('a,'b) endpoint * ('b,'a) endpoint
  val swap    : ('a,'b) endpoint -> ('a,'b) reagent
end

module Make (Sched : Scheduler.S) : S with
  type ('a,'b) reagent = ('a,'b) Core.Make(Sched).t = struct

  module Core = Core.Make(Sched)
  module Reaction = Reaction.Make(Sched)
  module Offer = Offer.Make(Sched)

  open Core

  type ('a,'b) reagent = ('a,'b) Core.t

  type ('a,'b) message =
    Message : 'c Offer.t * ('b,'a) t -> ('a,'b) message

  let mk_message (type a) (type b) (type c) (payload : a) (sender_rx : Reaction.t)
                 (sender_k : (b,c) t) (sender_offer : c Offer.t) =
    let try_react payload sender_offer sender_rx receiver_k c receiver_rx receiver_offer =
      let rx = Reaction.union sender_rx receiver_rx in
      let cas = Offer.complete sender_offer c in
      let new_rx =
        if can_cas_immediate receiver_k rx receiver_offer then
          match PostCommitCas.commit cas with
          | None -> None
          | Some f -> ( f (); Some rx )
        else Some (Reaction.with_CAS rx cas)
      in
      match new_rx with
      | None -> Retry
      | Some new_rx -> receiver_k.try_react payload new_rx receiver_offer
    in
    let rec complete_exchange : 'd. (a,'d) t -> (c,'d) t =
      fun receiver_k ->
        { always_commits = false;
          compose = (fun next -> complete_exchange (receiver_k.compose next));
          try_react = try_react payload sender_offer sender_rx receiver_k}
    in
    let complete_exchange =
          sender_k.compose (complete_exchange Core.commit)
    in
    Message (sender_offer, complete_exchange)

  type ('a,'b) endpoint =
    { name : string;
      outgoing: ('a,'b) message Lockfree.Michael_scott_queue.t;
      incoming: ('b,'a) message Lockfree.Michael_scott_queue.t }

  let mk_chan ?name () =
    let name =
      match name with
      | None -> ""
      | Some n -> n
    in
    let l1 = Lockfree.Michael_scott_queue.create () in
    let l2 = Lockfree.Michael_scott_queue.create () in
    {name = "+" ^ name; incoming = l1; outgoing = l2},
    {name = "-" ^ name; incoming = l2; outgoing = l1}

  let message_is_active (Message (o,_)) = Offer.is_active o

  let rec swap : 'a 'b 'r. ('a,'b) endpoint -> ('b,'r) reagent -> ('a,'r) reagent =
    let try_react ep k a rx offer =
      let {name = _name; outgoing; incoming} = ep in
      (* Search for matching offers *)
      let rec try_from cursor retry =
        match Lockfree.Michael_scott_queue.next cursor with
        | None -> if retry then Retry else Block
        | Some (Message (sender_offer,exchange), cursor) ->
            let same_offer o = function
            | None -> false
            | Some o' -> Offer.equal o o'
            in
            ( if (not (Offer.is_active sender_offer))
                || Reaction.has_offer rx sender_offer
                || same_offer sender_offer offer then
(*                   let _ = Printf.printf "me!!\n" in *)
                  try_from cursor retry
              else (* Found matching offer *)
(*                 let _ = Printf.printf "found matching offer!\n" in *)
                let new_rx = Reaction.with_offer rx sender_offer in
                let merged = exchange.compose k in
                match merged.try_react a new_rx offer with
                | Retry -> try_from cursor true
                | Block | BlockAndRetry -> try_from cursor retry
                | v -> v )
      in
      ( begin
          match offer with
          | Some offer (* when (not k.may_sync) *) ->
(*               Printf.printf "[%d,%s] pushing offer %d\n"  *)
(*                 (Sched.get_tid ()) name @@ Offer.get_id offer; *)
             Lockfree.Michael_scott_queue.push outgoing (mk_message a rx k offer)
          | _ -> ()
        end;
(*         Printf.printf "[%d,%s] checking..\n" (Sched.get_tid()) name; *)
        Lockfree.Michael_scott_queue.clean_until incoming message_is_active;
        if Lockfree.Michael_scott_queue.is_empty incoming then Block
        else try_from (Lockfree.Michael_scott_queue.snapshot incoming) false )
    in
    fun ep k ->
      { always_commits = false;
        compose = (fun next -> swap ep (k.compose next));
        try_react = try_react ep k}

  let swap ep = swap ep Core.commit
end
