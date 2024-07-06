// socketHandlers.js
const Conversation = require('../models/conversation.model')
const Message = require('../models/message.model')
const User = require('../models/user.model')
const sendNotification = require('../utils/sendNotification')

module.exports = function (io) {
    io.on('connection', (socket) => {
        const { clientUserId } = socket.handshake.query;

        console.log(`A user connected to room: ${clientUserId}`);

        socket.join(clientUserId);

        socket.on('Message', async (data) => {
            try {
                const { conversationId, sender, text, tempId, video, image, voiceMessage, duration } = data

                // Check if conversation exists
                const conversation = await Conversation.findById(conversationId)
                if (!conversation) {
                    console.error(`Conversation with ID ${conversationId} not found`)
                }

                // Save message
                const message = new Message({
                    conversationId: conversationId,
                    sender: sender,
                    readBy: [sender],
                    tempId: tempId
                })

                if (text && text != "") {
                    message.text = text
                } else if (video && video != "") {
                    message.video = video
                } else if (image && image != "") {
                    message.image = image
                } else if (voiceMessage && voiceMessage != "" && duration > 0) {
                    message.voiceMessage = voiceMessage
                    message.duration = duration
                }

                await message.save()

                // Emit message to all participants in the conversation
                conversation.participants.forEach(userId => {
                    sendNotification(userId, message)
                    io.to(String(userId)).emit('Message', message)
                })

            } catch (error) {
                console.error('Error sending message:', error)
            }
        })

        socket.on('Message', async (data) => {
            try {
                const { conversationId, sender, text, tempId, video, image, voiceMessage, duration } = data

                // Check if conversation exists
                const conversation = await Conversation.findById(conversationId)
                if (!conversation) {
                    console.error(`Conversation with ID ${conversationId} not found`)
                }

                // Save message
                const message = new Message({
                    conversationId: conversationId,
                    sender: sender,
                    readBy: [sender],
                    tempId: tempId
                })

                if (text && text != "") {
                    message.text = text
                } else if (video && video != "") {
                    message.video = video
                } else if (image && image != "") {
                    message.image = image
                } else if (voiceMessage && voiceMessage != "" && duration > 0) {
                    message.voiceMessage = voiceMessage
                    message.duration = duration
                }

                await message.save()

                // Emit message to all participants in the conversation
                conversation.participants.forEach(userId => {
                    sendNotification(userId, message)
                    io.to(String(userId)).emit('Message', message)
                })

            } catch (error) {
                console.error('Error sending message:', error)
            }
        })

        socket.on('LastOnline', async (data) => {
            try {
                const { lastOnline } = data
                // Update user's lastOnline time
                const user = await User.findById(clientUserId)
                if (!user) {
                    throw new Error('User not found')
                }
                user.lastOnline = new Date(lastOnline)
                await user.save()

                // Find conversations involving this user
                const conversations = await Conversation.find({ participants: {$in: [clientUserId]}})

                // Emit lastOnline update to each participant in each conversation
                // Use a Set to keep track of emitted participant IDs
                let emittedParticipants = new Set()

                conversations.forEach((conversation) => {
                    conversation.participants.forEach((participantId) => {
                        if (!emittedParticipants.has(participantId)) {
                            io.to(String(participantId)).emit('lastOnlineUpdate', { userId: clientUserId, lastOnline: user.lastOnline })
                            emittedParticipants.add(participantId)
                        }
                    })
                })

            } catch (error) {
                console.error('Error updating lastOnline:', error)
            }
        })

        socket.on('disconnect', () => {
            console.log('A user disconnected')
        })
    })
}