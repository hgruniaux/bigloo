/*=====================================================================*/
/*    .../prgm/project/bigloo/api/pthread/src/Posix/bglpthread.c       */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Fri Feb 22 12:12:04 2002                          */
/*    Last change :  Tue Nov  3 09:31:37 2009 (serrano)                */
/*    Copyright   :  2002-09 Manuel Serrano                            */
/*    -------------------------------------------------------------    */
/*    C utilities for native Bigloo fair threads implementation.       */
/*=====================================================================*/
#include <pthread.h>
#include <sched.h>
#include <stdlib.h>
#include <string.h>

#define GC_PRIVATE_H
#include <gc.h>
#include <bglpthread.h>

#if HAVE_SIGACTION
#include <signal.h>
#endif

/*---------------------------------------------------------------------*/
/*    Imports                                                          */
/*---------------------------------------------------------------------*/
BGL_RUNTIME_DECL void bgl_multithread_dynamic_denv_register();
BGL_RUNTIME_DECL obj_t bgl_remq_bang( obj_t, obj_t );

/*---------------------------------------------------------------------*/
/*    pthread_key_t                                                    */
/*    bgldenv_key ...                                                  */
/*---------------------------------------------------------------------*/
static pthread_key_t bgldenv_key;

/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_single_thread_denv ...                                    */
/*---------------------------------------------------------------------*/
static obj_t bglpth_single_thread_denv = 0L;

/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_thread_gc_conservative_mark_envs ...                      */
/*    -------------------------------------------------------------    */
/*    It is unclear if the Boehm's collector is able to track          */
/*    objects pointed to by by thread-local-storage variables.         */
/*    Since these variables are exclusively used in Bigloo to store    */
/*    the thread-specific environments, these environments are         */
/*    also backed up in a global static variables.                     */
/*---------------------------------------------------------------------*/
#if( BGL_HAS_THREAD_LOCALSTORAGE )
static obj_t gc_conservative_mark_envs = BNIL;
static pthread_mutex_t gc_conservative_mark_mutex;
#endif

/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_dynamic_env ...                                           */
/*---------------------------------------------------------------------*/
obj_t
bglpth_dynamic_env() {
   obj_t env = pthread_getspecific( bgldenv_key );

   /* env might be null when bglpth_dynamic_env is */
   /* called from a non Bigloo thread              */
   return env ? env : bglpth_single_thread_denv;
}
 
/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_dynamic_env_set ...                                       */
/*---------------------------------------------------------------------*/
static obj_t
bglpth_dynamic_env_set( obj_t env ) {
#if( BGL_HAS_THREAD_LOCALSTORAGE )
   single_thread_denv = env;
#else
   pthread_setspecific( bgldenv_key, env );
#endif
   
   return env;
}

