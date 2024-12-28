;; BrightWeave - Collaborative Brainstorming Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

;; Data Variables
(define-data-var next-session-id uint u1)
(define-data-var next-idea-id uint u1)

;; Data Maps
(define-map Sessions 
    uint 
    {
        owner: principal,
        title: (string-ascii 100),
        description: (string-utf8 500),
        active: bool,
        created-at: uint
    }
)

(define-map Ideas
    uint
    {
        session-id: uint,
        creator: principal,
        content: (string-utf8 1000),
        votes: uint,
        created-at: uint
    }
)

(define-map SessionCollaborators
    {session-id: uint, collaborator: principal}
    bool
)

(define-map UserVotes
    {idea-id: uint, user: principal}
    bool
)

;; Session Management Functions
(define-public (create-session (title (string-ascii 100)) (description (string-utf8 500)))
    (let
        ((session-id (var-get next-session-id)))
        (map-set Sessions session-id {
            owner: tx-sender,
            title: title,
            description: description,
            active: true,
            created-at: block-height
        })
        (var-set next-session-id (+ session-id u1))
        (ok session-id)
    )
)

(define-public (add-collaborator (session-id uint) (collaborator principal))
    (let ((session (unwrap! (map-get? Sessions session-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner session)) err-unauthorized)
        (map-set SessionCollaborators {session-id: session-id, collaborator: collaborator} true)
        (ok true)
    )
)

;; Idea Management Functions
(define-public (submit-idea (session-id uint) (content (string-utf8 1000)))
    (let
        (
            (session (unwrap! (map-get? Sessions session-id) err-not-found))
            (idea-id (var-get next-idea-id))
        )
        (asserts! (or 
            (is-eq tx-sender (get owner session))
            (default-to false (map-get? SessionCollaborators {session-id: session-id, collaborator: tx-sender}))
        ) err-unauthorized)
        
        (map-set Ideas idea-id {
            session-id: session-id,
            creator: tx-sender,
            content: content,
            votes: u0,
            created-at: block-height
        })
        (var-set next-idea-id (+ idea-id u1))
        (ok idea-id)
    )
)

(define-public (vote-idea (idea-id uint))
    (let 
        ((idea (unwrap! (map-get? Ideas idea-id) err-not-found))
         (session (unwrap! (map-get? Sessions (get session-id idea)) err-not-found)))
        
        (asserts! (or 
            (is-eq tx-sender (get owner session))
            (default-to false (map-get? SessionCollaborators {session-id: (get session-id idea), collaborator: tx-sender}))
        ) err-unauthorized)
        
        (asserts! (not (default-to false (map-get? UserVotes {idea-id: idea-id, user: tx-sender}))) err-already-exists)
        
        (map-set Ideas idea-id (merge idea {votes: (+ (get votes idea) u1)}))
        (map-set UserVotes {idea-id: idea-id, user: tx-sender} true)
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-session (session-id uint))
    (map-get? Sessions session-id)
)

(define-read-only (get-idea (idea-id uint))
    (map-get? Ideas idea-id)
)

(define-read-only (is-collaborator (session-id uint) (user principal))
    (default-to false (map-get? SessionCollaborators {session-id: session-id, collaborator: user}))
)