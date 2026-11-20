import {Router} from "express";
import { pool } from "../db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { requireAuth } from "../middleware/requireAuth.js";



const router = Router();
function generateToken(user) {
    const payload = {
        sub: user.id,   
    };
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "7d" });
}

router.post("/signup",async (req, res) => { 
    
    const {email,password,name}=req.body??{};
    if ( typeof email !== "string" || typeof password !== "string" ) {
        return res.status(400).json({error:"Invalid input"});
    }
        const cleanEmail = email.trim().toLowerCase();
    if (password.length < 8) {
        return res.status(400).json({error:"Password must be at least 8 characters long"});
    }
        const passwordHash = await bcrypt.hash(password, 12);


    try{
        const result = await pool.query(
            "INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3) RETURNING id, email, name",
            [cleanEmail, passwordHash, name ?? null]
        );
        const user = result.rows[0];
        const token = generateToken(user);
        res.status(201).json({ user, token });
    } catch (error) {
       if(error.code === "23505") { // unique_violation
            return res.status(409).json({error:"Email already exists"});
       }
       throw error;
    }
});
router.post("/login", async (req, res) => {
    const {email,password}=req.body??{};
    if ( typeof email !== "string" || typeof password !== "string" ) {
        return res.status(400).json({error:"Invalid input"});
    }
    const cleanEmail = email.trim().toLowerCase();
    const userResult = await pool.query(
        "SELECT id, email, password_hash, name FROM users WHERE email = $1",
        [cleanEmail]
    );
    const user = userResult.rows[0];
    if(!user){
        return res.status(401).json({error:"Invalid email or password"});
    }
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if(!isPasswordValid){
        return res.status(401).json({error:"Invalid email or password"});
    }
    const token = generateToken(user);
    return res.status(200).json({ user: { id: user.id, email: user.email, name: user.name }, token });

});

router.get("/me", requireAuth, async (req, res) => { 
    const userInfoResult = await pool.query(
        "SELECT id, email, name FROM users WHERE id = $1",
        [req.userId]
    );
    const user = userInfoResult.rows[0];
    if(!user){
        return res.status(404).json({error:"User not found"});
    }
    res.status(200).json({ user });

});
export default router;
