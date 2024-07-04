const router = require('express').Router()
const User = require('../models/user.model')
const Conversation = require('../models/conversation.model')
const requireAuth = require('../middleware/requireAuth')
const { route } = require('./authRoutes')

router.use(requireAuth)

// Fetch recommended users
router.get('/fetchRecommended', async (req, res) => {
    try {
        const users = await User.find({}, { _id: 1, username: 1, bio: 1, createdAt: 1, targetLanguages: 1, nativeLanguages: 1, profilePictureUrl: 1, lastOnline: 1}).limit(20)
        return res.status(200).json(users)
    } catch (error) {
        return res.status(400).json({ message: "Unknown server error" })
    }
})

// Fetch users from conversation
router.get('/fetchMany/:conversationId', async (req, res) => {
    const { conversationId } = req.params
    try {
        const conversation = await Conversation.findOne({ _id: conversationId })
        if (!conversation) {
            return res.status(404).json({ message: "Conversation not found" })
        }

        const participantsToFetch = conversation.participants

        const usersPromises = participantsToFetch.map(async _id => {
            if (_id != req.userId) {
                const user = await User.findOne({ _id }, { _id: 1, username: 1, createdAt: 1, targetLanguages: 1, nativeLanguages: 1, profilePictureUrl: 1, lastOnline: 1})
                return user
            }
        })

        const users = await Promise.all(usersPromises)

        return res.status(200).json(users)
    } catch (error) {
        return res.status(500).json({ message: "Internal server error" })
    }
})

// Fetch all contacts 
router.get("/fetchContacts", async (req, res) => {
    try {
        const conversations = await Conversation.find({
            participants: { $in: [req.userId]}
        })

        let uniqueUserIds = new Set()

        conversations.forEach((conversation) => {
            conversation.participants.forEach((userId) => {
                uniqueUserIds.add(userId)
            })
        })

        const uniqueUserIdsArray = Array.from(uniqueUserIds)

        const users = await User.find({ _id: { $in: uniqueUserIdsArray } }, { _id: 1, username: 1, createdAt: 1, targetLanguages: 1, nativeLanguages: 1, profilePictureUrl: 1, lastOnline: 1})

        return res.status(200).json(users)
    } catch (error) {
        return res.status(500).json({ message: "Internal server error" })
    }
})

// Fetch client user
router.get('/fetchClient', async (req, res) => {
    
    try {
        const user = await User.findOne({ _id: req.userId},  { _id: 1, username: 1, createdAt: 1, targetLanguages: 1, nativeLanguages: 1, profilePictureUrl: 1, lastOnline: 1 })

        if (!user) {
            return res.status(400).json({ message: "User not found" })
        }

        return res.status(200).json(user)

    } catch (error) {
        return res.status(400).json({ message: "Unknown server error" })
    }
})

module.exports = router