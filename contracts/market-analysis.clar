;; Market Analysis Contract
;; Analyzes sourcing markets and trends

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))

;; Data Variables
(define-data-var next-market-id uint u1)
(define-data-var next-analysis-id uint u1)
(define-data-var total-markets uint u0)

;; Data Maps
(define-map markets
  uint
  {
    category: (string-ascii 50),
    description: (string-ascii 200),
    risk-level: uint,
    volatility-index: uint,
    created-at: uint,
    updated-at: uint
  }
)

(define-map market-analysis
  uint
  {
    market-id: uint,
    analyst-principal: principal,
    price-trend: (string-ascii 20),
    supply-demand-ratio: uint,
    market-size: uint,
    growth-rate: uint,
    recommendations: (string-ascii 500),
    confidence-score: uint,
    analysis-date: uint
  }
)

(define-map market-prices
  {market-id: uint, date: uint}
  {
    average-price: uint,
    min-price: uint,
    max-price: uint,
    volume: uint
  }
)

(define-map authorized-analysts
  principal
  bool
)

;; Read-only functions
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

(define-read-only (get-market-analysis (analysis-id uint))
  (map-get? market-analysis analysis-id)
)

(define-read-only (get-market-price (market-id uint) (date uint))
  (map-get? market-prices {market-id: market-id, date: date})
)

(define-read-only (is-authorized-analyst (analyst principal))
  (default-to false (map-get? authorized-analysts analyst))
)

(define-read-only (get-total-markets)
  (var-get total-markets)
)

(define-read-only (calculate-market-score (market-id uint))
  (match (get-market market-id)
    market
      (let
        (
          (risk-score (- u100 (get risk-level market)))
          (stability-score (- u100 (get volatility-index market)))
        )
        (/ (+ risk-score stability-score) u2)
      )
    u0
  )
)

;; Public functions
(define-public (create-market (category (string-ascii 50)) (description (string-ascii 200)) (risk-level uint) (volatility-index uint))
  (let
    (
      (market-id (var-get next-market-id))
    )
    (asserts! (is-authorized-analyst tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len category) u0) ERR-INVALID-INPUT)
    (asserts! (<= risk-level u100) ERR-INVALID-INPUT)
    (asserts! (<= volatility-index u100) ERR-INVALID-INPUT)

    (map-set markets market-id
      {
        category: category,
        description: description,
        risk-level: risk-level,
        volatility-index: volatility-index,
        created-at: block-height,
        updated-at: block-height
      }
    )

    (var-set next-market-id (+ market-id u1))
    (var-set total-markets (+ (var-get total-markets) u1))

    (ok market-id)
  )
)

(define-public (submit-market-analysis
  (market-id uint)
  (price-trend (string-ascii 20))
  (supply-demand-ratio uint)
  (market-size uint)
  (growth-rate uint)
  (recommendations (string-ascii 500))
  (confidence-score uint))
  (let
    (
      (analysis-id (var-get next-analysis-id))
    )
    (asserts! (is-authorized-analyst tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (get-market market-id)) ERR-NOT-FOUND)
    (asserts! (<= confidence-score u100) ERR-INVALID-INPUT)
    (asserts! (> (len price-trend) u0) ERR-INVALID-INPUT)

    (map-set market-analysis analysis-id
      {
        market-id: market-id,
        analyst-principal: tx-sender,
        price-trend: price-trend,
        supply-demand-ratio: supply-demand-ratio,
        market-size: market-size,
        growth-rate: growth-rate,
        recommendations: recommendations,
        confidence-score: confidence-score,
        analysis-date: block-height
      }
    )

    (var-set next-analysis-id (+ analysis-id u1))

    (ok analysis-id)
  )
)

(define-public (update-market-price (market-id uint) (average-price uint) (min-price uint) (max-price uint) (volume uint))
  (let
    (
      (current-date block-height)
    )
    (asserts! (is-authorized-analyst tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (get-market market-id)) ERR-NOT-FOUND)
    (asserts! (>= average-price min-price) ERR-INVALID-INPUT)
    (asserts! (<= average-price max-price) ERR-INVALID-INPUT)

    (map-set market-prices {market-id: market-id, date: current-date}
      {
        average-price: average-price,
        min-price: min-price,
        max-price: max-price,
        volume: volume
      }
    )

    (ok true)
  )
)

(define-public (authorize-analyst (analyst principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-analysts analyst true)
    (ok true)
  )
)

(define-public (revoke-analyst (analyst principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-analysts analyst false)
    (ok true)
  )
)

(define-public (update-market-risk (market-id uint) (new-risk-level uint) (new-volatility-index uint))
  (let
    (
      (market (unwrap! (get-market market-id) ERR-NOT-FOUND))
    )
    (asserts! (is-authorized-analyst tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-risk-level u100) ERR-INVALID-INPUT)
    (asserts! (<= new-volatility-index u100) ERR-INVALID-INPUT)

    (map-set markets market-id
      (merge market {
        risk-level: new-risk-level,
        volatility-index: new-volatility-index,
        updated-at: block-height
      })
    )

    (ok true)
  )
)
