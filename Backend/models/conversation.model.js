const mongoose = require('mongoose')

const conversationSchema = mongoose.Schema({
    creator: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    participants: {
        type: [mongoose.Schema.Types.ObjectId],
        ref: "User",
        required: true
    },
    chatName: {
        type: String
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})

conversationSchema.index({ participants: 1 })

module.exports = mongoose.model("Conversation", conversationSchema)
