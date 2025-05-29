;; SupplyChainTracker: Product Provenance and Verification System
;; Version: 1.0.0
(define-constant ERR-NOT-MANUFACTURER (err u1))
(define-constant ERR-PRODUCT-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-QUANTITY (err u5))
(define-constant ERR-INVALID-CATEGORY (err u6))
(define-constant ERR-INVALID-CONDITION (err u7))
(define-constant ERR-INVALID-NAME (err u8))
(define-constant ERR-INVALID-DETAILS (err u9))
(define-constant MIN-QUANTITY u1)
(define-data-var next-product-id uint u1)
(define-map supply-chain
    uint
    {
        manufacturer: principal,
        product-name: (string-utf8 50),
        product-details: (string-utf8 200),
        product-category: (string-utf8 10),
        condition: (string-utf8 20),
        status: (string-utf8 10),
        quantity: uint
    }
)
(define-private (validate-category (category (string-utf8 10)))
    (or 
        (is-eq category u"Electronics")
        (is-eq category u"Apparel")
        (is-eq category u"Food")
        (is-eq category u"Automotive")
        (is-eq category u"Pharma")
        (is-eq category u"Luxury")
    )
)
(define-private (validate-condition (condition (string-utf8 20)))
    (or 
        (is-eq condition u"New")
        (is-eq condition u"Refurbished")
        (is-eq condition u"Certified")
        (is-eq condition u"Damaged")
        (is-eq condition u"Recalled")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (register-product 
    (product-name (string-utf8 50))
    (product-details (string-utf8 200))
    (product-category (string-utf8 10))
    (condition (string-utf8 20))
    (quantity uint)
)
    (let
        (
            (product-id (var-get next-product-id))
        )
        (asserts! (validate-text-length product-name u3 u50) ERR-INVALID-NAME)
        (asserts! (validate-text-length product-details u10 u200) ERR-INVALID-DETAILS)
        (asserts! (>= quantity MIN-QUANTITY) ERR-INVALID-QUANTITY)
        (asserts! (validate-category product-category) ERR-INVALID-CATEGORY)
        (asserts! (validate-condition condition) ERR-INVALID-CONDITION)
        
        (map-set supply-chain product-id {
            manufacturer: tx-sender,
            product-name: product-name,
            product-details: product-details,
            product-category: product-category,
            condition: condition,
            status: u"in-transit",
            quantity: quantity
        })
        (var-set next-product-id (+ product-id u1))
        (ok product-id)
    )
)
(define-public (update-product-status (product-id uint) (new-status (string-utf8 10)))
    (let
        (
            (product (unwrap! (map-get? supply-chain product-id) ERR-PRODUCT-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get manufacturer product)) ERR-NOT-MANUFACTURER)
        (asserts! (or 
            (is-eq new-status u"in-transit")
            (is-eq new-status u"delivered")
            (is-eq new-status u"recalled")
        ) ERR-INVALID-STATUS)
        (ok (map-set supply-chain product-id (merge product { status: new-status })))
    )
)
(define-read-only (get-product (product-id uint))
    (ok (map-get? supply-chain product-id))
)
(define-read-only (get-manufacturer (product-id uint))
    (ok (get manufacturer (unwrap! (map-get? supply-chain product-id) ERR-PRODUCT-NOT-FOUND)))
)
