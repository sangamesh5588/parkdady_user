# Production Setup Guide - Chat Service

Complete guide to deploy the chat service to production with all features working.

## 🎯 Quick Start Checklist

- [ ] Supabase project created and configured
- [ ] Database schema executed (`schema.sql`)
- [ ] Service role key obtained
- [ ] Environment variables configured
- [ ] Chat service deployed and running
- [ ] Flutter app configured with production URL
- [ ] Health endpoint returns healthy status
- [ ] Test message sent successfully

## 📋 Step-by-Step Production Setup

### Step 1: Supabase Setup (CRITICAL)

1. **Create Supabase Project:**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project (or use existing)
   - Wait for project provisioning (~2 minutes)

2. **Execute Database Schema:**
   ```bash
   # Go to Supabase Dashboard > SQL Editor
   # Copy entire contents of schema.sql
   # Paste and click "RUN"
   ```

   This creates:
   - `chat_sessions` table
   - `chat_messages` table
   - Indexes for performance
   - RLS policies for security

3. **Get Service Role Key:**
   ```bash
   # Supabase Dashboard > Project Settings > API
   # Copy "service_role" key (NOT anon key!)
   # This bypasses RLS for backend operations
   ```

4. **Verify Tables Created:**
   ```bash
   # Supabase Dashboard > Table Editor
   # Should see: chat_sessions, chat_messages
   ```

### Step 2: Backend Deployment

#### Option A: Local/VPS Deployment

1. **Install Python 3.11+:**
   ```bash
   python --version  # Should be 3.11 or higher
   ```

2. **Clone and Setup:**
   ```bash
   cd parking/src/chat-service
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   python -m nltk.downloader punkt stopwords
   ```

3. **Configure Environment:**
   ```bash
   cp .env.example .env
   nano .env  # or use any text editor
   ```

   **Minimum required configuration:**
   ```env
   # REQUIRED
   SUPABASE_URL=https://eivjgwxyijhfmnyrcbcb.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

   # Server settings
   PORT=8000
   BASE_URL=https://your-domain.com  # or http://localhost:8000 for dev
   ENVIRONMENT=production
   ```

4. **Test Locally First:**
   ```bash
   python app.py
   # Should see: "Chat service initialized"
   # Should see: "Database connected: True"
   ```

5. **Test Health Endpoint:**
   ```bash
   curl http://localhost:8000/health
   # Expected: {"status":"healthy", "services":{"database":"connected"}}
   ```

6. **Test Chat:**
   ```bash
   curl -X POST http://localhost:8000/chat \
     -H "Content-Type: application/json" \
     -d '{"user_id":"test","message":"How do I book parking?"}'
   # Should return bot response
   ```

#### Option B: Docker Deployment (Recommended)

1. **Configure Environment:**
   ```bash
   cp .env.example .env
   nano .env  # Add Supabase credentials
   ```

2. **Build and Run:**
   ```bash
   docker-compose up -d
   ```

3. **Check Logs:**
   ```bash
   docker-compose logs -f chat-service
   # Should see: "Database connected: True"
   ```

4. **Verify Running:**
   ```bash
   curl http://localhost:8000/health
   ```

### Step 3: Production Server Setup

#### Using DigitalOcean/AWS/Linode

1. **Create Droplet/Instance:**
   - Ubuntu 22.04 LTS
   - Minimum: 1GB RAM, 1 CPU
   - Recommended: 2GB RAM, 2 CPUs

2. **Install Docker:**
   ```bash
   ssh root@your-server-ip

   # Update system
   sudo apt update && sudo apt upgrade -y

   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Install Docker Compose
   sudo apt install docker-compose -y
   ```

3. **Deploy Application:**
   ```bash
   # Clone your repository
   git clone https://github.com/your-repo/parking.git
   cd parking/src/chat-service

   # Configure environment
   cp .env.example .env
   nano .env  # Add production credentials

   # Start service
   docker-compose up -d

   # Check logs
   docker-compose logs -f
   ```

4. **Setup Nginx Reverse Proxy:**
   ```bash
   sudo apt install nginx -y

   # Create nginx config
   sudo nano /etc/nginx/sites-available/chat-service
   ```

   **Nginx configuration:**
   ```nginx
   server {
       listen 80;
       server_name chat.yourdomain.com;

       location / {
           proxy_pass http://localhost:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

   ```bash
   # Enable site
   sudo ln -s /etc/nginx/sites-available/chat-service /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

