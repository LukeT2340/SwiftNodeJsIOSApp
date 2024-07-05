const router = require("express").Router()
const requireAuth = require("../middleware/requireAuth")
const Note = require("../models/note.model")
const User = require("../models/user.model")
const NoteComment = require("../models/noteComment.model")
const NoteLike = require("../models/noteLike.model")
const CommentLike = require("../models/commentLike.model")
router.use(requireAuth)

// Create new post
router.post("/create", async (req, res) => {
    const author = req.userId
    const { textContent, mediaContent } = req.body
    try {
        const note = new Note({
            author,
            textContent,
            mediaContent
        })
        await note.save()
        return res.status(201).json(note)
    } catch (error) {
        return res.status(400).json({ message: "Error creating note" })
    }
})

// Like note
router.post("/like", async (req, res) => {
    const userId = req.userId
    const { noteId } = req.body

    try {
        // check if user has liked note
        const noteLike = await NoteLike.findOne({ userId, noteId })
        if (noteLike) {
            return res.status(400).json({ message: "Note already liked" })
        }

        const note = await Note.findOne({ _id: noteId })
        if (!note) {
            return res.status(400).json({ message: "Note not found" })
        }

        const newNoteLike = new NoteLike({
            userId,
            noteId
        })

        await newNoteLike.save()
        note.likeCount += 1

        await note.save()
        const noteWithLikeStatus = {
            ...note.toObject(),
            hasLiked: true
        }
        return res.status(200).json(noteWithLikeStatus)
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error liking note'})
    }
})

// Unlike post
router.post("/unlike", async (req, res) => {
    const userId = req.userId
    const { noteId } = req.body
    try {
        // make sure user has liked note
        const noteLike = await NoteLike.findOne({ userId, noteId })
        if (!noteLike) {
            return res.status(400).json({ message: "Note hasn't liked note" })
        }
        
        const note = await Note.findById(noteId)
        if (!note) {
            return res.status(400).json({ message: "Note couldn't be found" })
        }

        await noteLike.deleteOne()
        note.likeCount -= 1
        await note.save()
        const noteWithLikeStatus = {
            ...note.toObject(),
            hasLiked: false
        }
        return res.status(200).json(noteWithLikeStatus)
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error unliking note' })
    }
})

// Fetch paginated pages
router.get('/fetch', async (req, res) => {
    const page = parseInt(req.query.page)
    var limit = parseInt(req.query.limit)
    let userProfileId = req.query.userId
    if (limit > 10) {
        limit = 10
    }
    const clientUserId = req.userId

    try {
        // Build the aggregation pipeline
        const pipeline = []

        // Add a $match stage if userId is provided
        if (userProfileId && userProfileId !== "") {
            pipeline.push(
                { $match: { author: userProfileId } }
            )
        }

        // Add sorting, skipping, and limiting stages
        pipeline.push(
            { $sort: { createdAt: -1 } },
            { $skip: (page - 1) * limit },
            { $limit: limit }
        )
     
        // Fetch page of notes using the pipeline
        const notes = await Note.aggregate(pipeline).exec()

        // Send author object of each note back to client
        var notesAndUsers = []
        for (const note of notes) {
            const user = await User.findById(note.author, { password: 0 })
        
            // Check whether client user has liked the note
            const noteLike = await NoteLike.findOne({ userId: clientUserId, noteId: note._id })
            const hasLiked = !!noteLike // Convert to boolean
        
            if (user) {
                // Send three comments back to the as well
                const comments = await NoteComment.find({ noteId: note._id })
                    .sort({ likeCount: -1 }) 
                    .limit(4)
                var commentsAndAuthors = []
                for (const comment of comments) {
                    const commentAuthor = await User.findOne({ _id: comment.userId }, { password: 0 })
                    const commentLike = await CommentLike.findOne({commentId: comment._id, userId: req.userId})
                    const commentWithHasLiked = {...comment.toObject(), hasLiked: !!commentLike}
                    if (commentAuthor) {
                        commentsAndAuthors.push({comment: commentWithHasLiked, author: commentAuthor})
                    }
                }
            
                // Include hasLiked field in the note
                const notePackage = {
                    ...note,
                    hasLiked: hasLiked
                }
                notesAndUsers.push({ note: notePackage, author: user, commentsAndAuthors })
            }
        }
        console.log(notesAndUsers.length)
        return res.status(200).json(notesAndUsers)
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error fetching notes' })
    }
})

// Fetch one note
router.get('/fetchOne/:noteId', async (req, res) => {
    const noteId = req.params.noteId
    const clientUserId = req.userId

    try {
        const note = await Note.findById(noteId)

        if (!note) {
            return res.status(400).json({ message: "Note not found" })
        }

        const user = await User.findById(note.author, { password: 0 })
        
        // Check whether client user has liked the note
        const noteLike = await NoteLike.findOne({ userId: clientUserId, noteId: note._id })
        const hasLiked = !!noteLike // Convert to boolean
    
        if (user) {
            // Send three comments back to the as well
            const comments = await NoteComment.find({ noteId: note._id })
                .sort({ likeCount: -1 }) 
                .limit(8)

            var commentsAndAuthors = []
            for (const comment of comments) {
                const commentAuthor = await User.findOne({ _id: comment.userId }, { password: 0 })
                const commentLike = await CommentLike.findOne({commentId: comment._id, userId: req.userId})
                const commentWithHasLiked = {...comment.toObject(), hasLiked: !!commentLike}
                if (commentAuthor) {
                    commentsAndAuthors.push({comment: commentWithHasLiked, author: commentAuthor})
                }
            }
        
            // Include hasLiked field in the note
            const notePackage = {
                ...note.toObject(),
                hasLiked: hasLiked
            }
            return res.status(200).json({ note: notePackage, author: user, commentsAndAuthors })
        }
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error fetching notes' })
    }
})

module.exports = router