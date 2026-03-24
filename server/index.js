const express = require("express");
const sequelize = require("./config/db");
const cors = require("cors");
require("dotenv").config();
const app = express();
const mainRouter = require("./routes.index");


app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));



// PostgreSQL connect test
(async () => {
    try {
        console.time("DB Connection");
        await sequelize.authenticate();
        console.timeEnd("DB Connection");
        console.log("Database connected!");

        console.time("DB Sync");
        await sequelize.sync({ alter: true });
        console.timeEnd("DB Sync");
        console.log("Tables synced!");
    } catch (err) {
        console.error("DB error:", err);
    }
})();

app.use("/billify", mainRouter);
app.get("/billify/test", (req, res) => {
    res.json(
        {
            status: "Running",
            server: "Shiftledger"
        }
    )
});


app.listen(process.env.PORT, () => {
    console.log(`Server is running on port ${process.env.PORT}`);
});