5. **Setup SSL Certificate:**
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   sudo certbot --nginx -d chat.yourdomain.com
   # Follow prompts
   ```

6. **Configure Firewall:**
   ```bash
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw enable
   ```

### Step 4: Flutter App Configuration

1. **Update Production URL:**
   ```dart
   // lib/core/config.dart
   static const String productionChatUrl = 'https://chat.yourdomain.com';
   ```

2. **Update CORS in Backend:**
   ```python
   # src/chat-service/app.py (line 39)
   allow_origins=[
       "https://yourdomain.com",
       "https://www.yourdomain.com",
       "https://app.yourdomain.com"
   ]
   ```

3. **Build Production App:**
   ```bash
   # Android
   flutter build apk --release --dart-define=CHAT_SERVICE_URL=https://chat.yourdomain.com

   # iOS
   flutter build ios --release --dart-define=CHAT_SERVICE_URL=https://chat.yourdomain.com
   ```

### Step 5: Verification & Testing

1. **Health Check:**
   ```bash
   curl https://chat.yourdomain.com/health
   ```

   Expected response:
   ```json
   {
     "status": "healthy",
     "timestamp": "2025-12-16T...",
     "services": {
       "chat_engine": "operational",
       "agent_service": "operational",
       "database": "connected",
       "business_hours": true
     }
   }
   ```

2. **Test Chat API:**
   ```bash
   curl -X POST https://chat.yourdomain.com/chat \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "production_test",
       "message": "How do I book a parking space?"
     }'
   ```

3. **Test from Flutter App:**
   - Open app
   - Go to Help & Support
   - Tap "Live Chat"
   - Send message: "test"
   - Should receive bot response

4. **Test Database Persistence:**
   ```bash
   # Send a message
   curl -X POST https://chat.yourdomain.com/chat \
     -H "Content-Type: application/json" \
     -d '{"user_id":"test","message":"hello","chat_id":"test123"}'

   # Retrieve history
   curl https://chat.yourdomain.com/chat/test123/history
   # Should show message history
   ```

## 🔍 Monitoring

### Check Logs

**Docker:**
```bash
docker-compose logs -f chat-service
```

**Direct Python:**
```bash
tail -f chat_service.log
```

### Monitor Health

Setup monitoring service (UptimeRobot, Pingdom, etc.):
- URL: `https://chat.yourdomain.com/health`
- Interval: 5 minutes
- Alert on non-200 status

### Database Monitoring

Check Supabase Dashboard:
- Database > Tables > chat_sessions (should see new sessions)
- Database > Tables > chat_messages (should see messages)

## 🐛 Troubleshooting

### Issue: "Database connected: False"

**Cause:** Supabase credentials incorrect or missing

**Solution:**
```bash
# Check .env file
cat .env | grep SUPABASE

# Verify values:
# - SUPABASE_URL should start with https://
# - SUPABASE_SERVICE_ROLE_KEY should be long JWT token
# - Use service_role key, NOT anon key

# Test Supabase connection
curl -X GET "https://eivjgwxyijhfmnyrcbcb.supabase.co/rest/v1/chat_sessions" \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### Issue: Flutter app shows "Network error"

**Causes:**
1. Chat service not running
2. Wrong URL in config.dart
3. CORS not configured
4. Firewall blocking

**Solutions:**
```bash
# 1. Verify service is running
curl https://chat.yourdomain.com/health

# 2. Check Flutter config
# lib/core/config.dart should have correct URL

# 3. Check CORS in app.py
# allow_origins should include your app domain

# 4. Check firewall
sudo ufw status
# Ensure 80 and 443 are allowed
```

### Issue: Messages not persisting

**Cause:** Database tables not created or RLS blocking

**Solution:**
```bash
# Re-run schema.sql in Supabase SQL Editor
# Verify tables exist in Table Editor
# Check logs for database errors:
docker-compose logs | grep -i "database\|supabase"
```

### Issue: High memory usage

**Solution:**
```bash
# Limit Docker memory
docker-compose down
nano docker-compose.yml

# Add under chat-service:
    mem_limit: 512m
    mem_reservation: 256m

docker-compose up -d
```

## 📊 Performance Optimization

### Database Indexes

Already included in `schema.sql`:
- `idx_chat_sessions_user_id`
- `idx_chat_messages_chat_id`
- `idx_chat_messages_timestamp`

### Caching with Redis (Optional)

1. **Enable Redis:**
   ```bash
   # Docker Compose already includes Redis
   # Just add to .env:
   REDIS_HOST=redis
   REDIS_PORT=6379
   ```

2. **Restart service:**
   ```bash
   docker-compose restart chat-service
   ```

### Database Cleanup

**Schedule cleanup of old chats (>30 days):**

```python
# Create cleanup script
from database import DatabaseService
import asyncio

async def cleanup():
    db = DatabaseService()
    deleted = await db.delete_old_sessions(days=30)
    print(f"Deleted {deleted} old sessions")

asyncio.run(cleanup())
```

```bash
# Add to crontab
0 2 * * * cd /app && python cleanup.py
```

## 🔒 Security Checklist

- [ ] HTTPS enabled (SSL certificate)
- [ ] Supabase RLS policies active
- [ ] Service role key in backend only (never in Flutter)
- [ ] CORS configured for production domains only
- [ ] `.env` file in `.gitignore`
- [ ] Firewall configured (only 80, 443, 22)
- [ ] Rate limiting configured (nginx/Cloudflare)
- [ ] Database backups enabled (Supabase automatic)
- [ ] Logs don't contain sensitive data

## 📈 Scaling

### Vertical Scaling
- Increase droplet/instance size
- 2GB RAM → 4GB RAM
- Add more CPU cores

### Horizontal Scaling
- Deploy multiple instances
- Use load balancer (nginx, HAProxy)
- Share Redis for session management
- All instances use same Supabase database

### Load Balancer Config (nginx)
```nginx
upstream chat_backend {
    server 10.0.0.1:8000;
    server 10.0.0.2:8000;
    server 10.0.0.3:8000;
}

server {
    listen 80;
    location / {
        proxy_pass http://chat_backend;
    }
}
```

## ✅ Final Checklist

Before going live:
- [ ] All tests passing
- [ ] Health endpoint returns healthy
- [ ] Database connected and persisting
- [ ] SSL certificate installed
- [ ] Monitoring configured
- [ ] Logs being collected
- [ ] Backups enabled
- [ ] Documentation updated
- [ ] Team trained on system

## 📞 Support

If you encounter issues:
1. Check this guide first
2. Review application logs
3. Test each component individually
4. Check Supabase dashboard for errors

---

**You're all set!** Your chat service is now production-ready. 🎉
