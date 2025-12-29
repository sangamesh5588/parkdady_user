# Quick Start Guide - 5 Minutes to Working Chat

Get the chat system running locally in 5 minutes.

## Prerequisites Check

```bash
# Check Python version (need 3.11+)
python --version

# Check pip
pip --version

# Check git
git --version
```

## Step 1: Install Dependencies (2 minutes)

```bash
# Navigate to chat service directory
cd src/chat-service

# Create and activate virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Download NLTK data
python -m nltk.downloader punkt stopwords
```

## Step 2: Configure Environment (1 minute)

```bash
# Copy example env file
cp .env.example .env

# Edit .env file
# For quick local testing, you can skip Supabase initially
# The service will use in-memory storage
```

**Minimal `.env` for local testing:**
```env
PORT=8000
BASE_URL=http://localhost:8000
ENVIRONMENT=development
```

**For production (with Supabase):**
```env
PORT=8000
BASE_URL=http://localhost:8000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
ENVIRONMENT=production
```

## Step 3: Start the Service (30 seconds)

```bash
# Start the server
python app.py
```

You should see:
```
INFO:     Started server process
INFO:     Chat service initialized
INFO:     Database connected: True  (or False if no Supabase)
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## Step 4: Test It! (1 minute)

### Test 1: Health Check
```bash
# In a new terminal
curl http://localhost:8000/health
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

### Test 2: Send a Message
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "How do I book a parking space?"
  }'
```

Expected response:
```json
{
  "chat_id": "uuid-here",
  "response": "To book a parking space:\n1. Open the app...",
  "message_type": "bot",
  "category": "booking",
  "escalated": false
}
```

### Test 3: Get Chat History
```bash
# Use chat_id from previous response
curl http://localhost:8000/chat/YOUR_CHAT_ID/history
```

## Step 5: Test with Flutter App (30 seconds)

1. **Make sure chat service is running on localhost:8000**

2. **Run Flutter app:**
   ```bash
   cd ../..  # Back to project root
   flutter run
   ```

3. **In the app:**
   - Navigate to Profile/Help & Support
   - Tap "Live Chat"
   - Send message: "test"
   - Should see bot response!

## Common Issues & Quick Fixes

### Issue: "Module not found" error
**Fix:**
```bash
pip install -r requirements.txt
```

### Issue: "NLTK data not found"
**Fix:**
```bash
python -m nltk.downloader punkt stopwords
```

### Issue: "Address already in use"
**Fix:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Issue: Flutter can't connect
**Fixes:**
1. Check service is running: `curl http://localhost:8000/health`
2. Check Flutter is using localhost:8000 in config.dart
3. On Android emulator, use `10.0.2.2:8000` instead of `localhost:8000`
4. On iOS simulator, `localhost:8000` should work

### Issue: "Database connected: False"
**Expected** if you didn't configure Supabase yet.
- Service works with in-memory storage
- Data won't persist after restart
- Set up Supabase for production

## Next Steps

### For Production Deployment:
1. Read `PRODUCTION_SETUP.md`
2. Setup Supabase (required for production)
3. Run `schema.sql` in Supabase
4. Update `.env` with Supabase credentials
5. Deploy with Docker

### For Development:
1. **Supabase Setup (Recommended):**
   - Create free Supabase project
   - Run `schema.sql`
   - Update `.env`
   - Restart service

2. **Add Features:**
   - Configure Redis for caching
   - Add Twilio for voice calls
   - Customize responses in `chat_engine_simple.py`

## Quick Commands Reference

```bash
# Start service
python app.py

# Stop service
Ctrl+C

# View logs
tail -f chat_service.log

# Test health
curl http://localhost:8000/health

# Test chat
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"hello"}'

# List dependencies
pip list

# Update dependencies
pip install --upgrade -r requirements.txt
```

## Docker Quick Start (Alternative)

If you prefer Docker:

```bash
# Copy env file
cp .env.example .env

# Start with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f chat-service

# Stop
docker-compose down
```

## Testing Different Query Types

```bash
# Booking query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"How do I cancel my booking?"}'

# Payment query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"I need a refund"}'

# Technical query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"The app crashed"}'

# General query
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"What are your support hours?"}'
```

## Verify Everything Works

✅ Checklist:
- [ ] `python --version` shows 3.11+
- [ ] `pip install -r requirements.txt` completes successfully
- [ ] NLTK data downloaded
- [ ] Service starts without errors
- [ ] Health endpoint returns healthy
- [ ] Chat endpoint returns bot response
- [ ] Flutter app can connect and send messages

## Need Help?

1. **Check logs:** `tail -f chat_service.log`
2. **Read docs:** `README.md`, `PRODUCTION_SETUP.md`
3. **Review architecture:** `ARCHITECTURE.md`
4. **See changes:** `CHANGES_SUMMARY.md`

---

**Time to first message: ~5 minutes** ⏱️

**Status: Ready for development and testing** ✅

For production deployment, follow `PRODUCTION_SETUP.md`
