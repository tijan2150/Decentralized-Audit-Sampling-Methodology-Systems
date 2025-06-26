;; Audit Methodologist Verification Contract
;; Manages registration and validation of audit methodologists

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

;; Data Variables
(define-data-var next-methodologist-id uint u1)

;; Data Maps
(define-map methodologists
  { methodologist-id: uint }
  {
    owner: principal,
    credentials-hash: (string-ascii 64),
    status: (string-ascii 20),
    registration-block: uint,
    last-activity: uint
  }
)

(define-map methodologist-by-owner
  { owner: principal }
  { methodologist-id: uint }
)

;; Public Functions

;; Register a new methodologist
(define-public (register-methodologist (credentials-hash (string-ascii 64)))
  (let
    (
      (methodologist-id (var-get next-methodologist-id))
      (caller tx-sender)
    )
    (asserts! (is-none (map-get? methodologist-by-owner { owner: caller })) ERR-ALREADY-REGISTERED)

    (map-set methodologists
      { methodologist-id: methodologist-id }
      {
        owner: caller,
        credentials-hash: credentials-hash,
        status: "active",
        registration-block: block-height,
        last-activity: block-height
      }
    )

    (map-set methodologist-by-owner
      { owner: caller }
      { methodologist-id: methodologist-id }
    )

    (var-set next-methodologist-id (+ methodologist-id u1))
    (ok methodologist-id)
  )
)

;; Update methodologist status
(define-public (update-status (methodologist-id uint) (new-status (string-ascii 20)))
  (let
    (
      (methodologist (unwrap! (map-get? methodologists { methodologist-id: methodologist-id }) ERR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get owner methodologist))) ERR-NOT-AUTHORIZED)

    (map-set methodologists
      { methodologist-id: methodologist-id }
      (merge methodologist { status: new-status, last-activity: block-height })
    )
    (ok true)
  )
)

;; Validate methodologist
(define-public (validate-methodologist (methodologist-id uint))
  (let
    (
      (methodologist (unwrap! (map-get? methodologists { methodologist-id: methodologist-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq (get status methodologist) "active") ERR-INVALID-STATUS)

    (map-set methodologists
      { methodologist-id: methodologist-id }
      (merge methodologist { last-activity: block-height })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get methodologist details
(define-read-only (get-methodologist (methodologist-id uint))
  (map-get? methodologists { methodologist-id: methodologist-id })
)

;; Get methodologist by owner
(define-read-only (get-methodologist-by-owner (owner principal))
  (match (map-get? methodologist-by-owner { owner: owner })
    entry (map-get? methodologists { methodologist-id: (get methodologist-id entry) })
    none
  )
)

;; Check if methodologist is active
(define-read-only (is-active-methodologist (methodologist-id uint))
  (match (map-get? methodologists { methodologist-id: methodologist-id })
    methodologist (is-eq (get status methodologist) "active")
    false
  )
)
