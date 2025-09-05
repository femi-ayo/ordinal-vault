;; Title: OrdinalVault - Bitcoin-Native NFT Treasury & Liquidity Protocol 
;;
;; Summary: Revolutionary Bitcoin-secured digital asset management platform
;; that transforms NFTs into productive financial instruments through      
;; decentralized vaulting, fractional ownership, and automated yield       
;; generation powered by Stacks' smart contract capabilities.              
;;
;; Description: OrdinalVault bridges the gap between Bitcoin's pristine    
;; security and DeFi innovation by creating a sophisticated treasury       
;; management system for digital collectibles. Users can securely mint    
;; collateral-backed NFTs, engage in trustless peer-to-peer trading,      
;; unlock liquidity through innovative share tokenization, and generate   
;; passive income via intelligent staking mechanisms. Built on Stacks,    
;; every transaction inherits Bitcoin's immutable security while enabling  
;; programmable money features that traditional Bitcoin cannot provide.    
;; Perfect for institutions, collectors, and DeFi enthusiasts seeking     
;; maximum security with optimal capital efficiency.                      

;;                              CORE CONSTANTS                               

(define-constant CONTRACT-OWNER tx-sender)

;; Error constants for comprehensive error handling
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-LISTING-NOT-FOUND (err u104))
(define-constant ERR-INVALID-PRICE (err u105))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u106))
(define-constant ERR-ALREADY-STAKED (err u107))
(define-constant ERR-NOT-STAKED (err u108))
(define-constant ERR-INVALID-PERCENTAGE (err u109))
(define-constant ERR-INVALID-URI (err u110))
(define-constant ERR-INVALID-RECIPIENT (err u111))
(define-constant ERR-OVERFLOW (err u112))

;;                           PROTOCOL PARAMETERS                             

;; Bitcoin-inspired conservative collateral requirements
(define-data-var min-collateral-ratio uint u150) ;; 150% over-collateralization
(define-data-var protocol-fee uint u25) ;; 2.5% marketplace fee (250 basis points)
(define-data-var total-staked uint u0) ;; Total staked NFT count
(define-data-var yield-rate uint u50) ;; 5% annual yield (500 basis points)
(define-data-var total-supply uint u0) ;; Global NFT counter

;;                             DATA STRUCTURES                               

;; Primary NFT registry with comprehensive metadata
(define-map tokens
  { token-id: uint }
  {
    owner: principal,
    uri: (string-ascii 256),
    collateral: uint,
    is-staked: bool,
    stake-timestamp: uint,
    fractional-shares: uint,
  }
)

;; Decentralized marketplace listings
(define-map token-listings
  { token-id: uint }
  {
    price: uint,
    seller: principal,
    active: bool,
  }
)

;; Fractional ownership tracking for enhanced liquidity
(define-map fractional-ownership
  {
    token-id: uint,
    owner: principal,
  }
  { shares: uint }
)

;; Yield generation and reward distribution system
(define-map staking-rewards
  { token-id: uint }
  {
    accumulated-yield: uint,
    last-claim: uint,
  }
)

;;                            SECURITY UTILITIES                             

;; Validates URI format and length constraints
(define-private (validate-uri (uri (string-ascii 256)))
  (let ((uri-len (len uri)))
    (and
      (> uri-len u0)
      (<= uri-len u256)
    )
  )
)

;; Prevents self-transfers and contract ownership conflicts
(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient (as-contract tx-sender)))
)

;; Overflow protection for arithmetic operations
(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((sum (+ a b)))
    (asserts! (>= sum a) ERR-OVERFLOW)
    (ok sum)
  )
)

;;                        COLLATERAL-BACKED NFT SYSTEM                       

;; Mints new NFT with STX collateral backing - Bitcoin-inspired security model
(define-public (mint-nft
    (uri (string-ascii 256))
    (collateral uint)
  )
  (let (
      (token-id (+ (var-get total-supply) u1))
      (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
    )
    (asserts! (validate-uri uri) ERR-INVALID-URI)
    (asserts! (>= (stx-get-balance tx-sender) collateral-requirement)
      ERR-INSUFFICIENT-COLLATERAL
    )

    ;; Lock collateral in contract vault
    (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))

    ;; Register new NFT with full metadata
    (map-set tokens { token-id: token-id } {
      owner: tx-sender,
      uri: uri,
      collateral: collateral,
      is-staked: false,
      stake-timestamp: u0,
      fractional-shares: u0,
    })

    (var-set total-supply token-id)
    (ok token-id)
  )
)

