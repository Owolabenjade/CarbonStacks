;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-verified (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-project-not-found (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-listing-not-found (err u105))
(define-constant err-price-mismatch (err u106))
(define-constant err-unauthorized (err u107))
(define-constant err-already-retired (err u108))
(define-constant err-invalid-retirement (err u109))
(define-constant err-invalid-checkpoint (err u110))
(define-constant err-verification-failed (err u111))
(define-constant err-not-due-for-verification (err u112))
(define-constant err-invalid-input (err u113))
(define-constant err-invalid-verifier (err u114))

;; Define verification status options
(define-constant STATUS-PENDING u1)
(define-constant STATUS-APPROVED u2)
(define-constant STATUS-REJECTED u3)

;; Define checkpoint types
(define-constant CHECKPOINT-INITIAL u1)
(define-constant CHECKPOINT-QUARTERLY u2)
(define-constant CHECKPOINT-ANNUAL u3)
(define-constant CHECKPOINT-METHODOLOGY u4)

;; Define data variables
(define-data-var total-supply uint u0)
(define-data-var next-project-id uint u1)
(define-data-var next-listing-id uint u1)
(define-data-var next-retirement-id uint u1)
(define-data-var total-retired uint u0)

;; Define data maps
(define-map balances principal uint)
(define-map verifiers principal bool)

(define-map projects
    uint    ;; project-id
    {
        name: (string-ascii 50),
        location: (string-ascii 50),
        total-credits: uint,
        verified-by: principal
    }
)

(define-map listings
    uint    ;; listing-id
    {
        seller: principal,
        amount: uint,
        price: uint,
        active: bool
    }
)

(define-map retired-credits
    uint    ;; retirement-id
    {
        owner: principal,
        amount: uint,
        project-id: uint,
        retirement-time: uint,
        purpose: (string-ascii 100),
        beneficiary: (string-ascii 50)
    }
)

(define-map total-retired-by-project 
    uint  ;; project-id
    uint  ;; total amount retired
)

(define-map verifier-credentials
    principal
    {
        organization: (string-ascii 50),
        certification: (string-ascii 50),
        valid-until: uint,
        reputation-score: uint
    }
)

(define-map project-checkpoints
    {project-id: uint, checkpoint-id: uint}
    {
        checkpoint-type: uint,
        verifier: principal,
        status: uint,
        timestamp: uint,
        details: (string-ascii 200),
        evidence-hash: (buff 32),
        next-verification: uint
    }
)

(define-map project-verification-status
    uint    ;; project-id
    {
        last-checkpoint: uint,
        is-active: bool,
        total-verifications: uint,
        latest-verification: uint
    }
)

;; Validation helper functions
(define-private (is-valid-project-id (project-id uint))
    (is-some (map-get? projects project-id))
)

(define-private (is-valid-verifier (verifier principal))
    (and 
        (is-some (map-get? verifier-credentials verifier))
        (default-to false (map-get? verifiers verifier)))
)

(define-private (is-valid-name (name (string-ascii 50)))
    (and 
        (>= (len name) u1)
        (<= (len name) u50))
)

(define-private (is-valid-details (details (string-ascii 200)))
    (and 
        (>= (len details) u1)
        (<= (len details) u200))
)

(define-private (is-valid-purpose (purpose (string-ascii 100)))
    (and 
        (>= (len purpose) u1)
        (<= (len purpose) u100))
)

(define-private (is-valid-checkpoint-type (checkpoint-type uint))
    (or 
        (is-eq checkpoint-type CHECKPOINT-INITIAL)
        (is-eq checkpoint-type CHECKPOINT-QUARTERLY)
        (is-eq checkpoint-type CHECKPOINT-ANNUAL)
        (is-eq checkpoint-type CHECKPOINT-METHODOLOGY))
)

;; Added validation helper function for checkpoint-id
(define-private (is-valid-checkpoint-id (project-id uint) (checkpoint-id uint))
    (is-some (map-get? project-checkpoints {project-id: project-id, checkpoint-id: checkpoint-id}))
)

;; Updated validation helper functions without the 'principal' function
(define-private (validate-recipient (recipient principal))
    ;; Ensure the recipient is not the contract principal to avoid tokens being locked
    (not (is-eq recipient (as-contract tx-sender)))
)

(define-private (validate-verifier-input (verifier principal))
    ;; Verifier cannot be the contract owner or the contract principal
    (and
        (not (is-eq verifier contract-owner))  ;; Verifier cannot be contract owner
        (not (is-eq verifier (as-contract tx-sender)))  ;; Not the contract principal
    )
)

(define-private (validate-beneficiary (beneficiary (string-ascii 50)))
    (and 
        (>= (len beneficiary) u1)
        (<= (len beneficiary) u50)
        (not (is-eq beneficiary ""))
    )
)

(define-private (validate-evidence-hash (hash (buff 32)))
    (and
        (is-eq (len hash) u32)  ;; Ensure hash is exactly 32 bytes
        (not (is-eq hash 0x))   ;; Not empty hash
    )
)

;; Helper functions
(define-private (is-active-listing (listing-id uint))
    (default-to false (get active (map-get? listings listing-id)))
)

(define-private (get-min (a uint) (b uint))
    (if (<= a b) a b)
)

(define-private (uint-to-uint (n uint))
    n
)

(define-private (retirement-by-owner (retirement-id uint))
    (match (map-get? retired-credits retirement-id)
        retirement (is-eq (get owner retirement) tx-sender)
        false
    )
)

(define-private (generate-sequence (start uint) (length uint))
    (fold add-to-sequence
        (list start)
        (generate-inputs (- length u1)))
)

(define-private (generate-inputs (count uint))
    (list count)
)

(define-private (add-to-sequence (index uint) (acc (list 100 uint)))
    (let
        ((next-num (+ (unwrap-panic (element-at acc (- (len acc) u1))) u1)))
        (unwrap-panic (as-max-len? (append acc next-num) u100))
    )
)

(define-private (check-and-retire 
    (retirement {
        amount: uint,
        project-id: uint,
        purpose: (string-ascii 100),
        beneficiary: (string-ascii 50)
    })
    (previous-result (response bool uint)))
    (match previous-result
        prev-ok 
            (begin
                (asserts! (is-valid-project-id (get project-id retirement)) err-project-not-found)
                (asserts! (is-valid-purpose (get purpose retirement)) err-invalid-input)
                (match (retire-credits 
                        (get amount retirement)
                        (get project-id retirement)
                        (get purpose retirement)
                        (get beneficiary retirement))
                    success-id (ok true)
                    error-code (err error-code))
            )
        prev-err (err prev-err))
)

;; Public functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (default-to false (map-get? verifiers verifier))) err-invalid-verifier)
        (ok (map-set verifiers verifier true)))
)

