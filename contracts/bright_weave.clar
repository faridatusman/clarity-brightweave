;; BrightWeave - Collaborative Brainstorming Contract

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

;; Data Variables
(define-data-var next-session-id uint u1)
(define-data-var next-idea-id uint u1)
(define-data-var next-milestone-id uint u1)

;; Session States
(define-data-var session-version uint u1)

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
        last-updated: uint
    }
)

(define-map SessionIdeas
    uint 
    (list 100 uint)
)

(define-map Ideas
    uint
    {
        session-id: uint,
        creator: principal,
        content: (string-utf8 1000),
        votes: uint,
        milestone-votes: uint,
        created-at: uint,
        category: (optional (string-ascii 50))
    }
)

;; [Previous maps remain unchanged]

;; Session Management Functions
(define-public (create-session (title (string-ascii 100)) (description (string-utf8 500)))
    (let
        ((session-id (var-get next-session-id)))
        (map-set Sessions session-id {
            owner: tx-sender,
            title: title,
            description: description,
            active: true,
            paused: false,
            created-at: block-height,
            milestone-voting: false,
            version: (var-get session-version),
            last-updated: block-height
        })
        (map-set SessionIdeas session-id (list))
        (var-set next-session-id (+ session-id u1))
        (ok session-id)
    )
)

(define-public (pause-session (session-id uint))
    (let ((session (unwrap! (map-get? Sessions session-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner session)) err-unauthorized)
        (map-set Sessions session-id (merge session {
            paused: true,
            last-updated: block-height
        }))
        (ok true)
    )
)

(define-public (unpause-session (session-id uint))
    (let ((session (unwrap! (map-get? Sessions session-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner session)) err-unauthorized)
        (map-set Sessions session-id (merge session {
            paused: false,
            last-updated: block-height
        }))
        (ok true)
    )
)

(define-public (submit-idea (session-id uint) (content (string-utf8 1000)) (category (optional (string-ascii 50))))
    (let
        (
            (session (unwrap! (map-get? Sessions session-id) err-not-found))
            (idea-id (var-get next-idea-id))
            (current-ideas (default-to (list) (map-get? SessionIdeas session-id)))
        )
        (asserts! (get active session) err-session-inactive)
        (asserts! (not (get paused session)) err-invalid-state)
        (asserts! (or 
            (is-eq tx-sender (get owner session))
            (default-to false (map-get? SessionCollaborators {session-id: session-id, collaborator: tx-sender}))
        ) err-unauthorized)
        
        (map-set Ideas idea-id {
            session-id: session-id,
            creator: tx-sender,
            content: content,
            votes: u0,
            milestone-votes: u0,
            created-at: block-height,
            category: category
        })
        (map-set SessionIdeas session-id (append current-ideas idea-id))
        (var-set next-idea-id (+ idea-id u1))
        (ok idea-id)
    )
)

;; [Rest of the original functions remain unchanged]

;; New Read-only Functions
(define-read-only (get-session-ideas (session-id uint))
    (map-get? SessionIdeas session-id)
)

(define-read-only (get-session-status (session-id uint))
    (match (map-get? Sessions session-id)
        session (ok {
            active: (get active session),
            paused: (get paused session),
            milestone-voting: (get milestone-voting session)
        })
        err-not-found
    )
)
