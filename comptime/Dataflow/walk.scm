;*=====================================================================*/
;*    serrano/prgm/project/bigloo/comptime/Dataflow/walk.scm           */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Nov 26 08:17:46 2010                          */
;*    Last change :  Mon Nov 29 08:14:29 2010 (serrano)                */
;*    Copyright   :  2010 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Compute variable references according to dataflow tests. E.G.,   */
;*    for an expression such as (if (pair? x) then else), propagate    */
;*    x::pair in the the branch.                                       */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module dataflow_walk
   (include "Engine/pass.sch"
	    "Tools/trace.sch")
   (import  tools_error
	    tools_shape
	    type_type
	    type_typeof
	    type_cache
	    ast_var
	    ast_node
	    effect_cgraph
	    effect_spread
	    effect_feffect
	    engine_param)
   (static  (wide-class local/value::local
	       (node::node read-only)))
   (export  (dataflow-walk! globals)))

;*---------------------------------------------------------------------*/
;*    dataflow-walk! ...                                               */
;*---------------------------------------------------------------------*/
(define (dataflow-walk! globals)
   (pass-prelude "Dataflow")
   (for-each dataflow-global! globals)
   (pass-postlude globals))

;*---------------------------------------------------------------------*/
;*    dataflow-global! ...                                             */
;*---------------------------------------------------------------------*/
(define (dataflow-global! global)
   (dataflow-node! (sfun-body (global-value global)) '()))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::node ...                                        */
;*---------------------------------------------------------------------*/
(define-generic (dataflow-node!::pair-nil node::node env::pair-nil)
   env)

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::var ...                                         */
;*    -------------------------------------------------------------    */
;*    This function sets the most specific for the variable            */
;*    reference (computed according to the control flow). The          */
;*    stage globalize and integrate that introduce cells change        */
;*    the type of the boxed variable references (see globalize_node    */
;*    and integrate_node).                                             */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::var env)
   (with-access::var node (type variable)
      (let ((b (assq variable env)))
	 (if (pair? b)
	     (set! type (cdr b))
	     (set! type (variable-type variable)))))
   env)

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::sequence ...                                    */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::sequence env)
   (let loop ((node* (sequence-nodes node))
	      (env env))
      (if (null? node*)
	  env
	  (loop (cdr node*) (dataflow-node! (car node*) env)))))
	  
