const mongoose = require('mongoose')

const userSchema = new mongoose.Schema({ 
    email: { type: String, required: true },
    password: { type: String, required: true },
    username: { type: String },
    profilePictureUrl: { type: String },
    targetLanguages: [{ 
        language: { type: String },
        proficiency: { type: Number }
    }],
    nativeLanguages: { type: [String] },
    country: { type: String },
    bio: { type: String },
    lastOnline: { type: Date, default: Date.now },
    createdAt: { type: Date, default: Date.now },
    apnToken: { type: String }
})

module.exports = mongoose.model('User', userSchema)
