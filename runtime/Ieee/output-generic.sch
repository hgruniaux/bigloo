;*=====================================================================*/
;*    .../prgm/project/bigloo/wasm/runtime/Ieee/output-generic.sch     */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Mon Jul 22 15:24:13 2024                          */
;*    Last change :  Tue Sep 17 14:59:27 2024 (serrano)                */
;*    Copyright   :  2024 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Portable output implementation                                   */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The directives                                                   */
;*---------------------------------------------------------------------*/
(directives
   (export (bgl_write_char::obj ::bchar ::output-port)
           (bgl_display_fixnum::obj ::bint ::output-port)
           (bgl_display_elong::obj ::elong ::output-port)
           (bgl_display_llong::obj ::llong ::output-port)
	   (inline $$display-fixnum::obj ::bint ::output-port)
	   (inline $$write-procedure ::procedure ::output-port)
	   ($$write-cnst ::obj ::output-port))
   (extern (export bgl_write_char "bgl_write_char")
           (export bgl_display_fixnum "bgl_display_fixnum")
           (export bgl_display_elong "bgl_display_elong")
           (export bgl_display_llong "bgl_display_llong")))

;*---------------------------------------------------------------------*/
;*    alpha ...                                                        */
;*---------------------------------------------------------------------*/
(define (alpha n)
   (string-ref "0123456789abcdef" n))

;*---------------------------------------------------------------------*/
;*    char-names ...                                                   */
;*---------------------------------------------------------------------*/
(define-macro (char-names)
   `',(apply vector
	 (map (lambda (n)
		 (call-with-output-string
		    (lambda (op)
		       (write (integer->char n) op))))
	    (iota 256))))

;*---------------------------------------------------------------------*/
;*    bgl_write_char ...                                               */
;*---------------------------------------------------------------------*/
(define (bgl_write_char o op)
   (define names (char-names))
   ($display-string (vector-ref names (char->integer o)) op))

;*---------------------------------------------------------------------*/
;*    bgl_display_fixnum ...                                           */
;*---------------------------------------------------------------------*/
(define (bgl_display_fixnum o op)
   ($display-string (integer->string o) op))

;*---------------------------------------------------------------------*/
;*    bgl_display_elong ...                                            */
;*---------------------------------------------------------------------*/
(define (bgl_display_elong o op)
   (display-fixnum ($long->bint ($elong->long o)) op))

;*---------------------------------------------------------------------*/
;*    bgl_display_llong ...                                            */
;*---------------------------------------------------------------------*/
(define (bgl_display_llong o op)
   (display-fixnum ($long->bint ($llong->long o)) op))

;*---------------------------------------------------------------------*/
;*    $$display-fixnum ...                                             */
;*---------------------------------------------------------------------*/
(define-inline ($$display-fixnum o op)
   (display-string (fixnum->string o 10) op))
   
;*---------------------------------------------------------------------*/
;*    $$write-procedure ...                                            */
;*---------------------------------------------------------------------*/
(define-inline ($$write-procedure o op)
   (display "#<procedure:" op)
   (bgl_display_fixnum (procedure-arity o) op)
   (display ">" op))

;*---------------------------------------------------------------------*/
;*    write-cnst-string ...                                            */
;*---------------------------------------------------------------------*/
(define-macro (write-cnst-string cnst op)
   (let ((s (call-with-output-string (lambda (p) (write cnst p)))))
      `(display ,s ,op)))

;*---------------------------------------------------------------------*/
;*    $$write-cnst ...                                                 */
;*---------------------------------------------------------------------*/
(define ($$write-cnst o op)
   (cond
      ((eq? o #t) (write-cnst-string #t op))
      ((eq? o #f) (write-cnst-string #f op))
      ((null? o) (write-cnst-string '() op))
      ((eq? o #unspecified) (write-cnst-string #unspecified op))
      (else (display "#<???>" op))))
