const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

// Require this middleware on routes where user should be authenticated when accessing
const requireAuth = async (req, res, next) => {
    // Verify authentication
    const { authorization } = req.headers;

    if (!authorization) {
        return res.status(401).json({ error: 'Authorization token required' });
    }

    // Get token from header
    const token = authorization.split(' ')[1];

    // Try to retrieve user from db then attach id to request
    try {
        const {id} = jwt.verify(token, process.env.SECRET);
        const user = await User.findOne({ _id: id });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        req.userId = user._id;
        next();
    } catch(error) {
        console.log(error);
        res.status(401).json({ error: 'Request is not authorized '});
    }
};

module.exports = requireAuth