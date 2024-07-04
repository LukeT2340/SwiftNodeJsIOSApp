const router = require('express').Router()
const useAuth = require('../middleware/requireAuth')
const OSS = require('ali-oss')
const multer = require('multer')
const path = require('path')
const fs = require('fs') 
require('dotenv').config()

// Alibaba oss storage
const client = new OSS({
  region: process.env.OSS_REGION, 
  accessKeyId: process.env.OSS_ACCESS_KEY_ID,
  accessKeySecret: process.env.OSS_ACCESS_KEY_SECRET,
  bucket: process.env.OSS_BUCKET,
  secure: true
})
const upload = multer({ dest: 'uploads/' })

router.use(useAuth)

// upload media
router.post('/upload', upload.single('file'), async (req, res) => {
    try {
        const filePath = req.file.path
        const fileName = path.basename(filePath)
  
        // Upload the file to OSS
        const result = await client.put(fileName, filePath)
        // Respond with the file URL
        res.status(201).json(result.url)
        fs.unlinkSync(filePath)
    } catch (err) {
      console.error('Error uploading file:', err)
      res.status(500).send('Failed to upload file')
    }
})

module.exports = router