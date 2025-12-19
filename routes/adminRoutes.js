const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');
const Admin = require('../models/Admin');
const User = require('../models/User');
const Team = require('../models/Team');
const Task = require('../models/Task');
const { protect, adminOnly } = require('../middleware/auth');

// Admin Login (POST)
router.post('/login', asyncHandler(async (req, res) => {
    const { username, password } = req.body;

    const admin = await Admin.findOne({ username });
    
    if (admin && (await admin.matchPassword(password))) {
        res.json({
            _id: admin._id,
            username: admin.username,
            role: 'admin',
            token: jwt.sign({ id: admin._id, model: 'Admin' }, process.env.JWT_SECRET, {
                expiresIn: '30d'
            })
        });
    } else {
        res.status(401);
        throw new Error('Invalid username or password');
    }
}));

// Admin profile & overview
router.get('/profile', protect, adminOnly, asyncHandler(async (req, res) => {
    const admin = await Admin.findById(req.user._id).select('-password');
    if (!admin) {
        res.status(404);
        throw new Error('Admin not found');
    }

    const managerTeamTasks = await Task.find({ createdByRole: 'manager', assignedTeam: { $ne: null } })
        .populate('assignedTeam', 'name')
        .populate('assignedTo', 'name email role')
        .populate('createdBy', 'name email role')
        .sort({ createdAt: -1 });

    const hrList = await User.find({ role: 'hr' }).select('-password').sort({ createdAt: -1 });
    const managerList = await User.find({ role: 'manager' }).select('-password').sort({ createdAt: -1 });

    res.json({
        admin: { _id: admin._id, username: admin.username, email: admin.email || '' },
        hrs: hrList,
        managers: managerList,
        managerTeamTasks
    });
}));

// Update admin profile
router.put('/profile', protect, adminOnly, asyncHandler(async (req, res) => {
    const admin = await Admin.findById(req.user._id);
    if (!admin) {
        res.status(404);
        throw new Error('Admin not found');
    }

    const { username, email, password } = req.body;

    if (username && username !== admin.username) {
        const exists = await Admin.findOne({ username });
        if (exists && exists._id.toString() !== admin._id.toString()) {
            res.status(400);
            throw new Error('Username already taken');
        }
        admin.username = username;
    }

    if (email !== undefined) {
        admin.email = email;
    }

    if (password) {
        admin.password = password;
    }

    const updated = await admin.save();
    res.json({ _id: updated._id, username: updated.username, email: updated.email || '' });
}));

// Admin Login (GET) - simple browser form for testing/clickable links
router.get('/login', (req, res) => {
        // Allow browser autofill on admin login only
        res.send(`
            <html>
                <body style="font-family:Arial,Helvetica,sans-serif;">
                    <h2>Admin Login</h2>
                    <form method="post" action="/api/admin/login" autocomplete="off">
                        <!-- Hidden dummy inputs to discourage browser autofill -->
                        <input type="text" name="_fakeusernameremembered" style="display:none" autocomplete="off" />
                        <input type="password" name="_fakepasswordremembered" style="display:none" autocomplete="off" />
                        <label>Username: <input name="username" autocomplete="off" /></label><br/>
                        <label>Password: <input type="password" name="password" autocomplete="off" /></label><br/>
                        <button type="submit">Login</button>
                    </form>
                    <p>Use a REST client to call POST /api/admin/login with JSON for API testing.</p>
                </body>
            </html>
        `);
});

// Create new user
router.post('/users', protect, adminOnly, asyncHandler(async (req, res) => {
    const { name, email, password } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    const user = await User.create({
        name,
        email,
        password
    });

    if (user) {
        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email
        });
    } else {
        res.status(400);
        throw new Error('Invalid user data');
    }
}));

// Admin: Manage HR users (HRs are stored in User collection with role 'hr')
// Create HR
router.post('/hr', protect, adminOnly, asyncHandler(async (req, res) => {
    const { name, email, password } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    const user = await User.create({ name, email, password, role: 'hr' });
    if (user) {
        res.status(201).json({ _id: user._id, name: user.name, email: user.email, role: user.role });
    } else {
        res.status(400);
        throw new Error('Invalid HR data');
    }
}));

// List HRs
router.get('/hr', protect, adminOnly, asyncHandler(async (req, res) => {
    const hrs = await User.find({ role: 'hr' }).select('-password');
    res.json(hrs);
}));

// Update HR
router.put('/hr/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const hr = await User.findById(req.params.id);
    if (!hr || hr.role !== 'hr') {
        res.status(404);
        throw new Error('HR not found');
    }

    hr.name = req.body.name || hr.name;
    hr.email = req.body.email || hr.email;
    if (req.body.password) hr.password = req.body.password;

    const updated = await hr.save();
    res.json({ _id: updated._id, name: updated.name, email: updated.email });
}));

// Delete HR (and their related data) - admin only
router.delete('/hr/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const hr = await User.findById(req.params.id);
    if (!hr || hr.role !== 'hr') {
        res.status(404);
        throw new Error('HR not found');
    }
    await User.deleteOne({ _id: hr._id });
    // Note: depending on business rules you may want to reassign or delete managers created by this HR
    res.json({ message: 'HR removed' });
}));

