;; ==========================================================
;; Class accessors
;; Bigloo (4.6a)
;; Inria -- Sophia Antipolis     Thu Jul 18 10:44:00 AM CEST 2024 
;; (bigloo BackEnd/backend.scm -classgen)
;; ==========================================================

;; The directives
(directives

;; backend
(cond-expand ((and bigloo-class-sans (not bigloo-class-generate))
  (export
    (inline backend?::bool ::obj)
    (backend-nil::backend)
    (inline backend-string-literal-support::bool ::backend)
    (inline backend-string-literal-support-set! ::backend ::bool)
    (inline backend-force-register-gc-roots::bool ::backend)
    (inline backend-force-register-gc-roots-set! ::backend ::bool)
    (inline backend-strict-type-cast::bool ::backend)
    (inline backend-strict-type-cast-set! ::backend ::bool)
    (inline backend-typed-funcall::bool ::backend)
    (inline backend-typed-funcall-set! ::backend ::bool)
    (inline backend-type-check::bool ::backend)
    (inline backend-type-check-set! ::backend ::bool)
    (inline backend-bound-check::bool ::backend)
    (inline backend-bound-check-set! ::backend ::bool)
    (inline backend-pregisters::pair-nil ::backend)
    (inline backend-pregisters-set! ::backend ::pair-nil)
    (inline backend-registers::pair-nil ::backend)
    (inline backend-registers-set! ::backend ::pair-nil)
    (inline backend-require-tailc::bool ::backend)
    (inline backend-require-tailc-set! ::backend ::bool)
    (inline backend-tvector-descr-support::bool ::backend)
    (inline backend-tvector-descr-support-set! ::backend ::bool)
    (inline backend-pragma-support::bool ::backend)
    (inline backend-pragma-support-set! ::backend ::bool)
    (inline backend-debug-support::pair-nil ::backend)
    (inline backend-debug-support-set! ::backend ::pair-nil)
    (inline backend-foreign-clause-support::pair-nil ::backend)
    (inline backend-foreign-clause-support-set! ::backend ::pair-nil)
    (inline backend-trace-support::bool ::backend)
    (inline backend-trace-support-set! ::backend ::bool)
    (inline backend-typed-eq::bool ::backend)
    (inline backend-typed-eq-set! ::backend ::bool)
    (inline backend-foreign-closure::bool ::backend)
    (inline backend-foreign-closure-set! ::backend ::bool)
    (inline backend-remove-empty-let::bool ::backend)
    (inline backend-remove-empty-let-set! ::backend ::bool)
    (inline backend-effect+::bool ::backend)
    (inline backend-effect+-set! ::backend ::bool)
    (inline backend-qualified-types::bool ::backend)
    (inline backend-qualified-types-set! ::backend ::bool)
    (inline backend-callcc::bool ::backend)
    (inline backend-callcc-set! ::backend ::bool)
    (inline backend-heap-compatible::symbol ::backend)
    (inline backend-heap-compatible-set! ::backend ::symbol)
    (inline backend-heap-suffix::bstring ::backend)
    (inline backend-heap-suffix-set! ::backend ::bstring)
    (inline backend-typed::bool ::backend)
    (inline backend-typed-set! ::backend ::bool)
    (inline backend-types::obj ::backend)
    (inline backend-types-set! ::backend ::obj)
    (inline backend-functions::obj ::backend)
    (inline backend-functions-set! ::backend ::obj)
    (inline backend-variables::obj ::backend)
    (inline backend-variables-set! ::backend ::obj)
    (inline backend-extern-types::obj ::backend)
    (inline backend-extern-types-set! ::backend ::obj)
    (inline backend-extern-functions::obj ::backend)
    (inline backend-extern-functions-set! ::backend ::obj)
    (inline backend-extern-variables::obj ::backend)
    (inline backend-extern-variables-set! ::backend ::obj)
    (inline backend-name::bstring ::backend)
    (inline backend-name-set! ::backend ::bstring)
    (inline backend-srfi0::symbol ::backend)
    (inline backend-srfi0-set! ::backend ::symbol)
    (inline backend-language::symbol ::backend)
    (inline backend-language-set! ::backend ::symbol)))))

