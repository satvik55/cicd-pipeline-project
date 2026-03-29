# Pipeline Reliability Test Log — Day 12

| Run | Trigger | Change | Result | Notes |
|-----|---------|--------|--------|-------|
| 1 | Webhook (push) | Jenkinsfile update | PASS | Baseline run, all 8 stages green |
| 2 | Webhook (push) | New /info endpoint + test | PASS | 15 tests passing, new endpoint deployed |
| 3a | Webhook (push) | Intentional break | FAIL (expected) | Tests caught broken code — CI works correctly |
| 3b | Webhook (push) | Fix applied | PASS | Recovery confirmed, app redeployed |
| 4 | Webhook (push) | README update only | PASS | Full pipeline runs even for docs changes |
| 5 | Manual (Build Now) | None | PASS | Manual trigger works independently |

## Verification Commands
```bash
# Health check
curl http://3.111.228.220/health

# Info endpoint (new)
curl http://3.111.228.220/info

# All projects
curl http://3.111.228.220/api/projects

# Running container
ssh -i ~/.ssh/devops-project-key.pem ubuntu@3.111.228.220 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

## Conclusion

Pipeline is stable and reliable across multiple execution types. Security gate (Trivy) blocks vulnerable images. Test failures prevent broken code from deploying. Image tags are traceable to specific builds and commits.