(define-public (get-balance (account principal))
    (ok (default-to u0 (map-get? balances account)))
)

(define-public (register-project (name (string-ascii 50)) (location (string-ascii 50)))
    (let
        (
            (project-id (var-get next-project-id))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-name name) err-invalid-input)
        (asserts! (is-valid-name location) err-invalid-input)
        
        (map-set projects project-id {
            name: name,
            location: location,
            total-credits: u0,
            verified-by: tx-sender
        })
        (var-set next-project-id (+ project-id u1))
        (ok project-id)
    )
)

;; Updated mint-credits function with recipient validation
(define-public (mint-credits (amount uint) (project-id uint) (recipient principal))
    (let
        (
            (project (unwrap! (map-get? projects project-id) err-project-not-found))
        )
        (asserts! (is-valid-verifier tx-sender) err-not-verified)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-valid-project-id project-id) err-project-not-found)
        (asserts! (validate-recipient recipient) err-invalid-input)  ;; Added validation
        
        (map-set projects project-id (merge project {
            total-credits: (+ (get total-credits project) amount)
        }))
        
        (map-set balances recipient 
            (+ (default-to u0 (map-get? balances recipient)) amount))
        
        (var-set total-supply (+ (var-get total-supply) amount))
        
        (ok true)
    )
)