;; The definitions
(cond-expand (bigloo-class-sans
;; backend
(define-inline (backend?::bool obj::obj) ((@ isa? __object) obj (@ backend backend_backend)))
(define (backend-nil::backend) (class-nil (@ backend backend_backend)))
(define-inline (backend-string-literal-support::bool o::backend) (-> |#!bigloo_wallow| o string-literal-support))
(define-inline (backend-string-literal-support-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o string-literal-support) v))
(define-inline (backend-force-register-gc-roots::bool o::backend) (-> |#!bigloo_wallow| o force-register-gc-roots))
(define-inline (backend-force-register-gc-roots-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o force-register-gc-roots) v))
(define-inline (backend-strict-type-cast::bool o::backend) (-> |#!bigloo_wallow| o strict-type-cast))
(define-inline (backend-strict-type-cast-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o strict-type-cast) v))
(define-inline (backend-typed-funcall::bool o::backend) (-> |#!bigloo_wallow| o typed-funcall))
(define-inline (backend-typed-funcall-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o typed-funcall) v))
(define-inline (backend-type-check::bool o::backend) (-> |#!bigloo_wallow| o type-check))
(define-inline (backend-type-check-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o type-check) v))
(define-inline (backend-bound-check::bool o::backend) (-> |#!bigloo_wallow| o bound-check))
(define-inline (backend-bound-check-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o bound-check) v))
(define-inline (backend-pregisters::pair-nil o::backend) (-> |#!bigloo_wallow| o pregisters))
(define-inline (backend-pregisters-set! o::backend v::pair-nil) (set! (-> |#!bigloo_wallow| o pregisters) v))
(define-inline (backend-registers::pair-nil o::backend) (-> |#!bigloo_wallow| o registers))
(define-inline (backend-registers-set! o::backend v::pair-nil) (set! (-> |#!bigloo_wallow| o registers) v))
(define-inline (backend-require-tailc::bool o::backend) (-> |#!bigloo_wallow| o require-tailc))
(define-inline (backend-require-tailc-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o require-tailc) v))
(define-inline (backend-tvector-descr-support::bool o::backend) (-> |#!bigloo_wallow| o tvector-descr-support))
(define-inline (backend-tvector-descr-support-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o tvector-descr-support) v))
(define-inline (backend-pragma-support::bool o::backend) (-> |#!bigloo_wallow| o pragma-support))
(define-inline (backend-pragma-support-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o pragma-support) v))
(define-inline (backend-debug-support::pair-nil o::backend) (-> |#!bigloo_wallow| o debug-support))
(define-inline (backend-debug-support-set! o::backend v::pair-nil) (set! (-> |#!bigloo_wallow| o debug-support) v))
(define-inline (backend-foreign-clause-support::pair-nil o::backend) (-> |#!bigloo_wallow| o foreign-clause-support))
(define-inline (backend-foreign-clause-support-set! o::backend v::pair-nil) (set! (-> |#!bigloo_wallow| o foreign-clause-support) v))
(define-inline (backend-trace-support::bool o::backend) (-> |#!bigloo_wallow| o trace-support))
(define-inline (backend-trace-support-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o trace-support) v))
(define-inline (backend-typed-eq::bool o::backend) (-> |#!bigloo_wallow| o typed-eq))
(define-inline (backend-typed-eq-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o typed-eq) v))
(define-inline (backend-foreign-closure::bool o::backend) (-> |#!bigloo_wallow| o foreign-closure))
(define-inline (backend-foreign-closure-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o foreign-closure) v))
(define-inline (backend-remove-empty-let::bool o::backend) (-> |#!bigloo_wallow| o remove-empty-let))
(define-inline (backend-remove-empty-let-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o remove-empty-let) v))
(define-inline (backend-effect+::bool o::backend) (-> |#!bigloo_wallow| o effect+))
(define-inline (backend-effect+-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o effect+) v))
(define-inline (backend-qualified-types::bool o::backend) (-> |#!bigloo_wallow| o qualified-types))
(define-inline (backend-qualified-types-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o qualified-types) v))
(define-inline (backend-callcc::bool o::backend) (-> |#!bigloo_wallow| o callcc))
(define-inline (backend-callcc-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o callcc) v))
(define-inline (backend-heap-compatible::symbol o::backend) (-> |#!bigloo_wallow| o heap-compatible))
(define-inline (backend-heap-compatible-set! o::backend v::symbol) (set! (-> |#!bigloo_wallow| o heap-compatible) v))
(define-inline (backend-heap-suffix::bstring o::backend) (-> |#!bigloo_wallow| o heap-suffix))
(define-inline (backend-heap-suffix-set! o::backend v::bstring) (set! (-> |#!bigloo_wallow| o heap-suffix) v))
(define-inline (backend-typed::bool o::backend) (-> |#!bigloo_wallow| o typed))
(define-inline (backend-typed-set! o::backend v::bool) (set! (-> |#!bigloo_wallow| o typed) v))
(define-inline (backend-types::obj o::backend) (-> |#!bigloo_wallow| o types))
(define-inline (backend-types-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o types) v))
(define-inline (backend-functions::obj o::backend) (-> |#!bigloo_wallow| o functions))
(define-inline (backend-functions-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o functions) v))
(define-inline (backend-variables::obj o::backend) (-> |#!bigloo_wallow| o variables))
(define-inline (backend-variables-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o variables) v))
(define-inline (backend-extern-types::obj o::backend) (-> |#!bigloo_wallow| o extern-types))
(define-inline (backend-extern-types-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o extern-types) v))
(define-inline (backend-extern-functions::obj o::backend) (-> |#!bigloo_wallow| o extern-functions))
(define-inline (backend-extern-functions-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o extern-functions) v))
(define-inline (backend-extern-variables::obj o::backend) (-> |#!bigloo_wallow| o extern-variables))
(define-inline (backend-extern-variables-set! o::backend v::obj) (set! (-> |#!bigloo_wallow| o extern-variables) v))
(define-inline (backend-name::bstring o::backend) (-> |#!bigloo_wallow| o name))
(define-inline (backend-name-set! o::backend v::bstring) (set! (-> |#!bigloo_wallow| o name) v))
(define-inline (backend-srfi0::symbol o::backend) (-> |#!bigloo_wallow| o srfi0))
(define-inline (backend-srfi0-set! o::backend v::symbol) (set! (-> |#!bigloo_wallow| o srfi0) v))
(define-inline (backend-language::symbol o::backend) (-> |#!bigloo_wallow| o language))
(define-inline (backend-language-set! o::backend v::symbol) (set! (-> |#!bigloo_wallow| o language) v))
))
