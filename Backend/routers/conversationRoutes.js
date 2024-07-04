const Conversation = require('../models/conversation.model')
const Message = require("../models/message.model")
const User = require("../models/user.model")
const requireAuth = require('../middleware/requireAuth')

module.exports = function(io) {
    const router = require('express').Router()
    router.use(requireAuth)

    // Fetch conversation Id given the participants of the conversation or create one if it doesn't exist
    router.post('/fetchId', async (req, res) => {
        const { participants } = req.body
        try {
            if (!participants || !Array.isArray(participants) || participants.length === 0) {
                return res.status(400).json({ message: "Invalid participants data" })
            }

            const existingConversation = await Conversation.findOne({
                participants: { $all: participants },
                $where: `this.participants.length === ${participants.length}`
            })

            if (existingConversation) {
                return res.status(200).json(existingConversation)
            }

            const newConversation = new Conversation({
                creator: req.userId,
                participants
            })

            await newConversation.save()
            return res.status(201).json(newConversation)
            
        } catch (error) {
            console.log(error)
            return res.status(400).json({ message: "Unknown server error" })
        }
    })

    // Fetch all conversations that client user if a part of
    router.get('/fetchAll', async (req, res) => {
        const _id = req.userId
        try {
        const conversations = await Conversation.find({ participants: { $in: [_id] } })
        return res.status(200).json(conversations) 
        } catch (error) {
            console.log(error)
            return res.status(400).json({ message: "Unknown server error" })
        }
    })

    // Add users to conversation
    router.post("/addUsers", async (req, res) => {
        const { conversationId, userIds } = req.body

        // Validate input
        if (!conversationId || !Array.isArray(userIds)) {
            return res.status(400).json({ message: "Conversation ID and User IDs array are required" })
        }

        try {
            // Look for the conversation
            const conversation = await Conversation.findById(conversationId)

            if (!conversation) {
                return res.status(404).json({ message: "Conversation doesn't exist" })
            }

            // Add users to participants (filter out duplicates)
            const newParticipants = userIds.filter(id => !conversation.participants.includes(id))
            conversation.participants.push(...newParticipants)
            await conversation.save()

            for (const userId of newParticipants) {
                try {
                    const user = await User.findById(userId);
            
                    if (user) {
                        // Mark all messages as read by all new participants so as to avoid them fetching entire chat history
                        await Message.updateMany(
                            { conversationId: conversationId },
                            {
                                $addToSet: { readBy: userId }
                            }
                        )

                        const systemMessage = new Message({
                            conversationId: conversationId,
                            text: `${user.username} joined the group chat`, // Localized String
                            isSystemMessage: true
                        })
            
                        await systemMessage.save()
                        let allParticipants = conversation.participants
                        for (const participant of allParticipants) {
                            io.to(String(participant._id)).emit('Message', systemMessage)
                        }
                    }
                } catch (error) {
                    console.error(`Failed to process userId ${userId}:`, error);
                }
            }

            return res.status(200).json(conversation)

        } catch (error) {
            console.error(error)
            return res.status(500).json({ message: "Unknown server error" })
        }
    })

    router.post("/changeGroupChatName", async (req, res) => {
        const { newName, conversationId } = req.body
        if (newName.length > 14) {
            return res.status(400).json({ error: "Name too long"})
        }
        try {
            const conversation = await Conversation.findById(conversationId)
            if (String(conversation.creator) !== String(req.userId)) {
                return res.status(401).json({ error: "Unauthourized" })
            }
            conversation.chatName = newName
            await conversation.save()
            return res.status(201).json({ message: `Updated group chat name to ${newName}` })
        } catch (error) {
            console.error(error)
            return res.status(500).json({ error: "Unknown server error" })
        }
    })
    return router
}