const express = require('express');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// In-memory data store (resets on restart — fine for this demo)
let projects = [
  {
    id: '1',
    name: 'CI/CD Pipeline',
    description: 'Automated pipeline with Jenkins, Docker, Terraform',
    status: 'in-progress',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

// --- GET /api/projects --- List all projects
router.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    count: projects.length,
    data: projects
  });
});

// --- GET /api/projects/:id --- Get one project by ID
router.get('/:id', (req, res) => {
  const project = projects.find(p => p.id === req.params.id);

  if (!project) {
    return res.status(404).json({
      success: false,
      error: `Project with id '${req.params.id}' not found`
    });
  }

  res.status(200).json({
    success: true,
    data: project
  });
});

// --- POST /api/projects --- Create a new project
router.post('/', (req, res) => {
  const { name, description, status } = req.body;

  // Validation: name is required
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed: "name" is required and must be a non-empty string'
    });
  }

  // Validate status if provided
  const validStatuses = ['planned', 'in-progress', 'completed'];
  if (status && !validStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      error: `Validation failed: "status" must be one of: ${validStatuses.join(', ')}`
    });
  }

  const newProject = {
    id: uuidv4(),
    name: name.trim(),
    description: description ? description.trim() : '',
    status: status || 'planned',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  projects.push(newProject);

  res.status(201).json({
    success: true,
    data: newProject
  });
});

// --- PUT /api/projects/:id --- Update a project
router.put('/:id', (req, res) => {
  const index = projects.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: `Project with id '${req.params.id}' not found`
    });
  }

  const { name, description, status } = req.body;

  // Validate status if provided
  const validStatuses = ['planned', 'in-progress', 'completed'];
  if (status && !validStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      error: `Validation failed: "status" must be one of: ${validStatuses.join(', ')}`
    });
  }

  // Update only provided fields
  const updated = {
    ...projects[index],
    name: name ? name.trim() : projects[index].name,
    description: description !== undefined ? description.trim() : projects[index].description,
    status: status || projects[index].status,
    updatedAt: new Date().toISOString()
  };

  projects[index] = updated;

  res.status(200).json({
    success: true,
    data: updated
  });
});

// --- DELETE /api/projects/:id --- Delete a project
router.delete('/:id', (req, res) => {
  const index = projects.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: `Project with id '${req.params.id}' not found`
    });
  }

  const deleted = projects.splice(index, 1)[0];

  res.status(200).json({
    success: true,
    message: 'Project deleted successfully',
    data: deleted
  });
});

// Export router AND projects array (tests need access to reset data)
module.exports = router;
module.exports.projects = projects;

// Pipeline deploy test marker
