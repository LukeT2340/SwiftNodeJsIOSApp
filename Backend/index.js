const express = require('express')
const mongoose = require('mongoose')
const authRoutes = require('./routers/authRoutes')
const userRoutes = require('./routers/userRoutes')
const messageRoutes = require('./routers/messageRoutes')
const mediaRoutes = require('./routers/mediaRoutes')
const noteRoutes = require('./routers/noteRoutes')
const commentRoutes = require('./routers/commentRoutes')
const http = require('http')
const socketIo = require('socket.io')

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

require('./socketHandlers/socketHandlers')(io)

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