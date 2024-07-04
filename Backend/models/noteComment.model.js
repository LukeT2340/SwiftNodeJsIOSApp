const mongoose = require('mongoose')

const noteCommentSchema = new mongoose.Schema({
    noteId: {
        type: mongoose.Types.ObjectId,
        ref: "Note",
        required: true
    },
    userId: {
        type: mongoose.Types.ObjectId,
        ref: "User",
        required: true
    },
    textContent: {
        type: String
    },
    likeCount: {
        type: Number,
        default: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})

module.exports = mongoose.model("NoteComment", noteCommentSchema)