// Get all users
router.get('/users', protect, adminOnly, asyncHandler(async (req, res) => {
    const users = await User.find({}).select('-password');
    res.json(users);
}));

// Get single user
router.get('/users/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
        res.status(404);
        throw new Error('User not found');
    }
    res.json(user);
}));

// Update user
router.put('/users/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);
    if (!user) {
        res.status(404);
        throw new Error('User not found');
    }

    user.name = req.body.name || user.name;
    user.email = req.body.email || user.email;
    if (req.body.password) user.password = req.body.password;

    const updated = await user.save();
    res.json({ _id: updated._id, name: updated.name, email: updated.email });
}));

// Delete user (and their tasks)
router.delete('/users/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);
    if (!user) {
        res.status(404);
        throw new Error('User not found');
    }

    // Remove tasks assigned to this user
    await Task.deleteMany({ assignedTo: user._id });
    await User.deleteOne({ _id: user._id });

    res.json({ message: 'User and associated tasks removed' });
}));

// Get all tasks
router.get('/tasks', protect, adminOnly, asyncHandler(async (req, res) => {
    const tasks = await Task.find({})
        .populate('assignedTo', 'name email role')
        .populate('assignedTeam', 'name')
        .populate('createdBy', 'username name email role')
        .sort({ createdAt: -1 });
    res.json(tasks);
}));

// Get all teams across the organization
router.get('/teams', protect, adminOnly, asyncHandler(async (req, res) => {
    const teams = await Team.find({})
        .populate('manager', 'name email role')
        .populate('members', 'name email role')
        .sort({ createdAt: -1 });
    res.json(teams);
}));

// Update task
router.put('/tasks/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const task = await Task.findById(req.params.id);

    if (!task) {
        res.status(404);
        throw new Error('Task not found');
    }

    const normalizeId = (value) => {
        if (value === undefined || value === null || value === '') {
            return null;
        }
        return value.toString();
    };

    const { title, description, deadline, status } = req.body;
    if (title) task.title = title;
    if (description) task.description = description;
    if (deadline) task.deadline = deadline;
    if (status) {
        const validStatuses = [
            'Client Requested',
            'Awaiting Manager Assignment',
            'Design In Progress',
            'Design Completed - Pending Manager Review',
            'Development In Progress',
            'Development Completed - Pending Manager Review',
            'Testing In Progress',
            'Testing Completed - Pending Manager Final Review',
            'Awaiting HR Review',
            'Awaiting Client Review',
            'Changes Requested',
            'Completed'
        ];
        if (!validStatuses.includes(status)) {
            res.status(400);
            throw new Error('Invalid status value');
        }
        task.status = status;
    }

    const hasAssignedTo = Object.prototype.hasOwnProperty.call(req.body, 'assignedTo');
    const hasAssignedTeam = Object.prototype.hasOwnProperty.call(req.body, 'assignedTeam');

    let nextAssignedTo = task.assignedTo ? task.assignedTo.toString() : null;
    let nextAssignedTeam = task.assignedTeam ? task.assignedTeam.toString() : null;

    let assignedUserDoc = null;
    if (hasAssignedTo) {
        const normalizedUserId = normalizeId(req.body.assignedTo);
        if (normalizedUserId) {
            assignedUserDoc = await User.findById(normalizedUserId);
            if (!assignedUserDoc) {
                res.status(404);
                throw new Error('Assigned user not found');
            }
            nextAssignedTo = assignedUserDoc._id.toString();
        } else {
            nextAssignedTo = null;
        }
    }

    let assignedTeamDoc = null;
    if (hasAssignedTeam) {
        const normalizedTeamId = normalizeId(req.body.assignedTeam);
        if (normalizedTeamId) {
            assignedTeamDoc = await Team.findById(normalizedTeamId);
            if (!assignedTeamDoc) {
                res.status(404);
                throw new Error('Assigned team not found');
            }
            nextAssignedTeam = assignedTeamDoc._id.toString();
        } else {
            nextAssignedTeam = null;
        }
    }

    if ((hasAssignedTo || hasAssignedTeam) && !nextAssignedTo && !nextAssignedTeam) {
        res.status(400);
        throw new Error('Task must remain assigned to at least one user or team');
    }

    if (nextAssignedTo && nextAssignedTeam) {
        const team = assignedTeamDoc || await Team.findById(nextAssignedTeam).select('members');
        const isMember = team && team.members.some(member => member.toString() === nextAssignedTo);
        if (!isMember) {
            res.status(400);
            throw new Error('Assigned user is not part of the selected team');
        }
    }

    task.assignedTo = nextAssignedTo ? nextAssignedTo : null;
    task.assignedTeam = nextAssignedTeam ? nextAssignedTeam : null;

    const saved = await task.save();
    await saved.populate('assignedTo', 'name email role');
    await saved.populate('assignedTeam', 'name');
    await saved.populate('createdBy', 'username name email role');
    res.json(saved);
}));

// Delete task
router.delete('/tasks/:id', protect, adminOnly, asyncHandler(async (req, res) => {
    const task = await Task.findById(req.params.id);
    
    if (!task) {
        res.status(404);
        throw new Error('Task not found');
    }

    await Task.deleteOne({ _id: task._id });
    res.json({ message: 'Task removed' });
}));

module.exports = router;