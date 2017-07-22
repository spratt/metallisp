#!/usr/bin/env racket
#lang racket

(define DEBUG #f)

(require test-engine/racket-tests)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (str-split line sep)
  ; Split a string on a given seperator, and return the seperators
  ; TODO: redefine this later to avoid optional arg
  (string-split line sep #:trim? #f)) 

(define (remove-comment line delim)
  ; Return only the substring of a line before a given delimiter
  (define parts (str-split line delim))
  (if (or (empty? parts) (eq? "#" (first parts)))
      ""
      (first parts)))

(define (remove-comments line)
  ; Return only the substring of a line before a comment delimiter (# or ;)
  (if (string-prefix? line "#")
      ""
      (remove-comment line ";")))

(define (read-lines acc)
  (define line (read-line))
  (if (eq? line eof)
      acc
      (let ((no-comments-line (remove-comments line)))
        (when DEBUG (printf "line: ~v, ncl: ~v~n" line no-comments-line))
        (read-lines (string-trim (string-append acc " " no-comments-line))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (read-until-pred-helper loc acc pred)
  ; Takes a list-of-characters to read (loc) and a list-of-characters
  ; already read (acc) and returns a list whose first element is the
  ; list of characters after the next space in loc, and the second
  ; element is the list of characters that preceded the next space in
  ; loc.  If there is no space in loc, the first element will be empty
  ; and the second will be the input loc.
  (if (empty? loc)
      (list loc acc)
      (if (pred loc acc)
          (list (rest loc) acc)
          (read-until-pred-helper (rest loc)
                                  (cons (first loc) acc)
                                  pred))))

(define (read-until-pred loc pred)
  (define ret (read-until-pred-helper loc (list) pred))
  (list (first ret) (list->string (reverse (second ret)))))

(define (read-until-whitespace loc)
  (read-until-pred loc
                   (lambda (loc acc)
                     (char-whitespace? (first loc)))))

(check-expect (read-until-whitespace (string->list "hello world"))
              (list (string->list "world") "hello"))

(define (loc-trim loc)
  (string->list (string-trim (list->string loc))))

(define (read-string loc)
  ; Reads until the first " that isn't preceded by a backslash \
  (define ret
    (read-until-pred loc
                     (lambda (loc acc)
                       (and (char=? (first loc) #\")
                            (or (empty? acc)
                                (not (char=? (first acc) #\\)))))))
  (list (loc-trim (first ret))
        (second ret)))

(check-expect (read-string (string->list "one\" two"))
              (list (string->list "two") "one"))

(define special-tokens
  (list (list #\( 'lparen)
        (list #\) 'rparen)
        (list #\' 'quote)))

(define (tokenize-helper loc acc)
  ; loc is a list of characters yet to tokenize
  ; acc is the list of tokens so far
  (cond
    ; Base case, nothing left to tokenize
    ((empty? loc) acc)
    ; A special token
    ((assoc (first loc) special-tokens) ; annoying duplication \/
     (tokenize-helper (loc-trim (rest loc))
                      (cons (second (assoc (first loc) special-tokens))
                            acc)))
    ; Strings
    ((char=? (first loc) #\")
     (let ((ret (read-string (rest loc))))
       (tokenize-helper (first ret)
                        (cons (second ret) acc))))
    ; Everything else must be a symbol
    (else
     (let ((ret (read-until-whitespace loc)))
       (tokenize-helper (first ret)
                        (cons (string->symbol (second ret)) acc))))))

(check-expect (tokenize-helper (list) 'pass)
              'pass)
(check-expect (tokenize-helper (string->list "(") (list))
              (list 'lparen))
(check-expect (tokenize-helper (string->list ")") (list))
              (list 'rparen))
(check-expect (tokenize-helper (string->list "'") (list))
              (list 'quote))
(check-expect (tokenize-helper (string->list "\"hello world\"") (list))
              (list "hello world"))
(check-expect (tokenize-helper (string->list "hello") (list))
              (list 'hello))

(define (tokenize s)
  ; Take a string and turn it into a list of tokens
  ; eg: "(and (+ 2 2) (println \"hello world\") 'hi)"
  ;  -> (list 'lparen
  ;           'and
  ;           'lparen
  ;           '+
  ;           2
  ;           2
  ;           'rparen
  ;           'lparen
  ;           'println
  ;           "hello world"
  ;           'rparen
  ;           'quote
  ;           'hi
  ;           'rparen)
  (reverse (tokenize-helper (string->list s) (list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (die msg)
  (println msg)
  (exit))

; Forgive me if I don't test the preceding function.  ;)

(define (parse-list toks acc)
  ; Parse a list of tokens looking for the rparen to match an
  ; already-parsed lparen.
  (when DEBUG (printf "parse-list, toks: ~v, acc: ~v~n" toks acc))
  (cond ((empty? toks) (die "MTL error: missing rparen"))
        ((eq? (first toks) 'rparen)
         (list (rest toks) (reverse acc)))
        ((eq? (first toks) 'lparen)
         (let ((ret (parse-list (rest toks) (list))))
           (parse-list (first ret)
                       (cons (second ret) acc))))         
        (else (parse-list (rest toks) (cons (first toks) acc)))))

(check-expect (parse-list '(a b c rparen) (list))
              (list (list) '(a b c)))
(check-expect (parse-list '(a b c lparen 1 2 3 rparen rparen) (list))
              (list (list) '(a b c (1 2 3))))
(check-expect (parse-list '(a b c rparen lparen 1 2 3 rparen) (list))
              (list '(lparen 1 2 3 rparen) '(a b c)))

(define (parse-helper toks acc)
  ; Parse a list of tokens into a list of either tokens or lists of tokens.
  (when DEBUG (printf "parse-helper, toks: ~v, acc: ~v~n" toks acc))
  (cond ((empty? toks) (reverse acc))
        ((eq? (first toks) 'rparen) (die "MTL error: unexpected rparen"))
        ((eq? (first toks) 'lparen)
         (let ((ret (parse-list (rest toks) (list))))
           (parse-helper (first ret)
                         (cons (second ret) acc))))
        (else (parse-helper (rest toks) (cons (first toks) acc)))))

(check-expect (parse-helper '(lparen a b c rparen) (list))
              (list '(a b c)))
(check-expect (parse-helper '(lparen a b c lparen 1 2 3 rparen rparen) (list))
              (list '(a b c (1 2 3))))
(check-expect (parse-helper '(lparen a b c rparen lparen 1 2 3 rparen) (list))
              (list '(a b c) '(1 2 3)))

(define (parse toks)
  ; Take a list of tokens (toks), and parse them into something that
  ; can be evaluated or compiled
  (parse-helper toks (list)))

(check-expect (parse (list 'lparen
                           'and
                           'lparen
                           '+
                           2
                           2
                           'rparen
                           'lparen
                           'println
                           "hello world"
                           'rparen
                           'quote
                           'hi
                           'rparen))
              (list (list 'and
                          (list '+
                                2
                                2)
                          (list 'println
                                "hello world")
                          'quote
                          'hi)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; An associative list that maps function names to lambdas
(define functions
  (list
   (list 'asm   (lambda (s) (printf "        ~a~n" s)))
   (list 'label (lambda (s) (printf "~a:~n" s)))
   (list 'dir   (lambda (s) (printf ".~a~n" s)))
   (list 'db    (lambda (s) (printf "        db \"~a\", 0~n" s)))))

(define (compile-ast ast)
  (when DEBUG (printf "compile-ast ast: ~v~n" ast))
  (define elem (assoc (first ast) functions))
  (if elem
      (apply (second elem) (rest ast))
      (printf "compile-ast, not found: ~v~n" (first ast))))

(define (compile-forest forest)
  (when (not (empty? forest))
    (compile-ast (first forest))
    (compile-forest (rest forest))))

(define (print-port p)
  (define line (read-line p))
  (when (not (eq? line eof))
    (begin
      (printf "~a~n" line)
      (print-port p))))

(define (print-file f)
  (print-port (open-input-file f)))

(define (compile forest)
  (print-file "header.asm")
  (compile-forest forest)
  (print-file "footer.asm"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Read the input from the standard input
(define input-string (read-lines (string)))
(when DEBUG (printf "input: ~v~n" input-string))

(if (string=? input-string "")
    (test)
    (let ((tokens (tokenize input-string)))
      (when DEBUG (printf "tokens: ~v~n" tokens))
      (let ((asf (parse tokens)))
        (when DEBUG (printf "asf: ~v~n" asf))
        (when DEBUG (printf "Compiler output:~n~n"))
        (compile asf))))
