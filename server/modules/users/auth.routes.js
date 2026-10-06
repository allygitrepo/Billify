const express = require("express");
const router = express.Router();
const authController = require("./auth.controller");

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/google", authController.googleLogin);
router.post("/request-otp", authController.requestOTP);
router.post("/verify-otp", authController.verifyOTP);
router.post("/forgot-password/request-otp", authController.requestForgotPasswordOTP);
router.post("/forgot-password/reset", authController.resetForgotPassword);

module.exports = router;
