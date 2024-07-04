const apn = require('apn')
require('dotenv').config()
const User = require('../models/user.model')

// Configure APNs connection
const apnProvider = new apn.Provider({
    token: {
        key: process.env.APN_P8_KEY_PATH, 
        keyId: process.env.APN_KEY_ID,
        teamId: process.env.APN_TEAM_ID
    },
    production: false 
})

sendNotification = async (userId, message) => {
    try {
        const receiver = await User.findById(userId)
        const sender = await User.findById(message.sender)
        if (!receiver || !sender) {
            return
        }

        var notificationBody = ''

        if (message.text && message.text !== "") {
            notificationBody = message.text
        } else if (message.image && message.image !== "") {
            notificationBody = '[Image]'
        } else if (message.voiceMessage && message.voiceMessage != "") {
            notificationBody = '[Voice Message]'
        }

        // Prepare the notification content
        const notification = new apn.Notification({
            topic: process.env.APN_TOPIC,
            alert: {
                title: `${sender.username}`,
                body: notificationBody
            },
            sound: 'default',
            badge: 1
        })

        // Device token of the iOS device
        const deviceToken = receiver.apnToken

        // Send the notification
        const response = await apnProvider.send(notification, deviceToken)
    }   
    catch (error) {
        console.log(error)
    }
}

module.exports = sendNotification