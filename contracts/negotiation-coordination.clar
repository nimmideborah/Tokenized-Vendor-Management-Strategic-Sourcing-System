;; Negotiation Coordination Contract
;; Coordinates sourcing negotiations between parties

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STATUS (err u105))
(define-constant ERR-EXPIRED (err u106))

;; Data Variables
(define-data-var next-session-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var total-sessions uint u0)

;; Data Maps
(define-map negotiation-sessions
  uint
  {
    buyer-principal: principal,
    supplier-principal: principal,
    coordinator-principal: principal,
    category: (string-ascii 50),
    status: (string-ascii 20),
    start-date: uint,
    end-date: uint,
    current-round: uint,
    max-rounds: uint
  }
)

(define-map negotiation-proposals
  uint
  {
    session-id: uint,
    proposer-principal: principal,
    proposal-type: (string-ascii 20),
    price-per-unit: uint,
    quantity: uint,
    delivery-terms: (string-ascii 100),
    quality-requirements: (string-ascii 200),
    payment-terms: (string-ascii 100),
    validity-period: uint,
    proposal-date: uint,
    status: (string-ascii 20)
  }
)

(define-map session-agreements
  uint
  {
    session-id: uint,
    final-price: uint,
    final-quantity: uint,
    agreed-terms: (string-ascii 500),
    agreement-date: uint,
    effective-date: uint,
    expiry-date: uint
  }
)

(define-map authorized-coordinators
  principal
  bool
)

;; Read-only functions
(define-read-only (get-negotiation-session (session-id uint))
  (map-get? negotiation-sessions session-id)
)

(define-read-only (get-negotiation-proposal (proposal-id uint))
  (map-get? negotiation-proposals proposal-id)
)

(define-read-only (get-session-agreement (session-id uint))
  (map-get? session-agreements session-id)
)

(define-read-only (is-authorized-coordinator (coordinator principal))
  (default-to false (map-get? authorized-coordinators coordinator))
)

(define-read-only (get-total-sessions)
  (var-get total-sessions)
)

(define-read-only (is-session-active (session-id uint))
  (match (get-negotiation-session session-id)
    session
      (and
        (is-eq (get status session) "active")
        (<= block-height (get end-date session))
        (< (get current-round session) (get max-rounds session))
      )
    false
  )
)

(define-read-only (can-participate (session-id uint) (participant principal))
  (match (get-negotiation-session session-id)
    session
      (or
        (is-eq participant (get buyer-principal session))
        (is-eq participant (get supplier-principal session))
        (is-eq participant (get coordinator-principal session))
      )
    false
  )
)

;; Public functions
(define-public (create-negotiation-session
  (buyer-principal principal)
  (supplier-principal principal)
  (category (string-ascii 50))
  (duration-blocks uint)
  (max-rounds uint))
  (let
    (
      (session-id (var-get next-session-id))
      (start-date block-height)
      (end-date (+ block-height duration-blocks))
    )
    (asserts! (is-authorized-coordinator tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len category) u0) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)
    (asserts! (> max-rounds u0) ERR-INVALID-INPUT)
    (asserts! (not (is-eq buyer-principal supplier-principal)) ERR-INVALID-INPUT)

    (map-set negotiation-sessions session-id
      {
        buyer-principal: buyer-principal,
        supplier-principal: supplier-principal,
        coordinator-principal: tx-sender,
        category: category,
        status: "active",
        start-date: start-date,
        end-date: end-date,
        current-round: u1,
        max-rounds: max-rounds
      }
    )

    (var-set next-session-id (+ session-id u1))
    (var-set total-sessions (+ (var-get total-sessions) u1))

    (ok session-id)
  )
)

(define-public (submit-proposal
  (session-id uint)
  (proposal-type (string-ascii 20))
  (price-per-unit uint)
  (quantity uint)
  (delivery-terms (string-ascii 100))
  (quality-requirements (string-ascii 200))
  (payment-terms (string-ascii 100))
  (validity-blocks uint))
  (let
    (
      (proposal-id (var-get next-proposal-id))
      (session (unwrap! (get-negotiation-session session-id) ERR-NOT-FOUND))
    )
    (asserts! (can-participate session-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-session-active session-id) ERR-INVALID-STATUS)
    (asserts! (> price-per-unit u0) ERR-INVALID-INPUT)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (asserts! (> validity-blocks u0) ERR-INVALID-INPUT)

    (map-set negotiation-proposals proposal-id
      {
        session-id: session-id,
        proposer-principal: tx-sender,
        proposal-type: proposal-type,
        price-per-unit: price-per-unit,
        quantity: quantity,
        delivery-terms: delivery-terms,
        quality-requirements: quality-requirements,
        payment-terms: payment-terms,
        validity-period: (+ block-height validity-blocks),
        proposal-date: block-height,
        status: "pending"
      }
    )

    (var-set next-proposal-id (+ proposal-id u1))

    (ok proposal-id)
  )
)

(define-public (accept-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (get-negotiation-proposal proposal-id) ERR-NOT-FOUND))
      (session-id (get session-id proposal))
      (session (unwrap! (get-negotiation-session session-id) ERR-NOT-FOUND))
    )
    (asserts! (can-participate session-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq tx-sender (get proposer-principal proposal))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status proposal) "pending") ERR-INVALID-STATUS)
    (asserts! (<= block-height (get validity-period proposal)) ERR-EXPIRED)

    (map-set negotiation-proposals proposal-id
      (merge proposal {
        status: "accepted"
      })
    )

    (map-set session-agreements session-id
      {
        session-id: session-id,
        final-price: (get price-per-unit proposal),
        final-quantity: (get quantity proposal),
        agreed-terms: (get delivery-terms proposal),
        agreement-date: block-height,
        effective-date: (+ block-height u144), ;; ~1 day
        expiry-date: (+ block-height u52560) ;; ~1 year
      }
    )

    (map-set negotiation-sessions session-id
      (merge session {
        status: "completed"
      })
    )

    (ok true)
  )
)

(define-public (reject-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (get-negotiation-proposal proposal-id) ERR-NOT-FOUND))
      (session-id (get session-id proposal))
    )
    (asserts! (can-participate session-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq tx-sender (get proposer-principal proposal))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status proposal) "pending") ERR-INVALID-STATUS)

    (map-set negotiation-proposals proposal-id
      (merge proposal {
        status: "rejected"
      })
    )

    (ok true)
  )
)

(define-public (advance-negotiation-round (session-id uint))
  (let
    (
      (session (unwrap! (get-negotiation-session session-id) ERR-NOT-FOUND))
      (current-round (get current-round session))
      (max-rounds (get max-rounds session))
    )
    (asserts! (is-eq tx-sender (get coordinator-principal session)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status session) "active") ERR-INVALID-STATUS)
    (asserts! (< current-round max-rounds) ERR-INVALID-STATUS)

    (map-set negotiation-sessions session-id
      (merge session {
        current-round: (+ current-round u1)
      })
    )

    (ok true)
  )
)

(define-public (close-session (session-id uint))
  (let
    (
      (session (unwrap! (get-negotiation-session session-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get coordinator-principal session)) ERR-NOT-AUTHORIZED)

    (map-set negotiation-sessions session-id
      (merge session {
        status: "closed"
      })
    )

    (ok true)
  )
)

(define-public (authorize-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-coordinators coordinator true)
    (ok true)
  )
)

(define-public (revoke-coordinator (coordinator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-coordinators coordinator false)
    (ok true)
  )
)
