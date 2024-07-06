const router = require("express").Router()
const requireAuth = require("../middleware/requireAuth")
const Note = require("../models/note.model")
const User = require("../models/user.model")
const NoteComment = require("../models/noteComment.model")
const CommentLike = require("../models/commentLike.model")
const mongoose = require("mongoose")
router.use(requireAuth)

// Add comment to post
router.post("/add", async (req, res) => {
    const { noteId, textContent } = req.body
    const userId = req.userId
    if (!userId || !noteId || userId === "" || noteId === "" || !textContent || textContent.trim() === "") {
        return res.status(400).json({ message: "User Id, note Id, or comment content not provided" });
    }
    try {
        const note = await Note.findById(noteId)
        if (!note) {
            return res.status(400).json({ message: "Note not found" })
        }
        const noteComment = new NoteComment({
            noteId,
            userId,
            textContent
        })
        const user = await User.findById(userId, { password: 0 })
        if (!user) {
            return res.status(400).json({ message: "User not found"})
        }
        await noteComment.save()
        note.commentCount += 1
        await note.save()
        return res.status(200).json({ comment: {...noteComment.toObject(), hasLiked: false}, author: user })
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error adding comment'})
    }
})

// Like comment
router.post("/like", async (req, res) => {
    const userId = req.userId
    const { commentId } = req.body
    if (!userId || !commentId || userId === "" || commentId === "") {
        return res.status(400).json({ message: "User Id or comment Id is missing" });
    }
    try {
        // Check if user has already liked comment
        const commentLike = await CommentLike.findOne({ commentId, userId })
        if (commentLike) {
            return res.status(400).json({ message: "Already liked comment" })
        }
        const comment = await NoteComment.findById(commentId)
        if (!comment) {
            return res.status(400).json({ message: "Comment doesn't exist" })
        }
        const newCommentLike = new CommentLike({
            commentId,
            userId
        })
        await newCommentLike.save()
        comment.likeCount += 1
        await comment.save()
        const returnJson = {...comment.toObject(), hasLiked: true}
        return res.status(200).json(returnJson)
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error liking comment'})
    }  
})

// Unlike comment
router.post("/unlike", async (req, res) => {
    const userId = req.userId
    const { commentId } = req.body
    if (!userId || !commentId || userId === "" || commentId === "") {
        return res.status(400).json({ message: "User Id or comment Id is missing" });
    }
    try {
        // Check if user has already liked comment
        const commentLike = await CommentLike.findOne({ commentId, userId })
        if (!commentLike) {
            return res.status(400).json({ message: "Already hasn't liked comment" })
        }
        const comment = await NoteComment.findById(commentId)
        if (!comment) {
            return res.status(400).json({ message: "Comment doesn't exist" })
        }

        comment.likeCount -= 1
        await commentLike.deleteOne()
        await comment.save()
        const returnJson = {...comment.toObject(), hasLiked: false}
        return res.status(200).json(returnJson)
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error liking comment'})
    }  
})

// Fetch more comments
router.get("/fetch", async (req, res) => {
    const page = parseInt(req.query.page)
    const noteId = req.query.noteId
    var limit = parseInt(req.query.limit)
    if (limit > 10) {
        limit = 10
    }
    const clientUserId = req.userId
    try {
        // Fetch page of comments
        const comments = await NoteComment.aggregate()
            .match({ noteId: new mongoose.Types.ObjectId(noteId) })
            .skip((page - 1) * limit)
            .limit(limit)
            .sort({ likeCount: -1 })
            .exec()

        // Send author object of each comment back to client
        var commentsAndUsers = []
        for (const comment of comments) {
            const user = await User.findById(comment.userId, { password: 0 })

            // Check whether client user has liked the comment
            const commentLike = await CommentLike.findOne({ userId: clientUserId, commentId: comment._id })
            const hasLiked = !!commentLike // Convert to boolean

            if (user) { 
                // Include hasLiked field in the comment
                const commentPackage = {
                    ...comment,
                    hasLiked
                }
                commentsAndUsers.push({ comment: commentPackage, author: user })
            }
        }
        return res.status(200).json(commentsAndUsers.length > 0 ? commentsAndUsers : [])
    } catch (error) {
        console.log(error)
        return res.status(500).json({ message: 'Error fetching comments'})
    }
})

module.exports = router