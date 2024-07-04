const router = require('express').Router()
const User = require('../models/user.model')
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken');
const useAuth = require('../middleware/requireAuth')

// Creates token
const createToken = (id) => {
    return jwt.sign({ id }, process.env.SECRET, { expiresIn: '3d' });
  };
  
  // Hashes passwords
  async function hashPassword(password) {
    try {
      const hashedPassword = await bcrypt.hash(password, 10); // Hash password with salt rounds of 10
      return hashedPassword;
    } catch (error) {
      throw new Error('Error hashing password');
    }
  }

  function validatePassword(password) {
    const minLength = 8;
    const uppercaseRegex = /[A-Z]/;
    const lowercaseRegex = /[a-z]/;
    const numberRegex = /[0-9]/;
    const specialCharRegex = /[!@#$%^&*(),.?":{}|<>]/;

    if (password.length < minLength) {
        return false;
    }
    if (!uppercaseRegex.test(password)) {
        return false;
    }
    if (!lowercaseRegex.test(password)) {
        return false;
    }
    if (!numberRegex.test(password)) {
        return false;
    }
    if (!specialCharRegex.test(password)) {
        return false;
    }
    return true;
}

function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Login
router.post('/login', async (req, res) => {
    const { email, password } = req.body
    try {
        const user = await User.findOne({ email })

        if (!user) {
            return res.status(400).json({ message: "Incorrect email or password" })
        }

        const correctPassword = await bcrypt.compare(password, user.password)

        if (!correctPassword) {
            return res.status(400).json({ message: "Incorrect email or password" })
        }

        const token = createToken(user._id);

        const userWithoutPassword = { ...user.toObject(), password: undefined }
            
        return res.status(200).json({ user: userWithoutPassword, token: token })
    } catch (error) {
        console.log(error)
        return res.status(400).json({ message: "Unknown server error"})
    }
})

// Register
router.post('/register', async (req, res) => {
    const { email, password } = req.body

    if (!validateEmail(email)) {
        return res.status(400).json({ message: "Invalid email" })
    }

    if (!validatePassword(password)) {
        return res.status(400).json({ message: "Password doesn't meet complexity requirements"})
    }

    try {
        const existingUser = await User.findOne({ email })

        if (existingUser) {
            return res.status(400).json({ messsage: "There's already a user registered with this email" })
        }

        const hashedPassword = await hashPassword(password)

        const newUser = new User({
            email,
            password: hashedPassword
        })

        await newUser.save()
        const token = createToken(newUser._id);

        return res.status(200).json({ user: newUser, token: token })
    } catch (error) {
        return res.status(400).json({ message: "Unknown server error"})  
    }
})

router.use(useAuth)

router.post("/submitAPNToken", async (req, res) => {
    const userId = req.userId
    const apnToken = req.body.apnToken
    if (!apnToken || apnToken === "") {
        return res.status(400).json({ message: "No apn token provided" })
    }

    try {
        const user = await User.findById(userId)
        user.apnToken = apnToken
        await user.save()
        return res.status(200).json({ message: "Apn token saved to DB" })
    } catch (error) {
        return res.status(400).json({ message: "Unknown server error" })
    }
})
module.exports = router