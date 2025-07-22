;; Hack-Shield: Parametric Insurance for DeFi Exploits
;; A smart contract insurance protocol built on Stacks blockchain

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-POLICY (err u101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u102))
(define-constant ERR-POLICY-EXPIRED (err u103))
(define-constant ERR-POLICY-NOT-FOUND (err u104))
(define-constant ERR-CLAIM-ALREADY-PROCESSED (err u105))
(define-constant ERR-INVALID-ORACLE-DATA (err u106))
(define-constant ERR-MINIMUM-PREMIUM (err u107))

;; Contract variables
(define-data-var policy-counter uint u0)
(define-data-var total-premium-pool uint u0)
(define-data-var oracle-address principal CONTRACT-OWNER)
(define-data-var minimum-premium uint u1000000) ;; 1 STX minimum

;; Data structures
(define-map policies
  uint
  {
    policy-holder: principal,
    protocol-address: (string-ascii 64),
    coverage-amount: uint,
    premium-paid: uint,
    start-block: uint,
    end-block: uint,
    is-active: bool,
    claim-processed: bool
  }
)

(define-map protocol-risk-scores
  (string-ascii 64)
  {
    risk-level: uint, ;; 1-10 scale (1=lowest risk, 10=highest risk)
    last-updated: uint
  }
)

(define-map exploit-events
  (string-ascii 64)
  {
    is-exploited: bool,
    exploit-amount: uint,
    block-height: uint,
    verified: bool
  }
)

(define-map user-policies
  principal
  (list 50 uint)
)

;; Read-only functions
(define-read-only (get-policy (policy-id uint))
  (map-get? policies policy-id)
)

(define-read-only (get-protocol-risk (protocol (string-ascii 64)))
  (map-get? protocol-risk-scores protocol)
)

(define-read-only (get-exploit-event (protocol (string-ascii 64)))
  (map-get? exploit-events protocol)
)

(define-read-only (get-user-policies (user principal))
  (default-to (list) (map-get? user-policies user))
)

(define-read-only (calculate-premium (coverage-amount uint) (protocol (string-ascii 64)) (duration-blocks uint))
  (let (
    (risk-data (get-protocol-risk protocol))
    (risk-multiplier (match risk-data
      risk-info (get risk-level risk-info)
      u5)) ;; Default medium risk
    (base-rate u100) ;; 1% base rate (100/10000)
    (duration-multiplier (/ duration-blocks u1008)) ;; Blocks per week approximation
  )
  (/ (* (* coverage-amount base-rate) (* risk-multiplier duration-multiplier)) u10000))
)

(define-read-only (get-total-premium-pool)
  (var-get total-premium-pool)
)

(define-read-only (get-policy-counter)
  (var-get policy-counter)
)

;; Administrative functions
(define-public (set-oracle-address (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set oracle-address new-oracle)
    (ok true)
  )
)

(define-public (update-protocol-risk (protocol (string-ascii 64)) (risk-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= risk-level u1) (<= risk-level u10)) ERR-INVALID-ORACLE-DATA)
    (map-set protocol-risk-scores protocol {
      risk-level: risk-level,
      last-updated: block-height
    })
    (ok true)
  )
)

(define-public (report-exploit (protocol (string-ascii 64)) (exploit-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-NOT-AUTHORIZED)
    (map-set exploit-events protocol {
      is-exploited: true,
      exploit-amount: exploit-amount,
      block-height: block-height,
      verified: true
    })
    (ok true)
  )
)

;; Core insurance functions
(define-public (create-policy 
  (protocol-address (string-ascii 64))
  (coverage-amount uint)
  (duration-blocks uint))
  (let (
    (policy-id (+ (var-get policy-counter) u1))
    (calculated-premium (calculate-premium coverage-amount protocol-address duration-blocks))
    (current-policies (get-user-policies tx-sender))
  )
  (asserts! (>= calculated-premium (var-get minimum-premium)) ERR-MINIMUM-PREMIUM)
  (asserts! (> coverage-amount u0) ERR-INVALID-POLICY)
  (asserts! (> duration-blocks u0) ERR-INVALID-POLICY)
  
  ;; Transfer premium from user to contract
  (try! (stx-transfer? calculated-premium tx-sender (as-contract tx-sender)))
  
  ;; Create policy record
  (map-set policies policy-id {
    policy-holder: tx-sender,
    protocol-address: protocol-address,
    coverage-amount: coverage-amount,
    premium-paid: calculated-premium,
    start-block: block-height,
    end-block: (+ block-height duration-blocks),
    is-active: true,
    claim-processed: false
  })
  
  ;; Update user policies list
  (map-set user-policies tx-sender (unwrap-panic (as-max-len? (append current-policies policy-id) u50)))
  
  ;; Update contract state
  (var-set policy-counter policy-id)
  (var-set total-premium-pool (+ (var-get total-premium-pool) calculated-premium))
  
  (ok policy-id))
)