;; Secure NFT transfer with ownership verification
(define-public (transfer-nft
    (token-id uint)
    (recipient principal)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)

    ;; Execute ownership transfer
    (map-set tokens { token-id: token-id } (merge token { owner: recipient }))
    (ok true)
  )
)

;;                         TRUSTLESS MARKETPLACE ENGINE                      

;; Creates marketplace listing for peer-to-peer trading
(define-public (list-nft
    (token-id uint)
    (price uint)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)

    ;; Create active marketplace listing
    (map-set token-listings { token-id: token-id } {
      price: price,
      seller: tx-sender,
      active: true,
    })
    (ok true)
  )
)

;; Executes atomic purchase with automated fee distribution
(define-public (purchase-nft (token-id uint))
  (let (
      (listing (unwrap! (get-listing token-id) ERR-LISTING-NOT-FOUND))
      (price (get price listing))
      (seller (get seller listing))
      (fee (/ (* price (var-get protocol-fee)) u1000))
    )
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)

    ;; Execute payment to seller
    (try! (stx-transfer? price tx-sender seller))

    ;; Collect protocol fee for treasury
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))

    ;; Transfer NFT ownership
    (try! (transfer-nft token-id tx-sender))

    ;; Clear marketplace listing
    (map-set token-listings { token-id: token-id } {
      price: u0,
      seller: seller,
      active: false,
    })
    (ok true)
  )
)

;;                      FRACTIONAL OWNERSHIP & LIQUIDITY                     

;; Enables fractional share transfers for enhanced liquidity
(define-public (transfer-shares
    (token-id uint)
    (recipient principal)
    (share-amount uint)
  )
  (let (
      (sender-shares (unwrap! (get-fractional-shares token-id tx-sender)
        ERR-INSUFFICIENT-BALANCE
      ))
      (current-recipient-shares (default-to { shares: u0 } (get-fractional-shares token-id recipient)))
      (recipient-new-shares (unwrap! (safe-add (get shares current-recipient-shares) share-amount)
        ERR-OVERFLOW
      ))
    )
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (>= (get shares sender-shares) share-amount)
      ERR-INSUFFICIENT-BALANCE
    )

    ;; Update sender's fractional position
    (map-set fractional-ownership {
      token-id: token-id,
      owner: tx-sender,
    } { shares: (- (get shares sender-shares) share-amount) }
    )

    ;; Update recipient's fractional position
    (map-set fractional-ownership {
      token-id: token-id,
      owner: recipient,
    } { shares: recipient-new-shares }
    )

    (ok true)
  )
)

;;                         YIELD GENERATION PROTOCOL                         

;; Stakes NFT to generate yield - Bitcoin-secured passive income
(define-public (stake-nft (token-id uint))
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)

    ;; Initialize staking state
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: true,
        stake-timestamp: stacks-block-height,
      })
    )

    ;; Initialize reward tracking
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })

    (var-set total-staked (+ (var-get total-staked) u1))
    (ok true)
  )
)

;; Unstakes NFT and claims final rewards
(define-public (unstake-nft (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
      (rewards (unwrap! (get-staking-rewards token-id) ERR-NOT-STAKED))
    )
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (get is-staked token) ERR-NOT-STAKED)

    ;; Claim accumulated rewards before unstaking
    (try! (claim-staking-rewards token-id))

    ;; Reset staking state
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: false,
        stake-timestamp: u0,
      })
    )

    (var-set total-staked (- (var-get total-staked) u1))
    (ok true)
  )
)

;;                             QUERY INTERFACE                               

;; Retrieves comprehensive token metadata
(define-read-only (get-token-info (token-id uint))
  (map-get? tokens { token-id: token-id })
)

;; Fetches active marketplace listing details
(define-read-only (get-listing (token-id uint))
  (map-get? token-listings { token-id: token-id })
)

;; Returns fractional ownership position
(define-read-only (get-fractional-shares
    (token-id uint)
    (owner principal)
  )
  (map-get? fractional-ownership {
    token-id: token-id,
    owner: owner,
  })
)

