[

 (block_text)
 (inline_text)
 (inline_text_list)
 (inline_text_bullet_list)
 (inline_text_bullet_item)
 (cmd_expr_arg)

 (match_expr)
 (parened_expr)
 (list)
 (record)
 (tuple)

 (application)
 (binary_expr)

 (sig_stmt)
 (struct_stmt)

 (let_stmt)
 (let_inline_stmt)
 (let_block_stmt)
 (let_math_stmt)

 (match_arm)

 ] @indent.begin

; (match_arm expr: (_) @indent)

(ctrl_if
  ; cond:(_) @indent
  "then" @indent.branch
  "else" @indent.branch
  ; true_clause:(_) @indent
  ; false_clause:(_) @indent
  ) @indent.begin

; (let_stmt expr:(_) @indent)
; (let_inline_stmt expr:(_) @indent)
; (let_block_stmt expr:(_) @indent)
; (let_math_stmt expr:(_) @indent)

(block_text ">" @indent.end)
(inline_text "}" @indent.end)
(inline_text_list "}" @indent.end)
(inline_text_bullet_list "}" @indent.end)
(parened_expr ")" @indent.end)
(cmd_expr_arg ")" @indent.end)

(list "]" @indent.end)
(record "|)" @indent.end)
(tuple ")" @indent.end)

[
  ")"
  "]"
  "}"
  "|)"
  "end"
] @indent.branch
(block_text ">" @indent.branch)

; (match_arm "|" @branch)

; (
;  (binary_expr
;    (binary_operator) @binop
;    ) @aligned_indent
;  (#set! "delimiter" "|")
;  (#matches! @binop "|>")
;  )