(define-public (file-claim (policy-id uint))
  (let (
    (policy-data (unwrap! (get-policy policy-id) ERR-POLICY-NOT-FOUND))
    (protocol (get protocol-address policy-data))
    (exploit-data (get-exploit-event protocol))
  )
  (asserts! (is-eq (get policy-holder policy-data) tx-sender) ERR-NOT-AUTHORIZED)
  (asserts! (get is-active policy-data) ERR-INVALID-POLICY)
  (asserts! (< block-height (get end-block policy-data)) ERR-POLICY-EXPIRED)
  (asserts! (not (get claim-processed policy-data)) ERR-CLAIM-ALREADY-PROCESSED)
  
  ;; Check if exploit actually occurred
  (match exploit-data
    exploit-info (begin
      (asserts! (get is-exploited exploit-info) ERR-INVALID-ORACLE-DATA)
      (asserts! (get verified exploit-info) ERR-INVALID-ORACLE-DATA)
      (asserts! (>= (get block-height exploit-info) (get start-block policy-data)) ERR-INVALID-ORACLE-DATA)
      
      ;; Process payout
      (try! (as-contract (stx-transfer? (get coverage-amount policy-data) tx-sender (get policy-holder policy-data))))
      
      ;; Mark claim as processed
      (map-set policies policy-id (merge policy-data { claim-processed: true, is-active: false }))
      
      (ok (get coverage-amount policy-data))
    )
    ERR-INVALID-ORACLE-DATA
  ))
)

(define-public (cancel-policy (policy-id uint))
  (let (
    (policy-data (unwrap! (get-policy policy-id) ERR-POLICY-NOT-FOUND))
    (blocks-remaining (- (get end-block policy-data) block-height))
    (total-blocks (- (get end-block policy-data) (get start-block policy-data)))
    (refund-amount (/ (* (get premium-paid policy-data) blocks-remaining) total-blocks))
  )
  (asserts! (is-eq (get policy-holder policy-data) tx-sender) ERR-NOT-AUTHORIZED)
  (asserts! (get is-active policy-data) ERR-INVALID-POLICY)
  (asserts! (not (get claim-processed policy-data)) ERR-CLAIM-ALREADY-PROCESSED)
  (asserts! (< block-height (get end-block policy-data)) ERR-POLICY-EXPIRED)
  
  ;; Calculate and process refund
  (if (> refund-amount u0)
    (try! (as-contract (stx-transfer? refund-amount tx-sender (get policy-holder policy-data))))
    true)
  
  ;; Deactivate policy
  (map-set policies policy-id (merge policy-data { is-active: false }))
  
  (ok refund-amount))
)

;; Emergency functions
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
    (ok true)
  )
)

(define-public (pause-new-policies)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set minimum-premium u999999999) ;; Effectively pauses new policies
    (ok true)
  )
)

(define-public (resume-policies (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set minimum-premium new-minimum)
    (ok true)
  )
)

;; Utility functions for batch operations
(define-public (batch-update-risk-scores (protocols (list 10 (string-ascii 64))) (risk-levels (list 10 uint)))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (len protocols) (len risk-levels)) ERR-INVALID-ORACLE-DATA)
    (ok (map update-single-risk protocols risk-levels))
  )
)

(define-private (update-single-risk (protocol (string-ascii 64)) (risk-level uint))
  (map-set protocol-risk-scores protocol {
    risk-level: risk-level,
    last-updated: block-height
  })
)

;; Contract initialization
(begin
  ;; Initialize some default protocol risk scores
  (map-set protocol-risk-scores "uniswap-v3" { risk-level: u3, last-updated: block-height })
  (map-set protocol-risk-scores "compound-v3" { risk-level: u4, last-updated: block-height })
  (map-set protocol-risk-scores "aave-v3" { risk-level: u2, last-updated: block-height })
  (map-set protocol-risk-scores "curve-finance" { risk-level: u5, last-updated: block-height })
)