;; Retrieves staking reward information
(define-read-only (get-staking-rewards (token-id uint))
  (map-get? staking-rewards { token-id: token-id })
)

;; Calculates real-time staking rewards
(define-read-only (calculate-rewards (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
      (rewards (unwrap! (get-staking-rewards token-id) ERR-NOT-STAKED))
      (blocks-staked (- stacks-block-height (get stake-timestamp token)))
      (yield-per-block (/ (var-get yield-rate) u52560)) ;; ~52,560 blocks/year
      (new-rewards (* blocks-staked yield-per-block))
    )
    (ok (+ (get accumulated-yield rewards) new-rewards))
  )
)

;;                          INTERNAL REWARD SYSTEM                           

;; Internal function to process reward claims
(define-private (claim-staking-rewards (token-id uint))
  (let (
      (rewards (unwrap! (calculate-rewards token-id) ERR-NOT-STAKED))
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
    )
    (asserts! (get is-staked token) ERR-NOT-STAKED)

    ;; Reset reward counter after claim
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })

    ;; Distribute STX rewards to token owner
    (as-contract (stx-transfer? rewards (as-contract tx-sender) (get owner token)))
  )
)

;; Yield generation and reward distribution system
(define-map staking-rewards
  { token-id: uint }
  {
    accumulated-yield: uint,
    last-claim: uint,
  }
)

;;                            SECURITY UTILITIES                             

;; Validates URI format and length constraints
(define-private (validate-uri (uri (string-ascii 256)))
  (let ((uri-len (len uri)))
    (and
      (> uri-len u0)
      (<= uri-len u256)
    )
  )
)

;; Prevents self-transfers and contract ownership conflicts
(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient (as-contract tx-sender)))
)

;; Overflow protection for arithmetic operations
(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((sum (+ a b)))
    (asserts! (>= sum a) ERR-OVERFLOW)
    (ok sum)
  )
)

;;                        COLLATERAL-BACKED NFT SYSTEM                       

;; Mints new NFT with STX collateral backing - Bitcoin-inspired security model
(define-public (mint-nft
    (uri (string-ascii 256))
    (collateral uint)
  )
  (let (
      (token-id (+ (var-get total-supply) u1))
      (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
    )
    (asserts! (validate-uri uri) ERR-INVALID-URI)
    (asserts! (>= (stx-get-balance tx-sender) collateral-requirement)
      ERR-INSUFFICIENT-COLLATERAL
    )

    ;; Lock collateral in contract vault
    (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))

    ;; Register new NFT with full metadata
    (map-set tokens { token-id: token-id } {
      owner: tx-sender,
      uri: uri,
      collateral: collateral,
      is-staked: false,
      stake-timestamp: u0,
      fractional-shares: u0,
    })

    (var-set total-supply token-id)
    (ok token-id)
  )
)

;; Secure NFT transfer with ownership verification
(define-public (transfer-nft
    (token-id uint)
    (recipient principal)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)

    ;; Execute ownership transfer
    (map-set tokens { token-id: token-id } (merge token { owner: recipient }))
    (ok true)
  )
)

;;                         TRUSTLESS MARKETPLACE ENGINE                      

;; Creates marketplace listing for peer-to-peer trading
(define-public (list-nft
    (token-id uint)
    (price uint)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)

    ;; Create active marketplace listing
    (map-set token-listings { token-id: token-id } {
      price: price,
      seller: tx-sender,
      active: true,
    })
    (ok true)
  )
)

;; Executes atomic purchase with automated fee distribution
(define-public (purchase-nft (token-id uint))
  (let (
      (listing (unwrap! (get-listing token-id) ERR-LISTING-NOT-FOUND))
      (price (get price listing))
      (seller (get seller listing))
      (fee (/ (* price (var-get protocol-fee)) u1000))
    )
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)

    ;; Execute payment to seller
    (try! (stx-transfer? price tx-sender seller))

    ;; Collect protocol fee for treasury
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))

    ;; Transfer NFT ownership
    (try! (transfer-nft token-id tx-sender))

    ;; Clear marketplace listing
    (map-set token-listings { token-id: token-id } {
      price: u0,
      seller: seller,
      active: false,
    })
    (ok true)
  )
)
