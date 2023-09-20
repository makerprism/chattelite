let rec last = function [] -> None | [ x ] -> Some x | _ :: tail -> last tail
