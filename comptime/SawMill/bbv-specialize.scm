;*=====================================================================*/
;*    .../bigloo/bigloo/comptime/SawMill/bbv-specialize.scm            */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Jul 20 07:42:00 2017                          */
;*    Last change :  Fri Jul  8 14:16:07 2022 (serrano)                */
;*    Copyright   :  2017-22 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    BBV instruction specialization                                   */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module saw_bbv-specialize
   
   (include "Tools/trace.sch"
	    "SawMill/regset.sch"
	    "SawMill/bbv-types.sch")
   
   (import  engine_param
	    ast_var
	    ast_node
	    type_type
	    type_cache
	    tools_shape
	    tools_speek
	    backend_backend
	    saw_lib
	    saw_defs
	    saw_regset
	    saw_regutils
	    saw_bbv-types
	    saw_bbv-cache
	    saw_bbv-utils
	    saw_bbv-range)
   
   (export (bbv-block::blockS b::blockV ctx::pair-nil)))

;*---------------------------------------------------------------------*/
;*    basic-block versionning configuration                            */
;*---------------------------------------------------------------------*/
(define *type-call* #t)
(define *type-loadi* #t)

;* {*---------------------------------------------------------------------*} */
;* {*    intervals                                                        *} */
;* {*---------------------------------------------------------------------*} */
;* (define *infinity-intv* (interval *-inf.0* *+inf.0*))               */
;* (define *length-intv* (interval #l0 *max-length*))                  */
;* (define *fixnum-intv* (interval *min-fixnum* *max-fixnum*))         */

;*---------------------------------------------------------------------*/
;*    bbv-block ::blockV ...                                           */
;*---------------------------------------------------------------------*/
(define (bbv-block::blockS b::blockV ctx::pair-nil)
   (with-access::blockV b (label versions succs preds first)
      (with-trace 'bbv (format "bbv-block ~a" label)
	 (let ((ctx (filter-live-in-regs (car first) ctx)))
	    (trace-item "succs=" (map block-label succs))
	    (trace-item "preds=" (map block-label preds))
	    (trace-item "ctx=" (shape ctx))
	    (trace-item "versions= #" (length versions) " "
	       (map ctx->string (map car versions)))
	    (let ((old (assoc ctx versions)))
	       (if (pair? old)
		   (cdr old)
		   (specialize-block! b ctx)))))))
   
;*---------------------------------------------------------------------*/
;*    specialize-block! ...                                            */
;*---------------------------------------------------------------------*/
(define (specialize-block!::blockS b::blockV ctx)
   
   (define (connect! s::blockS ins::rtl_ins)
      (cond
	 ((rtl_ins-ifeq? ins)
	  (with-access::rtl_ins ins (fun)
	     (let ((n (rtl_ifeq-then fun)))
		(block-succs-set! s (list #unspecified n))
		(block-preds-set! n (cons s (block-preds n))))))
	 ((rtl_ins-ifne? ins)
	  (with-access::rtl_ins ins (fun)
	     (let ((n (rtl_ifne-then fun)))
		(block-succs-set! s (list #unspecified n))
		(block-preds-set! n (cons s (block-preds n))))))
	 ((rtl_ins-go? ins)
	  (with-access::rtl_ins ins (fun)
	     (let ((n (rtl_go-to fun)))
		(if (pair? (block-succs s))
		    (set-car! (block-succs s) n)
		    (block-succs-set! s (list n)))
		(block-preds-set! n (cons s (block-preds n))))))))

   (with-access::blockV b (first label succs versions)
      (with-trace 'bbv-block (format "specialize-block! ~a" label)
	 (let* ((ctx (map (lambda (d)
			     (duplicate::bbv-ctxentry d))
			ctx))
		(lbl (genlabel))
		(s (instantiate::blockS
		      (%parent b)
		      (label lbl)
		      (first '()))))
	    (set! versions (cons (cons ctx s) versions))
	    (trace-item "new-label=" lbl)
	    (let loop ((oins first)
		       (nins '())
		       (ctx ctx))
	       (with-trace 'bbv-ins (format "specialize-block!.loop")
		  (trace-item "ctx=" (shape ctx))
		  (when (pair? oins)
		     (trace-item "ins=" (shape (car oins)))))
	       (cond
		  ((null? oins)
		   (with-access::blockS s (first)
		      (set! first (reverse! nins))
		      s))
		  ((rtl_ins-specializer (car oins))
		   =>
		   (lambda (specialize)
		      ;; instruction specialization
		      (multiple-value-bind (ins ctx)
			 (specialize (car oins) ctx)
			 (let ((ctx (extend-live-out-regs (car oins) ctx)))
			    (cond
			       ((rtl_ins-br? ins)
				(connect! s ins)
				(loop (cdr oins) (cons ins nins) ctx))
			       ((rtl_ins-go? ins)
				(connect! s ins)
				(loop '() (cons ins nins) ctx))
			       (else
				(loop (cdr oins) (cons ins nins) ctx)))))))
		  ((rtl_ins-last? (car oins))
		   ;; a return, fail, ...
		   (loop '() (cons (duplicate-ins (car oins) ctx) nins) '()))
		  ((rtl_ins-go? (car oins))
		   (with-access::rtl_ins (car oins) (fun)
		      (with-access::rtl_go fun (to)
			 (let* ((n (bbv-block to ctx))
				(ins (duplicate::rtl_ins/bbv (car oins)
					(ctx ctx)
					(fun (duplicate::rtl_go fun
						(to n))))))
			    (connect! s ins)
			    (loop '() (cons ins nins) ctx)))))
		  ((rtl_ins-ifeq? (car oins))
		   (with-access::rtl_ins (car oins) (fun)
		      (with-access::rtl_ifeq fun (then)
			 (let* ((n (bbv-block then ctx))
				(ins (duplicate::rtl_ins/bbv (car oins)
					(ctx ctx)
					(fun (duplicate::rtl_ifeq fun
						    (then n))))))
			    (connect! s ins)
			    (loop (cdr oins) (cons ins nins) ctx)))))
		  ((rtl_ins-ifne? (car oins))
		   (with-access::rtl_ins (car oins) (fun)
		      (with-access::rtl_ifne fun (then)
			 (let* ((n (bbv-block then ctx))
				(ins (duplicate::rtl_ins/bbv (car oins)
					(ctx ctx)
					(fun (duplicate::rtl_ifne fun
						    (then n))))))
			    (connect! s ins)
			    (loop (cdr oins) (cons ins nins) ctx)))))
;* 		  ((not (rtl_reg? (rtl_ins-dest (car oins))))          */
;* 		   (loop (cdr oins)                                    */
;* 		      (cons (duplicate-ins (car oins) ctx) nins) ctx)) */
		  (else
		   (loop (cdr oins) (cons (duplicate-ins (car oins) ctx) nins)
		      (extend-live-out-regs (car oins) ctx)))))))))

;*---------------------------------------------------------------------*/
;*    duplicate-ins ...                                                */
;*---------------------------------------------------------------------*/
(define (duplicate-ins ins ctx)
   (duplicate::rtl_ins/bbv ins
      (ctx ctx)))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specializer ...                                          */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specializer i::rtl_ins)
   (cond
      ((rtl_ins-fxcmp? i) rtl_ins-specialize-fxcmp)
      ((rtl_ins-typecheck? i) rtl_ins-specialize-typecheck)
      ((rtl_ins-mov? i) rtl_ins-specialize-mov)
      ((rtl_ins-loadi? i) rtl_ins-specialize-loadi)
      ((rtl_ins-call-specialize? i) rtl_ins-specialize-call)
      (else #f)))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-typecheck ...                                 */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-typecheck i::rtl_ins ctx)
   (with-trace 'bbv-ins "rtl_ins-specialize-typecheck"
      (multiple-value-bind (reg type flag)
	 (rtl_ins-typecheck i)
	 (let ((e (ctx-get ctx reg)))
	    (with-access::rtl_ins i (fun)
	       (trace-item "ins=" (shape i))
	       (trace-item "typ=" (shape type) " flag=" flag)
	       (trace-item "e=" (shape e))
	       (cond
		  ((and (eq? (bbv-ctxentry-typ e) type)
			(bbv-ctxentry-flag e))
		   ;; positive type simplification
		   (let ((pctx (extend-ctx ctx reg type #t)))
		      (with-access::rtl_ins/bbv i (fun)
			 (if (isa? fun rtl_ifeq)
			     (let ((s (duplicate::rtl_ins/bbv i
					 (ctx ctx)
					 (fun (instantiate::rtl_nop))
					 (dest #f)
					 (args '()))))
				(values s pctx))
			     (with-access::rtl_ifne fun (then)
				(let ((s (duplicate::rtl_ins/bbv i
					    (ctx ctx)
					    (fun (instantiate::rtl_go
						    (to (bbv-block then pctx))))
					    (dest #f)
					    (args '()))))
				   (values s (extend-ctx ctx reg type #f))))))))
		  ((and (eq? (bbv-ctxentry-typ e) type)
			(not (bbv-ctxentry-flag e)))
		   ;; negative type simplification
		   (let ((nctx (extend-ctx ctx reg type #f)))
		      (with-access::rtl_ins/bbv i (fun)
			 (if (isa? fun rtl_ifne)
			     (let ((s (duplicate::rtl_ins/bbv i
					 (ctx ctx)
					 (fun (instantiate::rtl_nop))
					 (dest #f)
					 (args '()))))
				(values s nctx))
			     (with-access::rtl_ifeq fun (then)
				(let ((s (duplicate::rtl_ins/bbv i
					    (ctx ctx)
					    (fun (instantiate::rtl_go
						    (to (bbv-block then nctx))))
					    (dest #f)
					    (args '()))))
				   (values s (extend-ctx ctx reg type #t))))))))
		  ((isa? fun rtl_ifne)
		   (with-access::bbv-ctxentry e (aliases)
		      (let ((regs (cons reg aliases)))
			 (with-access::rtl_ifne fun (then)
			    (let* ((n (bbv-block then
					 (extend-ctx* ctx regs type #t)))
				   (s (duplicate::rtl_ins/bbv i
					 (ctx ctx)
					 (fun (duplicate::rtl_ifne fun
						 (then n))))))
			       (values s (extend-ctx* ctx regs type #f)))))))
		  ((isa? fun rtl_ifeq)
		   (with-access::bbv-ctxentry e (aliases)
		      (let ((regs (cons reg aliases)))
			 (with-access::rtl_ifeq fun (then)
			    (let* ((n (bbv-block then
					 (extend-ctx* ctx regs type #f)))
				   (s (duplicate::rtl_ins/bbv i
					 (ctx ctx)
					 (fun (duplicate::rtl_ifeq fun
						 (then n))))))
			       (values s (extend-ctx* ctx regs type #t)))))))
		  (else
		   (error "rtl_ins-specialize-typecheck"
		      "should not be here"
		      (shape i)))))))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-mov ...                                       */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-mov i::rtl_ins ctx)
   (with-trace 'bbv-ins "rtl_ins-specialize-mov"
      (with-access::rtl_ins i (dest args fun)
	 (let ((ctx (unalias-ctx ctx dest)))
	    (cond
	       ((and (pair? args) (null? (cdr args)) (rtl_reg/ra? (car args)))
		(let ((e (ctx-get ctx (car args))))
		   (with-access::bbv-ctxentry e (typ)
		      (values (duplicate-ins i ctx)
			 (alias-ctx
			    (extend-ctx ctx dest typ #t)
			    dest (car args))))))
	       ((and *type-call* (pair? args) (rtl_ins-call? (car args)))
		(with-access::rtl_ins (car args) (fun)
		   (with-access::rtl_call fun (var)
		      (with-access::global var (value type)
			 (values (duplicate-ins i ctx)
			    (extend-ctx ctx dest type #t))))))
	       ((and *type-loadi* (pair? args) (rtl_ins-loadi? (car args)))
		(with-access::rtl_ins (car args) (fun)
		   (with-access::rtl_loadi fun (constant)
		      (with-access::atom constant (type)
			 (values (duplicate-ins i ctx)
			    (extend-ctx ctx dest type #t))))))
	       (else
		(values (duplicate-ins i ctx) ctx)))))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-loadi ...                                     */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-loadi i::rtl_ins ctx)
   (with-trace 'bbv-ins "rtl_ins-specialize-loadi"
      (with-access::rtl_ins i (dest args fun)
	 (with-access::rtl_loadi fun (constant)
	    (with-access::atom constant (value type)
	       (let ((s (duplicate::rtl_ins/bbv i
			   (ctx ctx)
			   (fun (duplicate::rtl_loadi fun)))))
		  (if (fixnum? value)
		      (values s (extend-ctx ctx dest type #t
				   :value (fixnum->range value)))
		      (values s (extend-ctx ctx dest type #t)))))))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-call-specialize? ...                                     */
;*---------------------------------------------------------------------*/
(define (rtl_ins-call-specialize? i::rtl_ins)
   (when (rtl_ins-call? i)
      (with-access::rtl_ins i (dest)
	 dest)))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-call ...                                      */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-call i::rtl_ins ctx)
   (with-trace 'bbv-ins "rtl_ins-specialize-call"
      (with-access::rtl_ins i (dest fun)
	 (with-access::rtl_call fun (var)
	    (with-access::global var (value type)
	       (let ((s (duplicate::rtl_ins/bbv i
			   (ctx ctx)
			   (fun (duplicate::rtl_call fun)))))
		  (if (fun? value)
		      (values s (extend-normalize-ctx ctx dest type #t))
		      (values s (extend-ctx ctx dest *obj* #t)))))))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-fxcmp? ...                                               */
;*---------------------------------------------------------------------*/
(define (rtl_ins-fxcmp? i)
   
   (define (reg? a)
      (or (rtl_reg? a)
	  (and (rtl_ins? a)
	       (with-access::rtl_ins a (fun args dest)
		  (when (isa? fun rtl_call)
		     (rtl_reg? dest))))))

   (define (rtl_call-fxcmp? i)
      (with-access::rtl_ins i (dest fun args)
	 (with-access::rtl_call fun (var)
	    (and (=fx (length args) 2)
		 (or (eq? var *<fx*) (eq? var *<=fx*)
		     (eq? var *>fx*) (eq? var *>=fx*)
		     (eq? var *=fx*))
		 (or (reg? (car args)) (rtl_ins-loadi? (car args)))
		 (or (reg? (cadr args)) (rtl_ins-loadi? (cadr args)))))))
   
   (with-access::rtl_ins i (dest fun args)
      (cond
	 ((isa? fun rtl_call)
	  (rtl_call-fxcmp? i))
	 ((isa? fun rtl_ifeq)
	  (rtl_call-fxcmp? (car args)))
	 ((isa? fun rtl_ifne)
	  (rtl_call-fxcmp? (car args)))
	 (else
	  #f))))
   
;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-fxcmp ...                                     */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-fxcmp i::rtl_ins ctx)
   
   (define (true)
      (instantiate::rtl_loadi
	 (constant (instantiate::literal (type *bool*) (value #t)))))
   
   (define (false)
      (instantiate::rtl_loadi
	 (constant (instantiate::literal (type *bool*) (value #f)))))
   
   (define (rtl_bint->long? a)
      (when (isa? a rtl_ins)
	 (with-access::rtl_ins a (fun)
	    (when (isa? fun rtl_call)
	       (with-access::rtl_call fun (var)
		  (eq? var *bint->long*))))))
   
   (define (reg? a)
      (or (rtl_reg? a)
	  (and (rtl_ins? a)
	       (with-access::rtl_ins a (fun args dest)
		  (when (isa? fun rtl_call)
		     (with-access::rtl_call fun (var)
			(if (eq? var *bint->long*)
			    (rtl_reg? (car args))
			    (rtl_reg? dest))))))))
   
   (define (reg a)
      (cond
	 ((rtl_reg? a) a)
	 ((rtl_bint->long? a) (car (rtl_ins-args a)))
	 (else (rtl_ins-dest a))))
   
   (define (fxcmp-op i)
      (with-access::rtl_ins i (fun)
	 (with-access::rtl_call fun (var)
	    (cond
	       ((eq? var *<fx*) '<)
	       ((eq? var *<=fx*) '<=)
	       ((eq? var *>fx*) '>)
	       ((eq? var *>=fx*) '>=)
	       ((eq? var *=fx*) '=)))))
   
   (define (inv-op op)
      (case op
	 ((<) '>)
	 ((<=) '>=)
	 ((>) '<)
	 ((>=) '<=)
	 (else op)))
   
   (define (resolve/op i op intl intr)
      (case op
	 ((<)
	  (duplicate::rtl_ins/bbv i
	     (fun (if (bbv-range<? intl intr) (true) (false)))))
	 ((<=)
	  (duplicate::rtl_ins/bbv i
	     (fun (if (bbv-range<=? intl intr) (true) (false)))))
	 ((>=)
	  (duplicate::rtl_ins/bbv i
	     (fun (if (bbv-range>=? intl intr) (true) (false)))))
	 ((>)
	  (duplicate::rtl_ins/bbv i
	     (fun (if (bbv-range>? intl intr) (true) (false)))))
	 ((=)
	  (duplicate::rtl_ins/bbv i
	     (fun (if (bbv-range=? intl intr) (true) (false)))))
	 (else
	  #f)))
   
   (define (test-ctxs-ref reg intl intr op ctx)
      (if (or (not (bbv-range? intl)) (not (bbv-range? intr)))
	  (values ctx ctx)
	  (case op
	     ((<)
	      (let ((intrt (bbv-range-lt intl intr))
		    (intro (bbv-range-gte intl intr)))
		 (values (extend-ctx ctx reg *int* #t :value intrt)
		    (extend-ctx ctx reg *int* #t :value intro))))
	     ((<=)
	      (let ((intrt (bbv-range-lte intl intr))
		    (intro (bbv-range-gt intl intr)))
		 (values (extend-ctx ctx reg *int* #t :value intrt)
		    (extend-ctx ctx reg *int* #t :value intro))))
	     ((>)
	      (let ((intrt (bbv-range-gt intl intr))
		    (intro (bbv-range-lte intl intr)))
		 (values (extend-ctx ctx reg *int* #t :value intrt)
		    (extend-ctx ctx reg *int* #t :value intro))))
	     ((>=)
	      (let ((intrt (bbv-range-gte intl intr))
		    (intro (bbv-range-lt intl intr)))
		 (values (extend-ctx ctx reg *int* #t :value intrt)
		    (extend-ctx ctx reg *int* #t :value intro))))
	     ((== ===)
	      (let ((ieq (bbv-range-eq intl intr)))
		 (values (if (bbv-range? ieq)
			     (extend-ctx ctx reg *int* #t :value ieq)
			     ctx)
		    ctx)))
	     ((!= !==)
	      (let ((ieq (bbv-range-eq intl intr)))
		 (values
		    ctx
		    (if (bbv-range? ieq)
			(extend-ctx ctx reg *int* #t :value ieq)
			ctx))))
	     (else
	      (values ctx ctx)))))
   
   (define (specialize/op op lhs intl rhs intr sctx)
      (cond
	 ((and (reg? lhs) (reg? rhs))
	  (multiple-value-bind (lctxt lctxo)
	     (test-ctxs-ref (reg lhs) intl intr op sctx)
	     (multiple-value-bind (rctxt rctxo)
		(test-ctxs-ref (reg rhs) intr intl (inv-op op) '())
		(values (append rctxt lctxt) (append rctxo lctxo)))))
	 ((reg? lhs)
	  (test-ctxs-ref (reg lhs) intl intr op sctx))
	 ((reg? rhs)
	  (test-ctxs-ref (reg rhs) intr intl (inv-op op) sctx))
	 (else
	  (values #f #f))))
   
   (define (specialize-call i::rtl_ins ctx)
      (with-access::rtl_ins i (fun args)
	 (with-access::rtl_call fun (var)
	    (let* ((lhs (car args))
		   (rhs (cadr args))
		   (intl (rtl-range lhs ctx))
		   (intr (rtl-range rhs ctx))
		   (op (fxcmp-op i)))
	       (tprint "FX op=" (shape i) " " (typeof intl) " " (typeof intr)
		  " rhs=" (shape rhs) " TO=" (typeof rhs))
	       (cond
		  ((not (and (bbv-range? intl) (bbv-range? intr)))
		   (tprint "fx.1")
		   (multiple-value-bind (pctx nctx)
		      (specialize/op op lhs (or intl (fixnum-range))
			 rhs (or intr (fixnum-range)) ctx)
		      (values i pctx nctx)))
		  ((resolve/op i op intl intr)
		   =>
		   (lambda (ni)
		      (tprint "fx.2")
		      (values ni ctx ctx)))
		  (else
		   (tprint "fx.3")
		   (multiple-value-bind (pctx nctx)
		      (specialize/op op lhs intl rhs intr ctx)
		      (values i pctx nctx))))))))
   
   (with-access::rtl_ins i (dest fun args)
      (tprint "FUN=" (shape i) " " (map typeof args))
      (cond
	 ((isa? fun rtl_ifeq)
	  (with-access::rtl_ifeq fun (then)
	     (multiple-value-bind (ins pctx nctx)
		(specialize-call (car args) ctx)
		(tprint "INS.1=" (shape ins))
		(let ((f (duplicate::rtl_ifeq fun
			    (then (bbv-block then nctx)))))
		   (values (duplicate::rtl_ins/bbv i
			      (ctx ctx)
			      (args (list ins))
			      (fun f))
		      pctx)))))
;* 	 ((isa? fun rtl_ifne)                                          */
;* 	  (multiple-value-bind (ins pctx nctx)                         */
;* 	     (specialize-call (car args) ctx)                          */
;* 	     (tprint "INS.2=" (shape ins))                             */
;* 	     (values (duplicate::rtl_ins/bbv i                         */
;* 			(ctx ctx))                                     */
;* 		nctx)))                                                */
;* 	 ((isa? fun rtl_call)                                          */
;* 	  'todo)                                                       */
	 (else
	  (values (duplicate::rtl_ins/bbv i
		     (ctx ctx))
	     ctx)))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize ...                                           */
;*    -------------------------------------------------------------    */
;*    Specialize an instruction according to the typing context.       */
;*    Returns the new instruction and the new context.                 */
;*---------------------------------------------------------------------*/
(define (rtl_ins-specialize-TBR i::rtl_ins ctx::pair-nil)
   (with-trace 'bbv-ins "rtl_ins-specialize"
      (trace-item "ins=" (shape i))
      (trace-item "ctx=" (ctx->string ctx))
      (cond
;* 	 ((rtl_ins-last? i)                                            */
;* 	  (tprint "SHOULD NOT...")                                     */
;* 	  (values i (extend-ctx ctx (rtl_ins-dest i) *obj* #t)))       */
;* 	 ((rtl_ins-typecheck? i)                                       */
;* 	  (tprint "SHOULD NOT....")                                    */
;* 	  (rtl_ins-specialize-typecheck-old i ctx))                    */
;* 	 ((rtl_ins-vector-bound-check? i)                              */
;* 	  (rtl_ins-specialize-vector-bound-check i ctx))               */
;*  	 ((rtl_ins-bool? i)                                            */
;* 	  (rtl_ins-specialize-bool i ctx))                             */
	 ((rtl_ins-go? i)
	  ;; have to duplicate the instruction to break "to" sharing
	  (tprint "SHOULD NOT....")
	  (with-access::rtl_ins i (fun)
	     (let ((s (duplicate::rtl_ins/bbv i
			 (fun (duplicate::rtl_go fun)))))
		(values s ctx))))
	 ((not (rtl_reg? (rtl_ins-dest i)))
	  (tprint "SHOULD NOT....")
	  (values i ctx))
	 ((rtl_ins-mov? i)
	  (tprint "SHOULD NOT....")
	  (with-access::rtl_ins i (dest args fun)
	     (cond
		((and (pair? args) (null? (cdr args)) (rtl_reg/ra? (car args)))
		 (values i (alias-ctx ctx dest (car args))))
		((and *type-call* (pair? args) (rtl_ins-call? (car args)))
		 (with-access::rtl_ins (car args) (fun)
		    (with-access::rtl_call fun (var)
		       (with-access::global var (value type)
			  (values i (extend-normalize-ctx ctx dest type #t))))))
		(else
		 (values i (extend-ctx ctx dest *obj* #t))))))
	 ((rtl_ins-ifeq? i)
	  ;; have to duplicate the instruction to break "to" sharing
	  (case (bool-value (car (rtl_ins-args i)) ctx)
	     ((true)
	      (tprint "ifeq.TRUE...")
	      (let ((s (duplicate::rtl_ins/bbv i
			  (fun (instantiate::rtl_nop)))))
		 (values s ctx)))
	     ((false)
	      (tprint "ifeq.FALSE...")
	      (with-access::rtl_ins i (fun)
		 (with-access::rtl_ifeq fun (then)
		    (let ((s (duplicate::rtl_ins/bbv i
				(fun (instantiate::rtl_go
					(to then))))))
		       (values s ctx)))))
	     (else
	      (with-access::rtl_ins i (fun)
		 (let ((s (duplicate::rtl_ins/bbv i
			     (fun (if (isa? fun rtl_ifeq)
				      (duplicate::rtl_ifeq fun)
				      (duplicate::rtl_ifne fun))))))
		    (values s ctx))))))
	 ((rtl_ins-ifne? i)
	  ;; have to duplicate the instruction to break "to" sharing
	  (case (bool-value (car (rtl_ins-args i)) ctx)
	     ((true)
	      (tprint "ifne.TRUE...")
	      (with-access::rtl_ins i (fun)
		 (with-access::rtl_ifeq fun (then)
		    (let ((s (duplicate::rtl_ins/bbv i
				(fun (instantiate::rtl_go
					(to then))))))
		       (values s ctx)))))
	     ((false)
	      (tprint "ifne.FALSE...")
	      (let ((s (duplicate::rtl_ins/bbv i
			  (fun (instantiate::rtl_nop)))))
		 (values s ctx)))
	     (else
	      (with-access::rtl_ins i (fun)
		 (let ((s (duplicate::rtl_ins/bbv i
			     (fun (duplicate::rtl_ifne fun)))))
		    (values s ctx))))))
	 
	 ((and *type-call* (rtl_ins-call? i))
	  (with-access::rtl_ins i (dest fun)
	     (with-access::rtl_call fun (var)
		(with-access::global var (value type)
		   (if (fun? value)
		       (values i (extend-normalize-ctx ctx dest type #t))
		       (values i (extend-ctx ctx dest *obj* #t)))))))
;* 	 ((rtl_ins-vlen? i)                                            */
;* 	  (rtl_ins-specialize-vlength i ctx))                          */
	 (else
	  (values i (extend-ctx ctx (rtl_ins-dest i) *obj* #t))))))

;*---------------------------------------------------------------------*/
;*    rtl_ins-typecheck? ...                                           */
;*    -------------------------------------------------------------    */
;*    Returns the type checked by the instruction or false.            */
;*---------------------------------------------------------------------*/
(define (rtl_ins-typecheck? i::rtl_ins)
   (when (or (rtl_ins-ifeq? i) (rtl_ins-ifne? i))
      (with-access::rtl_ins i (args)
	 (when (and (isa? (car args) rtl_ins) (rtl_ins-call? (car args)))
	    (when (rtl_call-predicate (car args))
	       (let ((args (rtl_ins-args* i)))
		  (and (pair? args) (null? (cdr args)) (rtl_reg? (car args)))))))))

;* {*---------------------------------------------------------------------*} */
;* {*    rtl_ins-specialize-bool ...                                      *} */
;* {*---------------------------------------------------------------------*} */
;* (define (rtl_ins-specialize-bool i ctx)                             */
;*                                                                     */
;*    (define (true)                                                   */
;*       (instantiate::rtl_loadi                                       */
;* 	 (constant (instantiate::literal (type *bool*) (value #t)))))  */
;*                                                                     */
;*    (define (false)                                                  */
;*       (instantiate::rtl_loadi                                       */
;* 	 (constant (instantiate::literal (type *bool*) (value #f)))))  */
;*                                                                     */
;*    (with-access::rtl_ins i (dest fun args)                          */
;*       (with-access::rtl_call fun (var)                              */
;* 	 (cond                                                         */
;* 	    ((and (eq? var *<fx*) (=fx (length args) 2))               */
;* 	     (let ((left (bbv-range-value (car args) ctx))              */
;* 		   (right (bbv-range-value (cadr args) ctx)))           */
;* 		(cond                                                  */
;* 		   ((not (and (bbv-range? left) (bbv-range? right)))     */
;* 		    (values i (extend-ctx ctx dest *bool* #t)))        */
;* 		   ((bbv-range<? left right)                            */
;* 		    (let ((ni (duplicate::rtl_ins/bbv i                */
;* 				 (fun (true)))))                       */
;* 		       (values i (extend-ctx ctx dest *bool* #t :value #t)))) */
;* 		   ((bbv-range>=? left right)                           */
;* 		    (let ((ni (duplicate::rtl_ins/bbv i                */
;* 				 (fun (false)))))                      */
;* 		       (values i (extend-ctx ctx dest *bool* #t :value #f)))) */
;* 		   (else                                               */
;* 		    (values i (extend-ctx ctx dest *bool* #t))))))     */
;* 	    (else                                                      */
;* 	     (with-access::rtl_ins i (dest)                            */
;* 		(values i (extend-ctx ctx dest *bool* #t))))))))       */
;*                                                                     */
;* {*---------------------------------------------------------------------*} */
;* {*    interval-value ...                                               *} */
;* {*---------------------------------------------------------------------*} */
;* (define (interval-value i ctx)                                      */
;*    (cond                                                            */
;*       ((isa? i rtl_reg)                                             */
;*        (let ((e (ctx-get ctx i)))                                   */
;* 	  (when (and e (eq? (bbv-ctxentry-typ e) *int*))               */
;* 	     (let ((v (bbv-ctxentry-value e)))                         */
;* 		(cond                                                  */
;* 		   ((interval? v) v)                                   */
;* 		   ((vector? v) *length-intv*))))))                    */
;*       ((rtl_ins-mov? i)                                             */
;*        (interval-value (car (rtl_ins-args i)) ctx))                 */
;*       ((rtl_ins-call? i)                                            */
;*        (with-access::rtl_ins i (fun)                                */
;* 	  (with-access::rtl_call fun (var)                             */
;* 	     (cond                                                     */
;* 		((eq? var *int->long*)                                 */
;* 		 (interval-value (car (rtl_ins-args i)) ctx))          */
;* 		(else                                                  */
;* 		 #f)))))                                               */
;*       (else                                                         */
;*        #f)))                                                        */

;*---------------------------------------------------------------------*/
;*    bool-value ...                                                   */
;*---------------------------------------------------------------------*/
(define (bool-value i ctx)
   (cond
      ((isa? i rtl_reg)
       (let ((e (ctx-get ctx i)))
	  (cond
	     ((or (not e) (not (eq? (bbv-ctxentry-typ e) *bool*))) '_)
	     ((eq? (bbv-ctxentry-value e) #t) 'true)
	     ((eq? (bbv-ctxentry-value e) #f) 'false)
	     (else '_))))
      ((rtl_ins-mov? i)
       (bool-value (car (rtl_ins-args i)) ctx))
      ((rtl_ins-loadi? i)
       (with-access::rtl_ins i (fun)
	  (with-access::rtl_loadi fun (constant)
	     (cond
		((not (isa? constant literal)) '_)
		((eq? (literal-value constant) #t) 'true)
		((eq? (literal-value constant) #f) 'false)
		(else '_)))))
      (else
       '_)))

;*---------------------------------------------------------------------*/
;*    rtl_ins-specialize-vlength ...                                   */
;*---------------------------------------------------------------------*/
;* (define (rtl_ins-specialize-vlength i ctx)                          */
;*    (with-access::rtl_ins i (dest args)                              */
;*       (cond                                                         */
;* 	 ((not (rtl_reg? (car args)))                                  */
;* 	  (values i (extend-ctx ctx dest *int* #t :value *length-intv*))) */
;* 	 ((find (lambda (e)                                            */
;* 		   (with-access::bbv-ctxentry e (typ value)            */
;* 		      (and (eq? type *int*)                            */
;* 			   (vector? value)                             */
;* 			   (eq? (vector-ref value 0) (car args)))))    */
;* 	     ctx)                                                      */
;* 	  =>                                                           */
;* 	  (lambda (e)                                                  */
;* 	     (values (duplicate::rtl_ins i                             */
;* 			(fun (instantiate::rtl_mov)))                  */
;* 		(alias-ctx ctx dest (car args)))))                     */
;* 	 (else                                                         */
;* 	  (values i (extend-ctx ctx dest *int* #t :value (vector (car args)))))))) */
;*                                                                     */
;* {*---------------------------------------------------------------------*} */
;* {*    rtl_ins-vector-bound-check? ...                                  *} */
;* {*---------------------------------------------------------------------*} */
;* (define (rtl_ins-vector-bound-check? i::rtl_ins)                    */
;*    (when (or (rtl_ins-ifeq? i) (rtl_ins-ifne? i))                   */
;*       (with-access::rtl_ins i (args fun)                            */
;* 	 (tprint "YAP" (shape i) " " (typeof fun))                     */
;* 	 (when (isa? fun rtl_call)                                     */
;* 	    (with-access::rtl_call fun (var)                           */
;* 	       (when (eq? var *vector-bound-check*)                    */
;* 		  (tprint "YIP")                                       */
;* 		  (let ((args (rtl_ins-args* i)))                      */
;* 		     (and (rtl_reg? (car args)) (rtl_reg? (cadr args)))))))))) */
;*                                                                     */
;* {*---------------------------------------------------------------------*} */
;* {*    rtl_ins-specialize-vector-bound-check ...                        *} */
;* {*---------------------------------------------------------------------*} */
;* (define (rtl_ins-specialize-vector-bound-check i::rtl_ins ctx)      */
;*    (tprint "VECTOR-BOUND-CHECK" (shape i))                          */
;*    (tprint "                  " (ctx->string ctx))                  */
;*    (values i (extend-ctx ctx (rtl_ins-dest i) *obj* #t)))           */
