;; RegTech Provider Verification Contract
;; Validates compliance technology vendors

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))
(define-constant ERR_INVALID_RATING (err u103))

;; Provider verification status
(define-map verified-providers
  { provider: principal }
  {
    verified: bool,
    verification-date: uint,
    rating: uint,
    certifications: (string-ascii 500),
    compliance-score: uint
  }
)

;; Verification requests
(define-map verification-requests
  { request-id: uint }
  {
    provider: principal,
    submitted-date: uint,
    status: (string-ascii 20),
    documents: (string-ascii 1000)
  }
)

(define-data-var next-request-id uint u1)

;; Submit verification request
(define-public (submit-verification-request (documents (string-ascii 1000)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        provider: tx-sender,
        submitted-date: block-height,
        status: "pending",
        documents: documents
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Verify provider (admin only)
(define-public (verify-provider
  (provider principal)
  (rating uint)
  (certifications (string-ascii 500))
  (compliance-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (<= compliance-score u100) ERR_INVALID_RATING)

    (map-set verified-providers
      { provider: provider }
      {
        verified: true,
        verification-date: block-height,
        rating: rating,
        certifications: certifications,
        compliance-score: compliance-score
      }
    )
    (ok true)
  )
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider principal))
  (match (map-get? verified-providers { provider: provider })
    verification-data (get verified verification-data)
    false
  )
)

;; Get provider details
(define-read-only (get-provider-details (provider principal))
  (map-get? verified-providers { provider: provider })
)

;; Get verification request
(define-read-only (get-verification-request (request-id uint))
  (map-get? verification-requests { request-id: request-id })
)
