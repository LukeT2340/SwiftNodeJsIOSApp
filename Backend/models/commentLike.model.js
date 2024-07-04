const mongoose = require('mongoose')

const commentLikeSchema = mongoose.Schema({
    commentId: {
        type: mongoose.Types.ObjectId,
        ref: "NoteComment",
        required: true
    },
    userId: {
        type: mongoose.Types.ObjectId,
        ref: "User",
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})

module.exports = mongoose.model("CommentLike", commentLikeSchema)