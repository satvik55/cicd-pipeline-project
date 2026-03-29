const request = require('supertest');
const app = require('../src/app');

// Reset the projects data before each test to avoid test pollution
// Each test should start with a clean, known state
beforeEach(() => {
  const routes = require('../src/routes');
  // Reset to one default project
  routes.projects.length = 0;
  routes.projects.push({
    id: '1',
    name: 'CI/CD Pipeline',
    description: 'Automated pipeline with Jenkins, Docker, Terraform',
    status: 'in-progress',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });
});

// ==========================================
// Health Check
// ==========================================
describe('GET /health', () => {
  it('should return healthy status', async () => {
    const res = await request(app).get('/health');

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('uptime');
  });
});

// ==========================================
// Root Route
// ==========================================
describe('GET /', () => {
  it('should return API info', async () => {
    const res = await request(app).get('/');

    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('AutoDeploy API');
    expect(res.body).toHaveProperty('endpoints');
  });
});

// ==========================================
// GET /api/projects
// ==========================================
describe('GET /api/projects', () => {
  it('should return all projects', async () => {
    const res = await request(app).get('/api/projects');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.count).toBe(1);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

// ==========================================
// GET /api/projects/:id
// ==========================================
describe('GET /api/projects/:id', () => {
  it('should return a single project', async () => {
    const res = await request(app).get('/api/projects/1');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('CI/CD Pipeline');
  });

  it('should return 404 for non-existent project', async () => {
    const res = await request(app).get('/api/projects/999');

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
  });
});

// ==========================================
// POST /api/projects
// ==========================================
describe('POST /api/projects', () => {
  it('should create a new project', async () => {
    const newProject = {
      name: 'Kubernetes Cluster',
      description: 'Multi-node K8s setup',
      status: 'planned'
    };

    const res = await request(app)
      .post('/api/projects')
      .send(newProject);

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Kubernetes Cluster');
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data).toHaveProperty('createdAt');
  });

  it('should return 400 if name is missing', async () => {
    const res = await request(app)
      .post('/api/projects')
      .send({ description: 'No name provided' });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('name');
  });

  it('should return 400 for invalid status', async () => {
    const res = await request(app)
      .post('/api/projects')
      .send({ name: 'Test', status: 'invalid-status' });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

// ==========================================
// PUT /api/projects/:id
// ==========================================
describe('PUT /api/projects/:id', () => {
  it('should update an existing project', async () => {
    const res = await request(app)
      .put('/api/projects/1')
      .send({ name: 'Updated Pipeline', status: 'completed' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Updated Pipeline');
    expect(res.body.data.status).toBe('completed');
  });

  it('should return 404 for non-existent project', async () => {
    const res = await request(app)
      .put('/api/projects/999')
      .send({ name: 'Ghost' });

    expect(res.statusCode).toBe(404);
  });

  it('should return 400 for invalid status', async () => {
    const res = await request(app)
      .put('/api/projects/1')
      .send({ status: 'banana' });

    expect(res.statusCode).toBe(400);
  });
});

// ==========================================
// DELETE /api/projects/:id
// ==========================================
describe('DELETE /api/projects/:id', () => {
  it('should delete a project', async () => {
    const res = await request(app).delete('/api/projects/1');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Project deleted successfully');
  });

  it('should return 404 for non-existent project', async () => {
    const res = await request(app).delete('/api/projects/999');

    expect(res.statusCode).toBe(404);
  });
});

// ==========================================
// 404 Handler
// ==========================================
describe('404 Handler', () => {
  it('should return 404 for unknown routes', async () => {
    const res = await request(app).get('/api/nonexistent');

    expect(res.statusCode).toBe(404);
    expect(res.body.error).toBe('Not Found');
  });
});

// ==========================================
// GET /info
// ==========================================
describe('GET /info', () => {
    it('should return system info', async () => {
        const res = await request(app).get('/info');

        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('app', 'autodeploy-api');
        expect(res.body).toHaveProperty('version');
        expect(res.body).toHaveProperty('node');
        expect(res.body).toHaveProperty('uptime');
    });
});
