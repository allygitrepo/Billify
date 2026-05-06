const express = require("express");
const router = express.Router();
const authController = require("./auth.controller");

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/google", authController.googleLogin);
router.post("/request-otp", authController.requestOTP);
router.post("/verify-otp", authController.verifyOTP);


module.exports = router;
