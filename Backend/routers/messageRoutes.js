const router = require('express').Router()
const useAuth = require('../middleware/requireAuth')
const Message = require('../models/message.model')
const Conversation = require('../models/conversation.model')

router.use(useAuth)

// Fetch unread messages
router.get('/fetchUnread', async (req, res) => {
    const userId = req.userId
    try {
        const conversations = await Conversation.find({
            participants: { $in: userId },
        })

        let newMessages = []

        for (const conversation of conversations) {
            const messages = await Message.find({ 
                conversationId: conversation._id,
                readBy: { $nin: [userId] },
                sender: { $ne: userId } 
            })
            newMessages = newMessages.concat(messages)
        }
        return res.status(200).json(newMessages)
    } catch (error) {
        return res.status(400).json({ message: "Unknown server error" })
    }
})

// Mark messages as read
router.post('/markRead', async (req, res) => {
    const userId = req.userId
    const conversationId = req.body.conversationId
    try {
        await Message.updateMany(
            {
                conversationId: conversationId,
                sender: { $ne: userId },
                readBy: { $nin: [userId] }
            },
            {
                $addToSet: { readBy: userId }
            }
        )
        return res.status(200).json("Success")
    } catch (error) {
        return res.status(400).json({ message: "Unknown server error" })
    }
})

// Downloads entire chat history for conversation
router.get('/downloadChatHistory/:conversationId', async (req, res) => {
    const conversationId = req.params.conversationId
    const userId = req.userId
    try {
        const conversation = await Conversation.findById(conversationId)
        if (!conversation) {
            return res.status(400).json({ message: "Conversation not found" })
        }
        const messages = await Message.find({ conversationId: conversationId })
        for (const message of messages) {
            if (!message.readBy.includes(userId)) {
                message.readBy.push(userId)
                await message.save()
            }
        }

        return res.status(200).json(messages)
    } catch {
        console.error("Error downloading chat history:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
})

module.exports = router
