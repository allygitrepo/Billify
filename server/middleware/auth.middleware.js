const jwt = require("jsonwebtoken");
require("dotenv").config();

const authenticate = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({ message: "No token provided. Access denied." });
        }

        const token = authHeader.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        req.user = decoded; // Contains { id, email }
        
        // Attach business_id from header if present (for multi-tenant support)
        const businessId = req.headers['x-business-id'];
        if (businessId) {
            const parsedId = parseInt(businessId);
            if (!isNaN(parsedId)) {
                req.user.business_id = parsedId;
            }
        }

        next();
    } catch (error) {
        console.error("Authentication Error:", error);
        return res.status(401).json({ message: "Invalid or expired token." });
    }
};

module.exports = { authenticate };
