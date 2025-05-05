const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

mongoose.connect(
  'mongodb+srv://faizan786:hasilpur62@flutterapp.fmmfdtq.mongodb.net/pharmacydb?retryWrites=true&w=majority&appName=FlutterApp'
).then(() => console.log('MongoDB Connected'))
 .catch(err => console.error(err));

// Define a simple schema
const MedicineSchema = new mongoose.Schema({
  name: String,
  price: Number,
  quantity: Number,
});

const Medicine = mongoose.model('Medicine', MedicineSchema);

// GET all medicines
app.get('/api/medicines', async (req, res) => {
  const medicines = await Medicine.find();
  res.json(medicines);
});

// POST add a medicine
app.post('/api/medicines', async (req, res) => {
  const newMed = new Medicine(req.body);
  await newMed.save();
  res.json(newMed);
});

// PUT update a medicine
app.put('/api/medicines/:id', async (req, res) => {
  const updatedMed = await Medicine.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(updatedMed);
});

// DELETE a medicine
app.delete('/api/medicines/:id', async (req, res) => {
  await Medicine.findByIdAndDelete(req.params.id);
  res.json({ message: 'Deleted successfully' });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
