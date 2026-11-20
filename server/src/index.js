import express from "express";
import { pool } from "./db.js";
import authRouter from "./routes/auth.js";


const app = express();
app.use(express.json());

// Health check: proves the server is running AND can reach the database
app.get("/health", async (req, res) => {
  const result = await pool.query("SELECT now()");
  res.json({ status: "ok", dbTime: result.rows[0].now });
});
app.use("/auth", authRouter);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