/*---------------------------------------------------------------------*/
/*    bglpthread_t                                                     */
/*    bglpth_thread_new ...                                            */
/*---------------------------------------------------------------------*/
bglpthread_t
bglpth_thread_new( obj_t thunk ) {
   bglpthread_t t = (bglpthread_t)GC_MALLOC( sizeof( struct bglpthread ) );

   pthread_mutex_init( &(t->mutex), 0L );
   pthread_cond_init( &(t->condvar), 0L );

   t->thunk = thunk;
   t->specific = BUNSPEC;
   t->cleanup = BUNSPEC;
   t->status = 0;

   t->mutexes = 0;
   
   return t;
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_thread_cleanup ...                                        */
/*---------------------------------------------------------------------*/
void
bglpth_thread_cleanup( void *arg ) {
   bglpthread_t self = (bglpthread_t)arg;
   obj_t cleanup = self->cleanup;

   /* lock the internal state of the thread */
   pthread_mutex_lock( &(self->mutex) );
   
   /* mark the thread terminated */
   self->status = 2;
   
   /* unlock all locked mutexes */
   bglpth_mutexes_unlock( self );
   
   /* unlock the internal state of the thread */
   pthread_mutex_unlock( &(self->mutex) );
   
#if( BGL_HAS_THREAD_LOCALSTORAGE )
   pthread_mutex_lock( &gc_conservative_mark_mutex );
   gc_conservative_mark_envs =
      bgl_remq_bang( self->env, gc_conservative_mark_envs );
   pthread_mutex_unlock( &gc_conservative_mark_mutex );
#endif
   
   /* invoke user cleanup */
   if( PROCEDUREP( cleanup ) ) {
      PROCEDURE_ENTRY( cleanup )( cleanup, self->bglthread, BEOA );
   }
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_thread_init ...                                           */
/*---------------------------------------------------------------------*/
void
bglpth_thread_init( bglpthread_t self, char *stack_bottom ) {
   /* The environment is stored in a specific variable for dynamic   */
   /* access but it is pointed to by the thread structure for the GC */
   bglpth_dynamic_env_set( self->env );

   BGL_DYNAMIC_ENV( self->env ).stack_bottom = stack_bottom;
   BGL_DYNAMIC_ENV( self->env ).current_thread = self;
   
   bgl_init_trace();
}

/*---------------------------------------------------------------------*/
/*    static void *                                                    */
/*    bglpth_thread_run ...                                            */
/*---------------------------------------------------------------------*/
static void *
bglpth_thread_run( void *arg ) {
   bglpthread_t self = (bglpthread_t)arg;
   obj_t thunk = self->thunk;

   bglpth_thread_init( self, (char *)&arg );
   
   pthread_setcanceltype( PTHREAD_CANCEL_ASYNCHRONOUS, 0 );
   
   pthread_cleanup_push( bglpth_thread_cleanup, arg );
   
   /* mark the thread started */
   pthread_mutex_lock( &(self->mutex) );
   self->status = 1;
   pthread_cond_broadcast( &(self->condvar) );
   pthread_mutex_unlock( &(self->mutex) );

   /* enter the user code */
   PROCEDURE_ENTRY( thunk )( thunk, BEOA );
   pthread_cleanup_pop( 1 );

   /* returns self so the GC is unable to collect self (and the */
   /* thread specific dynamic env) until the thread completes   */
   return (void *)self;
}

/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_thread_thunk ...                                          */
/*---------------------------------------------------------------------*/
obj_t bglpth_thread_thunk( bglpthread_t thread ) {
   return thread->thunk;
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_thread_env_create ...                                     */
/*---------------------------------------------------------------------*/
void
bglpth_thread_env_create( bglpthread_t thread, obj_t bglthread ) {
   thread->bglthread = bglthread;
   thread->env = bgl_dup_dynamic_env( BGL_CURRENT_DYNAMIC_ENV() );

#if( BGL_HAS_THREAD_LOCALSTORAGE )
   pthread_mutex_lock( &gc_conservative_mark_mutex );
   gc_conservative_mark_envs =
      MAKE_PAIR( thread->env, gc_conservative_mark_envs );
   pthread_mutex_unlock( &gc_conservative_mark_mutex );
#endif
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_thread_start ...                                          */
/*---------------------------------------------------------------------*/
void
bglpth_thread_start( bglpthread_t thread, obj_t bglthread, bool_t dt ) {
   pthread_attr_t a;

   pthread_attr_init( &a );

   if( dt ) pthread_attr_setdetachstate( &a, PTHREAD_CREATE_DETACHED );

   bglpth_thread_env_create( thread, bglthread );
   
   if( pthread_create( &(thread->pthread), &a, bglpth_thread_run, thread ) )
      FAILURE( string_to_bstring( "thread-start!" ),
	       string_to_bstring( "Cannot start thread" ),
	       string_to_bstring( strerror( errno ) ) );
}

/*---------------------------------------------------------------------*/
/*    bglpthread_t                                                     */
/*    bglpth_current_pthread ...                                       */
/*---------------------------------------------------------------------*/
bglpthread_t
bglpth_current_pthread() {
   obj_t env = BGL_CURRENT_DYNAMIC_ENV();

   return env ? BGL_DYNAMIC_ENV( env ).current_thread : 0;
}

/*---------------------------------------------------------------------*/
/*    obj_t                                                            */
/*    bglpth_current_thread ...                                        */
/*---------------------------------------------------------------------*/
obj_t
bglpth_current_thread() {
   bglpthread_t cur = bglpth_current_pthread();

   return cur ? cur->bglthread : BUNSPEC;
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_thread_join ...                                           */
/*---------------------------------------------------------------------*/
void
bglpth_thread_join( bglpthread_t t ) {
   pthread_mutex_lock( &(t->mutex) );
   if( !t->status ) {
      pthread_cond_wait( &(t->condvar), &(t->mutex) );
   }
   pthread_mutex_unlock( &(t->mutex) );

   if( pthread_join( t->pthread, 0L ) ) {
      FAILURE( string_to_bstring( "thread-join!" ),
	       string_to_bstring( "Cannot join thread" ),
	       string_to_bstring( strerror( errno ) ) );
   }
}

/*---------------------------------------------------------------------*/
/*    bool_t                                                           */
/*    bglpth_thread_terminate ...                                      */
/*---------------------------------------------------------------------*/
bool_t
bglpth_thread_terminate( bglpthread_t t ) {
   pthread_mutex_lock( &(t->mutex) );
   if( t->status != 2 ) {
      pthread_cancel( t->pthread );
      pthread_mutex_unlock( &(t->mutex) );
      return 1;
   } else {
      pthread_mutex_unlock( &(t->mutex) );
      return 0;
   }
}

/*---------------------------------------------------------------------*/
/*    void                                                             */
/*    bglpth_setup_thread ...                                          */
/*---------------------------------------------------------------------*/
void
bglpth_setup_thread() {
#if HAVE_SIGACTION
   struct sigaction sigact;
   sigemptyset( &(sigact.sa_mask) );
   sigact.sa_handler = SIG_IGN;
   sigact.sa_flags = SA_RESTART;
   sigaction( SIGPIPE, &sigact, NULL );
#else
   signal( SIGPIPE, SIG_IGN );
#endif

   /* main dynamic env init */
   bgl_init_dynamic_env();

   /* keep the environment in a global for the GC */
   bglpth_single_thread_denv = single_thread_denv;

   /* create the key when a global structure is used */
#if( !BGL_HAS_THREAD_LOCALSTORAGE )
   pthread_key_create( &bgldenv_key, 0L );
#endif
   
   /* store it in a thread variable */
   bglpth_dynamic_env_set( single_thread_denv );

   /* mark the main environment as multithreaded */
#if( !BGL_HAS_THREAD_LOCALSTORAGE )
   single_thread_denv = 0;
   bgl_multithread_dynamic_denv_register( &bglpth_dynamic_env );
#else
   pthread_mutex_init( &gc_conservative_mark_mutex, 0L );
#endif
}
