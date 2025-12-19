const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true
    },
    email: {
        type: String,
        trim: true,
        default: ''
    },
    password: {
        type: String,
        required: true
    }
}, {
    timestamps: true
});

adminSchema.methods.matchPassword = async function(enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

adminSchema.pre('save', async function(next) {
    if (!this.isModified('password')) {
        return next();
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    return next();
});

const Admin = mongoose.model('Admin', adminSchema);

// Create default admin if not exists
const createDefaultAdmin = async () => {
    try {
        const adminExists = await Admin.findOne({ username: process.env.ADMIN_USERNAME });
        if (!adminExists) {
            await Admin.create({
                username: process.env.ADMIN_USERNAME,
                email: process.env.ADMIN_EMAIL || '',
                password: process.env.ADMIN_PASSWORD
            });
            console.log('Default admin created');
        }
    } catch (error) {
        console.error('Error creating default admin:', error);
    }
};

createDefaultAdmin();

module.exports = Admin;