const express = require('express')
const mongoose = require('mongoose')
const authRoutes = require('./routers/authRoutes')
const userRoutes = require('./routers/userRoutes')
const messageRoutes = require('./routers/messageRoutes')
const mediaRoutes = require('./routers/mediaRoutes')
const noteRoutes = require('./routers/noteRoutes')
const commentRoutes = require('./routers/commentRoutes')
const User = require('./models/user.model')
const Note = require('./models/note.model')
const Conversation = require('./models/conversation.model')
const http = require('http')
const socketIo = require('socket.io')
const Message = require('./models/message.model')
const sendNotification = require('./utils/sendNotification')

const cors = require('cors')
require('dotenv').config()
const port = process.env.PORT

const app = express()
app.use(express.json())

// Connection URI for your MongoDB database
const mongoURI = process.env.MONGO_URI

// Connect to MongoDB
mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

// Get the default connection
const db = mongoose.connection

// Event handlers for database connection
db.on('connected', () => {
    console.log('Connected to MongoDB')
})

db.on('error', (err) => {
    console.error('MongoDB connection error:', err)
})

db.on('disconnected', () => {
    console.log('Disconnected from MongoDB')
})

// Use cors
app.use(cors({
    origin: '*', // Change in production
    credentials: true,
}))

const server = http.createServer(app)
const io = socketIo(server, {
    cors: {
        origin: '*', // Change in production
        credentials: true,
    },
})

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

/*
x = () => {
    const newUser = new User({
        email: "elonmusk@gmail.com",
        password: "$2b$10$l.G7LNWqlqDtjUDTEecZc./zBgzyUgn8vwz.rhhh6MNuDKCwWn162",
        username: "Elon Musk",
        profilePictureUrl: "https://bucketlangapp.oss-ap-southeast-1.aliyuncs.com/download.jpeg",
        targetLanguages: [
      {
        language: 'English',
        proficiency: 4
      }
    ],
        nativeLanguages: ["Mandarin"],
        bio: "I'm Elon Musk"
    })
    newUser.save()
}

x()
*/

/*
x = async () => {
    for (var i = 0; i < 200; i++) {
        const note = new Note({
            author: '6678c3c78b4c967af02ffb72',
            textContent: `Note number ${i+1}`,
            mediaContent: [
            {
                url: 'https://bucketlangapp.oss-ap-southeast-1.aliyuncs.com/392a992736963c2e01ad366554f387e0',
                duration: null,
                mediaType: 'image'
            }
            ],
            commentCount: 0,
            likeCount: i,
        })
        await note.save()
    }
}

x()
*/
/*
x = async () => {
    const user = await User.findOne({
        username: "m"
    })

    user.username = "Sam Altman"
    user.profilePictureUrl = "https://bucketlangapp.oss-ap-southeast-1.aliyuncs.com/Sam_Altman_2_-_Credit_Chen_Galili_COVER-1100x900.jpg"
    user.save()
}

x()
*/

app.use('/auth', authRoutes)
app.use('/user', userRoutes)
const conversationRoutes = require('./routers/conversationRoutes')(io)
app.use('/conversation', conversationRoutes)
app.use('/message', messageRoutes)
app.use('/media', mediaRoutes)
app.use('/note', noteRoutes)
app.use('/comment', commentRoutes)

server.listen(port, () => {
    console.log(`Listening on port ${port}`)
})