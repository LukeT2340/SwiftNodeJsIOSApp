const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    conversationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Conversation',
        required: true
    },
    sender: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    readBy: {
        type: [mongoose.Schema.Types.ObjectId],
        ref: 'User',
        default: []
    },
    text: {
        type: String
    },
    voiceMessage: {
        type: String,
    },
    duration: {
        type: Number
    },
    video: {
        type: String
    },
    image: {
        type: String 
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    tempId: {
        type: String
    },
    isSystemMessage: {
        type: Boolean
    }
})

module.exports = mongoose.model('Message', messageSchema);
