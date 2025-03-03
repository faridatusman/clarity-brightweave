;; BrightWeave - Collaborative Brainstorming Contract
;; Enhanced version with improved session management and security features

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-milestone (err u104))
(define-constant err-session-inactive (err u105))
(define-constant err-rate-limit (err u106))
(define-constant err-invalid-state (err u107))
(define-constant err-session-expired (err u108))
(define-constant err-invalid-input (err u109))

;; Configuration
(define-data-var submission-cooldown uint u10)
(define-data-var session-timeout uint u1440)  ;; 24 hours in blocks

;; Data Variables
(define-data-var next-session-id uint u1)
(define-data-var next-idea-id uint u1)
(define-data-var next-milestone-id uint u1)
(define-data-var session-version uint u1)

;; Helper Functions
(define-private (is-session-active (session-id uint))
    (match (map-get? Sessions session-id)
        session (and 
            (get active session)
            (< (- block-height (get created-at session)) (var-get session-timeout))
        )
        false
    )
)

(define-private (can-submit-idea (user principal) (session-id uint))
    (match (map-get? LastSubmission {user: user, session-id: session-id})
        last-block (>= (- block-height last-block) (var-get submission-cooldown))
        true
    )
)

;; Data Maps
(define-map Sessions 
    uint 
    {
        owner: principal,
        title: (string-ascii 100),
        description: (string-utf8 500),
        active: bool,
        paused: bool,
        created-at: uint,
        milestone-voting: bool,
        version: uint,
        last-updated: uint,
        archived: bool
    }
)

(define-map LastSubmission
    {user: principal, session-id: uint}
    uint
)

;; [Previous maps remain unchanged]

;; Enhanced Session Management Functions
(define-public (create-session (title (string-ascii 100)) (description (string-utf8 500)))
    (let
        ((session-id (var-get next-session-id)))
        (asserts! (> (len title) u0) err-invalid-input)
        (asserts! (> (len description) u0) err-invalid-input)
        
        (map-set Sessions session-id {
            owner: tx-sender,
            title: title,
            description: description,
            active: true,
            paused: false,
            created-at: block-height,
            milestone-voting: false,
            version: (var-get session-version),
            last-updated: block-height,
            archived: false
        })
        (map-set SessionIdeas session-id (list))
        (var-set next-session-id (+ session-id u1))
        (ok session-id)
    )
)

;; [Additional enhanced functions...]
