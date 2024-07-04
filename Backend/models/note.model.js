const mongoose = require('mongoose')
const Schema = mongoose.Schema

const noteSchema = new Schema({
    author: {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    textContent: String,
    mediaContent: [{
        url: String,
        duration: Number,
        mediaType: String
    }],
    commentCount: {
        type: Number,
        default: 0
    },
    likeCount: {
        type: Number,
        default: 0
    },
    editedAt: {
        type: Date,
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})

noteSchema.pre('save', function(next) {
    this.editedAt = new Date();
    next()
})

const Note = mongoose.model('Note', noteSchema)

module.exports = Note
