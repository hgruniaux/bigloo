;*=====================================================================*/
;*    .../prgm/project/bigloo/bigloo/api/mqtt/src/Llib/mqtt.scm        */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Oct 12 14:57:58 2001                          */
;*    Last change :  Wed Mar 16 17:58:46 2022 (serrano)                */
;*    Copyright   :  2001-22 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    MQTT protocol                                                    */
;*    -------------------------------------------------------------    */
;*    See https://mqtt.org/mqtt-specification/                         */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __mqtt_mqtt
   
   (export (class mqtt-control-packet
	      (type::byte read-only)
	      (flags::byte read-only)
	      (properties::pair-nil (default '()))
	      (payload (default #f)))
	   
	   (class mqtt-connect-packet::mqtt-control-packet
	      (version::long (default -1))
	      (connect-flags::long (default -1))
	      (keep-alive::long (default -1))
	      (client-id::bstring (default ""))
	      (will-topic::bstring (default ""))
	      (will-message::obj (default #f))
	      (username::bstring (default ""))
	      (password::obj (default #f)))

	   (class mqtt-publish-packet::mqtt-control-packet
	      (topic::bstring (default "")))
	   
	   (class mqtt-subscribe-packet::mqtt-control-packet
	      (ident::long (default -1)))

	   (inline MQTT-VERSION)
	   (inline MQTT-CPT-RESERVED)
	   (inline MQTT-CPT-CONNECT)
	   (inline MQTT-CPT-CONNACK)
	   (inline MQTT-CPT-PUBLISH)
	   (inline MQTT-CPT-PUBACK)
	   (inline MQTT-CPT-PUBREC)
	   (inline MQTT-CPT-PUBREL)
	   (inline MQTT-CPT-PUBCOMP)
	   (inline MQTT-CPT-SUBSCRIBE)
	   (inline MQTT-CPT-SUBACK)
	   (inline MQTT-CPT-UNSUBSCRIBE)
	   (inline MQTT-CPT-UNSUBACK)
	   (inline MQTT-CPT-PINGREQ)
	   (inline MQTT-CPT-PINGRESP)
	   (inline MQTT-CPT-DISCONNECT)
	   (inline MQTT-CPT-AUTH)
	   
	   (inline MQTT-CONFLAG-CLEAN-START)
	   (inline MQTT-CONFLAG-WILL-FLAG)
	   (inline MQTT-CONFLAG-WILL-QOSL)
	   (inline MQTT-CONFLAG-WILL-QOSH)
	   (inline MQTT-CONFLAG-WILL-RETAIN)
	   (inline MQTT-CONFLAG-PASSWORD-FLAG)
	   (inline MQTT-CONFLAG-USERNAME-FLAG)

	   (inline MQTT-PROPERTY-PAYLOAD-FORMAT-INDICATOR)
	   (inline MQTT-PROPERTY-MESSAGE-EXPIRY-INTERVAL)
	   (inline MQTT-PROPERTY-MESSAGE-CONTENT-TYPE)
	   (inline MQTT-PROPERTY-MESSAGE-RESPONSE-TOPIC)
	   (inline MQTT-PROPERTY-MESSAGE-CORRELATION-DATA)
	   (inline MQTT-PROPERTY-MESSAGE-SUBSCRIPTION-IDENTIFIER)
	   (inline MQTT-PROPERTY-SESSION-EXPIRY-INTERVAL)
	   (inline MQTT-PROPERTY-ASSIGNED-CLIENT-IDENTIFIER)
	   (inline MQTT-PROPERTY-SERVER-KEEP-ALIVE)
	   (inline MQTT-PROPERTY-AUTHENTICATION-METHOD)
	   (inline MQTT-PROPERTY-AUTHENTICATION-DATA)
	   (inline MQTT-PROPERTY-REQUEST-PROBLEM-INFORMATION)
	   (inline MQTT-PROPERTY-WILL-DELAY-INTERVAL)
	   (inline MQTT-PROPERTY-REQUEST-RESPONSE-INFORMATION)
	   (inline MQTT-PROPERTY-RESPONSE-INFORMATION)
	   (inline MQTT-PROPERTY-SERVER-REFERENCE)
	   (inline MQTT-PROPERTY-RECEIVE-MAXIMUM)
	   (inline MQTT-PROPERTY-TOPIC-ALIAS-MAXIMUM)
	   (inline MQTT-PROPERTY-MAXIMUM-QOS)
	   (inline MQTT-PROPERTY-RETAIN-AVAILABLE)
	   (inline MQTT-PROPERTY-USER-PROPERTY)
	   (inline MQTT-PROPERTY-MAXIMUM-PACKET-SIZE)
	   (inline MQTT-PROPERTY-WILDCARD-SUBSCRIPTION-AVAILABLE)
	   (inline MQTT-PROPERTY-SUBSCRIPTION-IDENTIFIER-AVAILABLE)
	   (inline MQTT-PROPERTY-SHARED-SUBSCRIPT-AVAILABLE)
	   
	   (mqtt-control-packet-type-name::bstring ::long)
	   (mqtt-connect-reason-code-name::bstring ::long)

	   (read-int16::long ::input-port)
	   (read-int32::long ::input-port)
	   (read-utf8::bstring ::input-port)
	   (read-vbi::long ::input-port)

	   (write-int16 ::long ::output-port)
	   (write-utf8 ::bstring ::output-port)
	   (write-vbi ::long ::output-port)

	   (read-fixed-header ::input-port)
	   (read-properties::pair-nil ::input-port)

	   (packet-identifier? type::byte flags::long)

	   (mqtt-write-connect-packet op::output-port
	      version::long keep-alive::long clientid::bstring
	      username::obj password::obj)

	   (mqtt-read-connack-packet ::input-port version::long)
	   (mqtt-write-connack-packet op::output-port code::long)
	   
	   (mqtt-read-publish-packet ::input-port version::long)
	   (mqtt-write-publish-packet ::output-port dup::bool qos::long retain::bool topic::bstring pi payload)

	   (mqtt-read-subscribe-packet ip::input-port version::long)

	   (mqtt-write-suback-packet op::output-port ident::long ::pair-nil)

	   (mqtt-read-pubrec-packet ip::input-port version::long)

	   (mqtt-read-pingreq-packet ip::input-port version::long)
	   (mqtt-write-pingresp-packet op::output-port)

	   (mqtt-read-disconnect-packet ip::input-port version::long)
	   ))

;*---------------------------------------------------------------------*/
;*    MQTT Constants ...                                               */
;*---------------------------------------------------------------------*/
;; Version
(define-inline (MQTT-VERSION) 5)

;; Control Packet Type
(define-inline (MQTT-CPT-RESERVED) 0)
(define-inline (MQTT-CPT-CONNECT) 1)
(define-inline (MQTT-CPT-CONNACK) 2)
(define-inline (MQTT-CPT-PUBLISH) 3)
(define-inline (MQTT-CPT-PUBACK) 4)
(define-inline (MQTT-CPT-PUBREC) 5)
(define-inline (MQTT-CPT-PUBREL) 6)
(define-inline (MQTT-CPT-PUBCOMP) 7)
(define-inline (MQTT-CPT-SUBSCRIBE) 8)
(define-inline (MQTT-CPT-SUBACK) 9)
(define-inline (MQTT-CPT-UNSUBSCRIBE) 10)
(define-inline (MQTT-CPT-UNSUBACK) 11)
(define-inline (MQTT-CPT-PINGREQ) 12)
(define-inline (MQTT-CPT-PINGRESP) 13)
(define-inline (MQTT-CPT-DISCONNECT) 14)
(define-inline (MQTT-CPT-AUTH) 15)

;; Connect flags
(define-inline (MQTT-CONFLAG-CLEAN-START) #b10)
(define-inline (MQTT-CONFLAG-WILL-FLAG) #b100)
(define-inline (MQTT-CONFLAG-WILL-QOSL) #b1000)
(define-inline (MQTT-CONFLAG-WILL-QOSH) #b10000)
(define-inline (MQTT-CONFLAG-WILL-RETAIN) #b100000)
(define-inline (MQTT-CONFLAG-PASSWORD-FLAG) #b1000000)
(define-inline (MQTT-CONFLAG-USERNAME-FLAG) #b10000000)

;; Properties
(define-inline (MQTT-PROPERTY-PAYLOAD-FORMAT-INDICATOR) #x1)
(define-inline (MQTT-PROPERTY-MESSAGE-EXPIRY-INTERVAL) #x2)
(define-inline (MQTT-PROPERTY-MESSAGE-CONTENT-TYPE) #x3)
(define-inline (MQTT-PROPERTY-MESSAGE-RESPONSE-TOPIC) #x8)
(define-inline (MQTT-PROPERTY-MESSAGE-CORRELATION-DATA) #x9)
(define-inline (MQTT-PROPERTY-MESSAGE-SUBSCRIPTION-IDENTIFIER) #xb)
(define-inline (MQTT-PROPERTY-SESSION-EXPIRY-INTERVAL) #x11)
(define-inline (MQTT-PROPERTY-ASSIGNED-CLIENT-IDENTIFIER) #x12)
(define-inline (MQTT-PROPERTY-SERVER-KEEP-ALIVE) #x13)
(define-inline (MQTT-PROPERTY-AUTHENTICATION-METHOD) #x15)
(define-inline (MQTT-PROPERTY-AUTHENTICATION-DATA) #x16)
(define-inline (MQTT-PROPERTY-REQUEST-PROBLEM-INFORMATION) #x17)
(define-inline (MQTT-PROPERTY-WILL-DELAY-INTERVAL) #x18)
(define-inline (MQTT-PROPERTY-REQUEST-RESPONSE-INFORMATION) #x19)
(define-inline (MQTT-PROPERTY-RESPONSE-INFORMATION) #x1A)
(define-inline (MQTT-PROPERTY-SERVER-REFERENCE) #x1C)
(define-inline (MQTT-PROPERTY-RECEIVE-MAXIMUM) #x21)
(define-inline (MQTT-PROPERTY-TOPIC-ALIAS-MAXIMUM) #x22)
(define-inline (MQTT-PROPERTY-TOPIC-ALIAS) #x23)
(define-inline (MQTT-PROPERTY-MAXIMUM-QOS) #x24)
(define-inline (MQTT-PROPERTY-RETAIN-AVAILABLE) #x25)
(define-inline (MQTT-PROPERTY-USER-PROPERTY) #x26)
(define-inline (MQTT-PROPERTY-MAXIMUM-PACKET-SIZE) #x27)
(define-inline (MQTT-PROPERTY-WILDCARD-SUBSCRIPTION-AVAILABLE) #x28)
(define-inline (MQTT-PROPERTY-SUBSCRIPTION-IDENTIFIER-AVAILABLE) #x29)
(define-inline (MQTT-PROPERTY-SHARED-SUBSCRIPT-AVAILABLE) #x2a)

;*---------------------------------------------------------------------*/
;*    CONTROL-PACKET-TYPE-NAMES ...                                    */
;*---------------------------------------------------------------------*/
(define (CONTROL-PACKET-TYPE-NAMES)
   '#("Reserved" "CONNECT" "CONNACK" "PUBLISH" "PUBACK" "PUBREC" "PUBREL"
      "PUBCOMP" "SUBSCRIBE" "SUBACK" "UNSUBSCRIBE" "UNSUBACK" "PINGREQ"
      "PINGRESP""DISCONNECT" "AUTH"))

;*---------------------------------------------------------------------*/
;*    mqtt-control-packet-type-name ...                                */
;*---------------------------------------------------------------------*/
(define (mqtt-control-packet-type-name type)
   (vector-ref (CONTROL-PACKET-TYPE-NAMES) (bit-and type #xf)))

;*---------------------------------------------------------------------*/
;*    mqtt-connect-reason-code-name ...                                */
;*---------------------------------------------------------------------*/
(define (mqtt-connect-reason-code-name code)
   ;; 3.2.2.2 Connect Reason Code
   (case code
      ((#x00) "Success")
      ((#x80) "Unspecified error")
      ((#x81) "Malformed Packet")
      ((#x82) "Protocol Error")
      ((#x83) "Implementation specific error")
      ((#x84) "Unsupported Protocol Version")
      ((#x85) "Client Identifier not valid")
      ((#x86) "Bad User Name or Password")
      ((#x87) "Not authorized")
      ((#x88) "Server unavailable")
      ((#x89) "Server busy")
      ((#x8a) "Banned")
      ((#x8c) "Bad authentication method")
      ((#x90) "Topic Name invalid")
      ((#x95) "Packet too large")
      ((#x97) "Quota exceeded")
      ((#x99) "Payload format invalid")
      ((#x9a) "Retain not supported")
      ((#x9b) "QoS not supported")
      ((#x9c) "Use another server")
      ((#x9d) "Server mode")
      ((#x9f) "Connection rate exceeded")
      (else "Illegal code")))
   
;*---------------------------------------------------------------------*/
;*    read-int16 ...                                                   */
;*---------------------------------------------------------------------*/
(define (read-int16 ip::input-port)
   (let* ((b1 (read-byte ip))
	  (b2 (read-byte ip)))
      (+fx (bit-lsh b1 8) b2)))

;*---------------------------------------------------------------------*/
;*    read-int32 ...                                                   */
;*---------------------------------------------------------------------*/
(define (read-int32 ip::input-port)
   (let* ((s1 (read-int16 ip))
	  (s2 (read-int16 ip)))
      (+fx (bit-lsh s1 16) s2)))

;*---------------------------------------------------------------------*/
;*    read-vbi ...                                                     */
;*    -------------------------------------------------------------    */
;*    [MQTT-1.5.5-1]                                                   */
;*---------------------------------------------------------------------*/
(define (read-vbi ip::input-port)
   (let ((c (read-byte ip)))
      (if (eof-object? c)
	  c
	  (if (=fx (bit-and c #x80) 0)
	      c
	      (let loop ((acc (bit-and c #x7f))
			 (shift 7))
		 (let ((c (read-byte ip)))
		    (let ((acc (+fx acc (bit-lsh (bit-and c #x7f) shift))))
		       (if (=fx (bit-and c #x80) 0)
			   acc
			   (loop acc (+fx shift 7))))))))))

[assert () (=fx (call-with-input-string #"\x40" read-vbi) #x40)]
[assert () (=fx (call-with-input-string #"\x7f" read-vbi) #x7f)]
[assert () (=fx (call-with-input-string #"\x80\x01" read-vbi) #x80)]
[assert () (=fx (call-with-input-string #"\xff\x7f" read-vbi) 16383)]
[assert () (=fx (call-with-input-string #"\x80\x80\x01" read-vbi) 16384)]
[assert () (=fx (call-with-input-string #"\xff\xff\x7f" read-vbi) 2097151)]
[assert () (=fx (call-with-input-string #"\x80\x80\x80\x01" read-vbi) 2097152)]
[assert () (=fx (call-with-input-string #"\xff\xff\xff\x7f" read-vbi) 268435455)]

;*---------------------------------------------------------------------*/
;*    read-utf8 ...                                                    */
;*    -------------------------------------------------------------    */
;*    [MQTT-1.5.4.1]                                                   */
;*---------------------------------------------------------------------*/
(define (read-utf8 ip)
   (let* ((msb (read-byte ip))
	  (lsb (read-byte ip))
	  (len (+fx (bit-lsh msb 8) lsb)))
      (read-chars len ip)))

(define (read-utf8/eof ip)
   (let ((byte (read-byte ip)))
      (if (eof-object? byte)
	  byte
	  (begin
	     (unread-char! (integer->char byte) ip)
	     (read-utf8 ip)))))

;*---------------------------------------------------------------------*/
;*    write-int16 ...                                                  */
;*---------------------------------------------------------------------*/
(define (write-int16 x op)
   (write-byte (bit-rsh x 8) op)
   (write-byte (bit-and x #xff) op))

;*---------------------------------------------------------------------*/
;*    write-utf8 ...                                                   */
;*    -------------------------------------------------------------    */
;*    [MQTT-1.5.4.1]                                                   */
;*---------------------------------------------------------------------*/
(define (write-utf8 x op)
   (let ((len (string-length x)))
      (write-byte (bit-rsh len 8) op)
      (write-byte (bit-and len #xff) op)
      (display-string x op)))

;*---------------------------------------------------------------------*/
;*    write-vbi ...                                                    */
;*    -------------------------------------------------------------    */
;*    [MQTT-1.5.5-1]                                                   */
;*---------------------------------------------------------------------*/
(define (write-vbi x op)
   (let loop ((x x))
      (let* ((enc (remainderfx x 128))
	     (x (bit-rsh x 7)))
	 (if (>fx x 0)
	     (let ((enc (bit-or enc 128)))
		(write-byte enc op)
		(loop x))
	     (write-byte enc op)))))
   
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi #x40 op))) #"\x40")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi #x7f op))) #"\x7f")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi #x80 op))) #"\x80\x01")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi 16383 op))) #"\xff\x7f")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi 16384 op))) #"\x80\x80\x01")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi 2097151 op))) #"\xff\xff\x7f")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi 2097152 op))) #"\x80\x80\x80\x01")]
[assert () (string=? (call-with-output-string (lambda (op) (write-vbi 268435455 op))) #"\xff\xff\xff\x7f")]

;*---------------------------------------------------------------------*/
;*    read-fixed-header ...                                            */
;*---------------------------------------------------------------------*/
(define (read-fixed-header ip::input-port)
   (let ((header (read-byte ip)))
      (if (eof-object? header)
	  (values header 0 0)
	  (values (bit-rsh header 4) (bit-and header #xf) (read-vbi ip)))))

;*---------------------------------------------------------------------*/
;*    read-property ...                                                */
;*---------------------------------------------------------------------*/
(define (read-property ip::input-port)
   (with-trace 'mqtt "read-property"
      (let ((ident (read-vbi ip)))
	 (trace-item "ident=" ident " " (integer->string ident 16))
	 (cond
	    ((eof-object? ident)
	     ident)
	    ((=fx ident (MQTT-PROPERTY-SESSION-EXPIRY-INTERVAL))
	     (cons 'SESSION-EXPIRY-INTERVAL (read-int32 ip)))
	    ((=fx ident (MQTT-PROPERTY-RECEIVE-MAXIMUM))
	     (cons 'RECEIVE-MAXIMUM (read-int16 ip)))
	    ((=fx ident (MQTT-PROPERTY-MAXIMUM-PACKET-SIZE))
	     (cons 'MAXIMUM-PACKET-SIZE (read-int32 ip)))
	    ((=fx ident (MQTT-PROPERTY-TOPIC-ALIAS-MAXIMUM))
	     (cons 'TOPIC-ALIAS-MAXIMUM (read-int16 ip)))
	    ((=fx ident (MQTT-PROPERTY-REQUEST-RESPONSE-INFORMATION))
	     (cons 'REQUEST-RESPONSE-INFORMATION (read-byte ip)))
	    ((=fx ident (MQTT-PROPERTY-REQUEST-PROBLEM-INFORMATION))
	     (cons 'REQUEST-PROBLEM-INFORMATION (read-byte ip)))
	    ((=fx ident (MQTT-PROPERTY-USER-PROPERTY))
	     (let* ((name (read-utf8 ip))
		    (value (read-utf8 ip)))
		(cons 'PROBLEM-INFORMATION (cons name value))))
	    ((=fx ident (MQTT-PROPERTY-AUTHENTICATION-METHOD))
	     (cons 'AUTHENTICATION-METHOD (read-utf8 ip)))
	    ((=fx ident (MQTT-PROPERTY-AUTHENTICATION-DATA))
	     (cons 'AUTHENTICATION-DATA "TODO-aut-data"))
	    ((=fx ident (MQTT-PROPERTY-PAYLOAD-FORMAT-INDICATOR))
	     (cons 'PAYLOAD-FORMAT-INDICATOR (read-byte ip)))
	    ((=fx ident (MQTT-PROPERTY-MESSAGE-EXPIRY-INTERVAL))
	     (cons 'MESSAGE-EXPIRY-INTERVAL (read-int32 ip)))
	    ((=fx ident (MQTT-PROPERTY-TOPIC-ALIAS))
	     (cons 'TOPIC-ALIAS (read-int16 ip)))
	    ((=fx ident (MQTT-PROPERTY-MESSAGE-RESPONSE-TOPIC))
	     (cons 'MESSAGE-RESPONSE-TOPIC (read-utf8 ip)))
	    ((=fx ident (MQTT-PROPERTY-MESSAGE-CORRELATION-DATA))
	     (cons 'MESSAGE-CORRELATION-DATA "TODO-correlation-data"))
	    ((=fx ident (MQTT-PROPERTY-USER-PROPERTY))
	     (cons 'USER-PROPERTY (read-utf8 ip)))
	    ((=fx ident (MQTT-PROPERTY-MESSAGE-SUBSCRIPTION-IDENTIFIER))
	     (cons 'MESSAGE-SUBSCRIPTION-IDENTIFIER (read-vbi ip)))
	    ((=fx ident (MQTT-PROPERTY-MESSAGE-CONTENT-TYPE))
	     (cons 'MESSAGE-CONTENT-TYPE (read-utf8 ip)))
	    (else
	     (tprint "unknown message " ident)
	     (cons 'UNKNOWN (format "~a" ident)))))))

;*---------------------------------------------------------------------*/
;*    read-properties ...                                              */
;*---------------------------------------------------------------------*/
(define (read-properties::pair-nil ip::input-port)
   (with-trace 'mqtt "read-properties"
      (let ((length (read-vbi ip)))
	 (trace-item "length=" length)
	 (if (=fx length 0)
	     '()
	     (call-with-input-string (read-chars length ip)
		(lambda (pip)
		   (let loop ()
		      (let ((prop (read-property pip)))
			 (if (eof-object? prop)
			     '()
			     (cons prop (loop)))))))))))

;*---------------------------------------------------------------------*/
;*    packet-identifier? ...                                           */
;*---------------------------------------------------------------------*/
(define (packet-identifier? type::byte flags::long)
   (or (and (=fx type (MQTT-CPT-PUBLISH)) (>fx flags 0))
       (=fx type (MQTT-CPT-PUBACK))
       (=fx type (MQTT-CPT-PUBREC))
       (=fx type (MQTT-CPT-PUBREL))
       (=fx type (MQTT-CPT-PUBCOMP))
       (=fx type (MQTT-CPT-SUBSCRIBE))
       (=fx type (MQTT-CPT-SUBACK))
       (=fx type (MQTT-CPT-UNSUBSCRIBE))
       (=fx type (MQTT-CPT-SUBACK))))

;*---------------------------------------------------------------------*/
;*    mqtt-write-connect-packet ...                                    */
;*---------------------------------------------------------------------*/
(define (mqtt-write-connect-packet op version keep-alive clientid::bstring
	   username password)

   (define (write-connect-variable-header op::output-port version::long keep-alive
	      username password)
      (write-utf8 "MQTT" op)
      ;; 3.1.2.2 Protocol Version
      (write-byte version op)
      ;; 3.1.2.3 Connect Flags
      (let* ((flags (if username
			(MQTT-CONFLAG-USERNAME-FLAG)
			0))
	     (flags (if password
			(bit-or flags (MQTT-CONFLAG-PASSWORD-FLAG))
			flags)))
	 (write-byte flags op))
      ;; 3.1.2.10 Keep Alive
      (write-byte (bit-rsh keep-alive 8) op)
      (write-byte (bit-and keep-alive #xff) op)
      ;; 3.1.2.11 CONNECT Properties
      (when (=fx version 5)
	 (write-byte 0 op)))

   (define (write-connect-payload op::output-port clientid username password)
      ;; client identifier
      (write-utf8 clientid op)
      ;; will topic
      ;; will message
      ;; user name
      (when username
	 (write-utf8 username op))
      ;; password
      (when password
	 (write-int16 (string-length password) op)
	 (display password op)))
   
   (let ((sop (open-output-string 256)))
      ;; 3.1.1 CONNECT Fixed Header
      (write-byte (bit-lsh (MQTT-CPT-CONNECT) 4) op)
      (unwind-protect
	 (begin
	    ;; 3.1.2 CONNECT Variable Header
	    (write-connect-variable-header sop
	       version keep-alive username password)
	    ;; 3.1.3 CONNECT Payload
	    (write-connect-payload sop
	       clientid username password))
	 (let ((str (close-output-port sop)))
	    ;; 3.1.2 CONNECT Variable Header
	    (write-vbi (string-length str) op)
	    (display-string str op)
	    (flush-output-port op)))))

;*---------------------------------------------------------------------*/
;*    mqtt-read-connack-packet ...                                     */
;*    -------------------------------------------------------------    */
;*    3.2 CONNACK                                                      */
;*---------------------------------------------------------------------*/
(define (mqtt-read-connack-packet ip::input-port version)
   (with-trace 'mqtt "mqtt-read-connack-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (unless (eq? ptype (MQTT-CPT-CONNACK))
	    (error "mqtt" "CONNACK packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 ;; 3.2.2.1 Connect Acknowledge Flags
	 (let ((ack (read-byte ip)))
	    ;; 3.2.2.1.1 Session Present
	    ;; 3.2.2.2 Connect Reason Code
	    (let ((reason-code (read-byte ip)))
	       (when (=fx version 5)
		  (read-properties ip)))))))

;*---------------------------------------------------------------------*/
;*    mqtt-write-connack-packet ...                                    */
;*    -------------------------------------------------------------    */
;*    3.2 CONNACK                                                      */
;*---------------------------------------------------------------------*/
(define (mqtt-write-connack-packet op::output-port code::long)
   (with-trace 'mqtt "mqtt-write-connack-packet"
      (trace-item "reason=" (mqtt-connect-reason-code-name code))
      ;; 3.2.1 CONNACK Fixed Header
      (write-byte (bit-lsh (MQTT-CPT-CONNACK) 4) op)
      (write-byte 2 op)
      ;; 3.2.2.1 Connect Acknowledge Flags
      (write-byte 0 op)
      ;; 3.2.2.2 Connect Reason Code
      (write-byte code op)
      (flush-output-port op)))

;*---------------------------------------------------------------------*/
;*    mqtt-read-publish-packet ...                                     */
;*    -------------------------------------------------------------    */
;*    3.3 PUBLISH                                                      */
;*---------------------------------------------------------------------*/
(define (mqtt-read-publish-packet ip::input-port version::long)

   (define (read-publish-variable-header ip::input-port pk::mqtt-control-packet flags)
      (with-trace 'mqtt "read-publish-variable-header"
	 (with-access::mqtt-publish-packet pk (properties payload topic)
	    ;; 3.3.2.1 Topic Name
	    (set! topic (read-utf8 ip))
	    (trace-item "topic=" topic)
	    ;; 3.2.2.2 Packet Identifier
	    (let* ((qos (bit-and 3 (bit-rsh flags 1)))
		   (id (if (or (=fx qos 1) (=fx qos 2)) (read-int16 ip) -1)))
	       (trace-item "id=" id)
	       (trace-item "props=" properties)
	       pk))))
   
   (with-trace 'mqtt "mqtt-read-publish-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (trace-item "header=" (mqtt-control-packet-type-name ptype)
	    " flags=" pflags)
	 (trace-item "length=" length)
	 (unless (eq? ptype (MQTT-CPT-PUBLISH))
	    (error "mqtt" "PUBLISH packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 (call-with-input-string (read-chars length ip)
	    (lambda (vip)
	       (let ((packet (instantiate::mqtt-publish-packet
				(type ptype)
				(flags pflags))))
		  (read-publish-variable-header vip packet pflags)
		  (with-access::mqtt-publish-packet packet (payload)
		     (set! payload (read-string vip))
		     (trace-item "payload=" (string-for-read payload)))
		  packet))))))

;*---------------------------------------------------------------------*/
;*    mqtt-write-publish-packet ...                                    */
;*    -------------------------------------------------------------    */
;*    3.3 PUBLISH                                                      */
;*---------------------------------------------------------------------*/
(define (mqtt-write-publish-packet op dup qos retain topic pi payload)
   ;; 3.1.1 CONNECT Fixed Header
   (let ((flags (bit-or (if dup 4 0)
		   (bit-or (if retain 1 0)
		      qos))))
      (write-byte (bit-or (bit-lsh (MQTT-CPT-PUBLISH) 4) flags) op)
      (let ((sop (open-output-string 256)))
	 (unwind-protect
	    (begin
	       (write-utf8 topic sop)
	       (when (or (=fx qos 1) (=fx qos 2))
		  (write-int16 pi sop))
	       (display-string payload sop))
	    (let ((str (close-output-port sop)))
	       (write-vbi (string-length str) op)
	       (display-string str op)
	       (flush-output-port op))))))
   
;*---------------------------------------------------------------------*/
;*    mqtt-read-subscribe-packet ...                                   */
;*---------------------------------------------------------------------*/
(define (mqtt-read-subscribe-packet ip::input-port version::long)
   
   (define (read-subscribe-variable-header ip::input-port pk::mqtt-subscribe-packet)
      (with-access::mqtt-subscribe-packet pk (ident properties)
	 (with-trace 'mqtt "read-subscribe-variable-header"
	    (set! ident (read-int16 ip))
	    (trace-item "ident=" ident)
	    (when (>=fx version 5)
	       (set! properties (read-properties ip))))))
   
   (define (read-subscribe-payload ip::input-port pk::mqtt-subscribe-packet)
      (with-trace 'mqtt "read-subscribe-payload"
	 (with-access::mqtt-subscribe-packet pk (payload)
	    ;; 3.8.3 SUBSCRIBE Payload
	    (let loop ((filters '()))
	       (let ((str (read-utf8/eof ip)))
		  (if (eof-object? str)
		      (set! payload (reverse! filters))
		      (let ((options (read-byte ip)))
			 (trace-item "str=" str " options=" options)
			 (loop (cons (cons str options) filters)))))))))
   
   (with-trace 'mqtt "mqtt-read-subscribe-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (trace-item "header=" (mqtt-control-packet-type-name ptype)
	    " flags=" pflags)
	 (trace-item "length=" length)
	 (unless (eq? ptype (MQTT-CPT-SUBSCRIBE))
	    (error "mqtt" "SUBSCRIBE packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 (call-with-input-string (read-chars length ip)
	    (lambda (vip)
	       (let ((packet (instantiate::mqtt-subscribe-packet
				(type ptype)
				(flags pflags))))
		  (read-subscribe-variable-header vip packet)
		  (read-subscribe-payload vip packet)
		  packet))))))
   
;*---------------------------------------------------------------------*/
;*    mqtt-write-suback-packet ...                                     */
;*---------------------------------------------------------------------*/
(define (mqtt-write-suback-packet op::output-port ident::long payload::pair-nil)
   (with-trace 'mqtt "mqtt-write-subnack-packet"
      (trace-item "ident=" ident)
      ;; 3.9.1 CONNACK Fixed Header
      (write-byte (bit-lsh (MQTT-CPT-SUBACK) 4) op)
      (write-byte (+fx 2 (length payload)) op)
      ;; 3.9.2 Variable header
      (write-int16 ident op)
      ;; 3.2.3 Payload
      (for-each (lambda (code) (write-byte code op)) payload)
      (flush-output-port op)))

;*---------------------------------------------------------------------*/
;*    mqtt-read-pubrec-packet ...                                      */
;*    -------------------------------------------------------------    */
;*    3.5 PUBREC                                                       */
;*---------------------------------------------------------------------*/
(define (mqtt-read-pubrec-packet ip::input-port version::long)
   (with-trace 'mqtt "mqtt-read-pubrec-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (trace-item "header=" (mqtt-control-packet-type-name ptype)
	    " flags=" pflags)
	 (trace-item "length=" length)
	 (unless (eq? ptype (MQTT-CPT-PUBREC))
	    (error "mqtt" "PUBREC packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 (instantiate::mqtt-control-packet
	    (type ptype)
	    (flags pflags)
	    (properties `((pi . ,(read-int16 ip))))))))
   
;*---------------------------------------------------------------------*/
;*    mqtt-read-pingreq-packet ...                                     */
;*    -------------------------------------------------------------    */
;*    3.12 PINGREQ                                                     */
;*---------------------------------------------------------------------*/
(define (mqtt-read-pingreq-packet ip::input-port version::long)
   (with-trace 'mqtt "mqtt-read-pingreq-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (trace-item "header=" (mqtt-control-packet-type-name ptype)
	    " flags=" pflags)
	 (trace-item "length=" length)
	 (unless (eq? ptype (MQTT-CPT-PINGREQ))
	    (error "mqtt" "PINGREQ packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 (call-with-input-string (read-chars length ip)
	    (lambda (vip)
	       (let ((packet (instantiate::mqtt-control-packet
				(type ptype)
				(flags pflags))))
		  packet))))))

;*---------------------------------------------------------------------*/
;*    mqtt-write-pingresp-packet ...                                   */
;*    -------------------------------------------------------------    */
;*    3.13 PINGRESP                                                    */
;*---------------------------------------------------------------------*/
(define (mqtt-write-pingresp-packet op::output-port)
   (with-trace 'mqtt "mqtt-write-pingresp-packet"
      ;; 3.13.1.1 PINGRESP Fixed Header
      (write-byte (bit-lsh (MQTT-CPT-PINGRESP) 4) op)
      ;; 3.13.2 Variable header
      (write-byte 0 op)
      (flush-output-port op)))

;*---------------------------------------------------------------------*/
;*    mqtt-read-disconnect-packet ...                                  */
;*    -------------------------------------------------------------    */
;*    3.14 DISCONNECT                                                  */
;*---------------------------------------------------------------------*/
(define (mqtt-read-disconnect-packet ip::input-port version::long)
   (with-trace 'mqtt "mqtt-read-disconnect-packet"
      (multiple-value-bind (ptype pflags length)
	 (read-fixed-header ip)
	 (trace-item "header=" (mqtt-control-packet-type-name ptype)
	    " flags=" pflags)
	 (trace-item "length=" length)
	 (unless (eq? ptype (MQTT-CPT-DISCONNECT))
	    (error "mqtt" "DISCONNECT packet expected"
	       (mqtt-control-packet-type-name ptype)))
	 (call-with-input-string (read-chars length ip)
	    (lambda (vip)
	       (let ((packet (instantiate::mqtt-control-packet
				(type ptype)
				(flags pflags))))
		  packet))))))