;; Updated transfer function with recipient validation
(define-public (transfer (amount uint) (recipient principal))
    (let
        (
            (sender-balance (default-to u0 (map-get? balances tx-sender)))
        )
        (asserts! (>= sender-balance amount) err-insufficient-balance)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (validate-recipient recipient) err-invalid-input)  ;; Added validation
        
        (map-set balances tx-sender (- sender-balance amount))
        
        (map-set balances recipient 
            (+ (default-to u0 (map-get? balances recipient)) amount))
        
        (ok true)
    )
)

(define-public (create-listing (amount uint) (price uint))
    (let
        (
            (listing-id (var-get next-listing-id))
            (seller-balance (default-to u0 (map-get? balances tx-sender)))
        )
        (asserts! (>= seller-balance amount) err-insufficient-balance)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (> price u0) err-invalid-amount)
        
        (map-set listings listing-id {
            seller: tx-sender,
            amount: amount,
            price: price,
            active: true
        })
        
        (map-set balances tx-sender (- seller-balance amount))
        
        (var-set next-listing-id (+ listing-id u1))
        (ok listing-id)
    )
)

;; Updated retire-credits function with beneficiary validation
(define-public (retire-credits 
    (amount uint) 
    (project-id uint)
    (purpose (string-ascii 100))
    (beneficiary (string-ascii 50)))
    (let
        (
            (retirement-id (var-get next-retirement-id))
            (user-balance (default-to u0 (map-get? balances tx-sender)))
            (project (unwrap! (map-get? projects project-id) err-project-not-found))
        )
        (asserts! (>= user-balance amount) err-insufficient-balance)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-valid-project-id project-id) err-project-not-found)
        (asserts! (is-valid-purpose purpose) err-invalid-input)
        (asserts! (validate-beneficiary beneficiary) err-invalid-input)  ;; Added validation
        
        ;; Rest of the function remains the same
        (map-set balances tx-sender (- user-balance amount))
        
        (map-set retired-credits retirement-id {
            owner: tx-sender,
            amount: amount,
            project-id: project-id,
            retirement-time: block-height,
            purpose: purpose,
            beneficiary: beneficiary
        })
        
        (map-set total-retired-by-project project-id 
            (+ (default-to u0 (map-get? total-retired-by-project project-id)) amount))
        
        (var-set total-retired (+ (var-get total-retired) amount))
        (var-set next-retirement-id (+ retirement-id u1))
        
        (ok retirement-id)
    )
)

;; Updated register-verifier-credentials function with verifier validation
(define-public (register-verifier-credentials 
    (verifier principal)
    (organization (string-ascii 50))
    (certification (string-ascii 50))
    (valid-until uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (validate-verifier-input verifier) err-invalid-verifier)  ;; Added validation
        (asserts! (is-valid-name organization) err-invalid-input)
        (asserts! (is-valid-name certification) err-invalid-input)
        (asserts! (> valid-until block-height) err-invalid-input)
        
        (map-set verifier-credentials verifier {
            organization: organization,
            certification: certification,
            valid-until: valid-until,
            reputation-score: u100
        })
        (ok true)
    )
)

;; Updated submit-verification-checkpoint function with evidence hash validation
(define-public (submit-verification-checkpoint
    (project-id uint)
    (checkpoint-type uint)
    (details (string-ascii 200))
    (evidence-hash (buff 32)))
    (let
        (
            (project (unwrap! (map-get? projects project-id) err-project-not-found))
            (verifier-cred (unwrap! (map-get? verifier-credentials tx-sender) err-not-verified))
            (current-status (default-to 
                {
                    last-checkpoint: u0,
                    is-active: false,
                    total-verifications: u0,
                    latest-verification: u0
                } 
                (map-get? project-verification-status project-id)))
            (new-checkpoint-id (+ (get last-checkpoint current-status) u1))
        )
        (asserts! (is-valid-verifier tx-sender) err-not-verified)
        (asserts! (> (get valid-until verifier-cred) block-height) err-not-verified)
        (asserts! (is-valid-project-id project-id) err-project-not-found)
        (asserts! (is-valid-checkpoint-type checkpoint-type) err-invalid-input)
        (asserts! (is-valid-details details) err-invalid-input)
        (asserts! (validate-evidence-hash evidence-hash) err-invalid-input)  ;; Added validation
        
        ;; Rest of the function remains the same
        (map-set project-checkpoints 
            {project-id: project-id, checkpoint-id: new-checkpoint-id}
            {
                checkpoint-type: checkpoint-type,
                verifier: tx-sender,
                status: STATUS-PENDING,
                timestamp: block-height,
                details: details,
                evidence-hash: evidence-hash,
                next-verification: (+ block-height 
                    (if (is-eq checkpoint-type CHECKPOINT-QUARTERLY)
                        u1440
                        u4320))
            })
        
        (map-set project-verification-status project-id
            (merge current-status {
                last-checkpoint: new-checkpoint-id,
                is-active: true,
                total-verifications: (+ (get total-verifications current-status) u1),
                latest-verification: block-height
            }))
        
        (ok new-checkpoint-id)
    )
)