;*---------------------------------------------------------------------*/
;*    dataflow-node! ::app ...                                         */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::app env)
   (with-access::app node (fun args)
      (let ((aenv (dataflow-node*! args env)))
	 (if (and (var? fun) (local? (var-variable fun)))
	     ;; when a local variable, all the locals that are not
	     ;; read-only have to be removed from the environment
	     ;; because they might be affected by the called function
	     (filter (lambda (b)
			(let ((v (car b)))
			   (or (global? v) (eq? (variable-access v) 'read))))
		     aenv)
	     aenv))))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::app-ly ...                                      */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::app-ly env)
   (with-access::app-ly node (fun arg)
      (dataflow-node! fun env)
      (dataflow-node! arg env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::funcall ...                                     */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::funcall env)
   (with-access::funcall node (fun args)
      (dataflow-node! fun env)
      (dataflow-node*! args env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::extern ...                                      */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::extern env)
   (let ((nodes (extern-expr* node)))
      (dataflow-node*! nodes env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::setq ...                                        */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::setq env)
   (with-access::setq node (var value)
      (dataflow-node! value env)
      (with-access::var var (variable)
	 (if (global? variable)
	     env
	     (let ((typ (get-type value)))
		(if (or (eq? typ *_*) (eq? typ *obj*))
		    env
		    (cons (cons variable typ) env)))))))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::conditional ...                                 */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::conditional env)
   (with-access::conditional node (test true false)
      (let* ((tenv (dataflow-node! test env))
	     (true-env (append (dataflow-test-env test) tenv)))
	 (dataflow-node! false env)
	 (dataflow-node! true true-env)
	 (if (conditional-branch-exit? false)
	     true-env
	     env))))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::fail ...                                        */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::fail env)
   (with-access::fail node (proc msg obj)
      (dataflow-node! proc env)
      (dataflow-node! msg env)
      (dataflow-node! obj env)
      env))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::select ...                                      */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::select env)
   (with-access::select node (test clauses)
      (dataflow-node! test env)
      (for-each (lambda (clause)
		   (dataflow-node! (cdr clause) env))
		clauses)
      env))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::let-fun ...                                     */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::let-fun env)
   (with-access::let-fun node (body locals)
      (for-each (lambda (local)
		   (dataflow-node! (sfun-body (local-value local)) env))
		locals)
      (dataflow-node! body env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::let-var ...                                     */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::let-var env)
   (with-access::let-var node (body bindings)
      (for-each (lambda (binding)
		   (dataflow-node! (cdr binding) env)
		   (let ((l (car binding)))
		      (when (eq? (variable-access l) 'read)
			 (widen!::local/value l
			    (node (cdr binding))))))
		bindings)
      (dataflow-node! body env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::set-ex-it ...                                   */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::set-ex-it env)
   (with-access::set-ex-it node (var)
      (dataflow-node! (set-ex-it-body node) env)
      '()))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::jump-ex-it ...                                  */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::jump-ex-it env)
   (with-access::jump-ex-it node (exit value)
      (dataflow-node! exit env)
      (dataflow-node! value env)
      '()))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::make-box ...                                    */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::make-box env)
   (dataflow-node! (make-box-value node) env))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::box-ref ...                                     */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::box-ref env)
   (with-access::box-ref node (var)
      (node-type-set! var *obj*)
      env))

;*---------------------------------------------------------------------*/
;*    dataflow-node! ::box-set! ...                                    */
;*---------------------------------------------------------------------*/
(define-method (dataflow-node! node::box-set! env)
   (with-access::box-set! node (var value)
      (node-type-set! var *obj*)
      (dataflow-node! value env)))

;*---------------------------------------------------------------------*/
;*    dataflow-node*! ...                                              */
;*---------------------------------------------------------------------*/
(define (dataflow-node*! node* env)
   (for-each (lambda (n) (dataflow-node! n env)) node*)
   env)

;*---------------------------------------------------------------------*/
;*    dataflow-test-env ...                                            */
;*---------------------------------------------------------------------*/
(define-generic (dataflow-test-env::pair-nil node::node)
   '())

;*---------------------------------------------------------------------*/
;*    dataflow-test-env ::app ...                                      */
;*---------------------------------------------------------------------*/
(define-method (dataflow-test-env node::app)
   (with-access::app node (fun args)
      (if (and (fun? (variable-value (var-variable fun)))
	       (fun-predicate-of (variable-value (var-variable fun)))
	       (pair? args) (null? (cdr args))
	       (var? (car args)))
	  (let ((typ (fun-predicate-of (variable-value (var-variable fun))))
		(var (var-variable (car args))))
	     (list (cons var typ)))
	  '())))

;*---------------------------------------------------------------------*/
;*    dataflow-test-env ::conditional ...                              */
;*---------------------------------------------------------------------*/
(define-method (dataflow-test-env node::conditional)
   (with-access::conditional node (test true false)
      (if (and (atom? false) (eq? (atom-value false) #f))
	  (append (dataflow-test-env test) (dataflow-test-env true))
	  '())))

;*---------------------------------------------------------------------*/
;*    dataflow-test-env ::var ...                                      */
;*---------------------------------------------------------------------*/
(define-method (dataflow-test-env node::var)
   (with-access::var node (variable)
      (if (local/value? variable)
	  (dataflow-test-env (local/value-node variable))
	  '())))

;*---------------------------------------------------------------------*/
;*    dataflow-test-env ::let-var ...                                  */
;*    -------------------------------------------------------------    */
;*    We detect the pattern:                                           */
;*      (let ((tmp exp))                                               */
;*         (<predicate> tmp))                                          */
;*---------------------------------------------------------------------*/
(define-method (dataflow-test-env node::let-var)
   (with-access::let-var node (bindings body)
      (if (and (pair? bindings)
		 (null? (cdr bindings))
		 (var? (cdar bindings)))
	  (let ((env (dataflow-test-env body)))
	     (if (and (pair? env)
		      (null? (cdr env))
		      (eq? (caar env) (caar bindings)))
		 (list (cons (var-variable (cdar bindings))
			     (cdar env)))
		 '()))
	  '())))

;*---------------------------------------------------------------------*/
;*    conditional-branch-exit? ::node ...                              */
;*---------------------------------------------------------------------*/
(define-generic (conditional-branch-exit? node::node)
   #f)
