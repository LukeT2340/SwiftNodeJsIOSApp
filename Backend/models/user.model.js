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
    sex: {
        type: String,
        required: true
    },
    nativeLanguages: { type: [String] },
    country: { type: String },
    bio: { type: String },
    lastOnline: { type: Date, default: Date.now },
    createdAt: { type: Date, default: Date.now },
    apnToken: { type: String },
    idealLanguagePartner: { type: String },
    hobbies: { type: [String]},
    languageGoals: { type: String }
})

module.exports = mongoose.model('User', userSchema)