;; Continuing public functions
(define-public (approve-checkpoint 
    (project-id uint)
    (checkpoint-id uint))
    (let
        (
            (checkpoint (unwrap! (map-get? project-checkpoints 
                {project-id: project-id, checkpoint-id: checkpoint-id}) 
                err-invalid-checkpoint))
        )
        (asserts! (is-valid-project-id project-id) err-project-not-found)
        (asserts! (is-valid-verifier tx-sender) err-not-verified)
        (asserts! (not (is-eq tx-sender (get verifier checkpoint))) err-unauthorized)
        
        (map-set project-checkpoints 
            {project-id: project-id, checkpoint-id: checkpoint-id}
            (merge checkpoint {status: STATUS-APPROVED}))
        
        (ok true)
    )
)

;; Updated get-checkpoint-details function with checkpoint-id validation
(define-read-only (get-checkpoint-details 
    (project-id uint)
    (checkpoint-id uint))
    (begin
        (asserts! (is-valid-project-id project-id) err-project-not-found)
        (asserts! (is-valid-checkpoint-id project-id checkpoint-id) err-invalid-checkpoint)  ;; Added validation
        (ok (unwrap-panic (map-get? project-checkpoints 
            {project-id: project-id, checkpoint-id: checkpoint-id})))
    )
)

;; Read-only functions
(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)

(define-read-only (get-project (project-id uint))
    (map-get? projects project-id)
)

(define-read-only (get-project-credits (project-id uint))
    (match (map-get? projects project-id)
        project (ok (get total-credits project))
        (err err-project-not-found)
    )
)

(define-read-only (get-active-listing-ids (start uint) (end uint))
    (let
        (
            (count (- (+ end u1) start))
        )
        (filter is-active-listing 
            (if (> count u100)
                (list)
                (map uint-to-uint (list start end))
            )
        )
    )
)

(define-read-only (get-retirement-details (retirement-id uint))
    (map-get? retired-credits retirement-id)
)

(define-read-only (get-project-retired-amount (project-id uint))
    (default-to u0 (map-get? total-retired-by-project project-id))
)

(define-read-only (get-total-retired)
    (ok (var-get total-retired))
)

(define-read-only (verify-retirement (retirement-id uint))
    (match (map-get? retired-credits retirement-id)
        retirement {
            is-valid: true,
            details: (some retirement)
        }
        {
            is-valid: false,
            details: none
        }
    )
)

(define-read-only (get-retirement-history (owner principal) (start uint) (end uint))
    (let
        (
            (count (- (+ u1 end) start))
        )
        (if (> count u100)
            (ok (list))
            (ok (filter retirement-by-owner 
                (generate-sequence start (get-min u100 count))))
        )
    )
)

(define-read-only (get-verifier-credentials (verifier principal))
    (map-get? verifier-credentials verifier)
)

(define-read-only (get-project-verification-status (project-id uint))
    (map-get? project-verification-status project-id)
)

(define-read-only (is-verification-due (project-id uint))
    (match (map-get? project-verification-status project-id)
        status (>= block-height (default-to u0 
            (get next-verification 
                (map-get? project-checkpoints 
                    {project-id: project-id, checkpoint-id: (get last-checkpoint status)}))))
        false
    )
)
