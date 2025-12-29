# Supabase MCP Setup Guide

This guide will help you configure the Supabase MCP server to query your database directly from Claude Code.

## Step 1: Get Your Service Role Key

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `eivjgwxyijhfmnyrcbcb`
3. Click on **Settings** (gear icon in sidebar)
4. Navigate to **API** section
5. Under **Project API keys**, find the **service_role** key (secret)
6. Copy this key - **IMPORTANT: Keep this secure! Never commit to Git!**

## Step 2: Get Your Database Password

### Option A: From Connection String
1. In Supabase Dashboard, go to **Settings** → **Database**
2. Scroll to **Connection string** section
3. Select **URI** tab
4. Click **Use connection pooling**
5. Copy the connection string - it looks like:
   ```
   postgresql://postgres.eivjgwxyijhfmnyrcbcb:[YOUR-PASSWORD]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres
   ```
6. Extract the password from between `:` and `@`

### Option B: Reset Password (if you don't have it)
1. In Supabase Dashboard, go to **Settings** → **Database**
2. Click **Reset database password**
3. Copy the new password immediately
4. Save it securely

## Step 3: Update MCP Configuration

1. Open `.claude/mcp.json`
2. Replace `YOUR_SERVICE_ROLE_KEY_HERE` with your service role key from Step 1
3. Replace `YOUR_DB_PASSWORD` with your database password from Step 2

Your final configuration should look like:
```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres"
      ],
      "env": {
        "SUPABASE_URL": "https://eivjgwxyijhfmnyrcbcb.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "eyJhbGc...(your actual service role key)",
        "POSTGRES_CONNECTION_STRING": "postgresql://postgres.eivjgwxyijhfmnyrcbcb:your-actual-password@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"
      }
    }
  }
}
```

## Step 4: Add to .env (Optional but Recommended)

For better security, add these to your `.env` file:
```env
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
SUPABASE_DB_PASSWORD=your_database_password_here
```

Then update `.claude/mcp.json` to reference them (if your MCP client supports env vars).

## Step 5: Update .gitignore

Make sure `.env` and `.claude/mcp.json` are in your `.gitignore`:
```
.env
.env.*
.claude/mcp.json
```

## Step 6: Restart Claude Code

After updating the configuration:
1. Save all files
2. Restart your Claude Code session
3. The Supabase MCP server will be available

## What You Can Do After Setup

Once configured, you can:
- Query your `parking_spots` table directly
- View all database tables and schemas
- Run SQL queries to debug issues
- Insert, update, delete records
- Check real-time data state

## Testing the Connection

After setup, try asking Claude:
- "Show me all tables in the database"
- "Query the parking_spots table"
- "What's the schema of parking_spots?"

## Troubleshooting

### Connection fails
- Verify your service role key is correct
- Verify your database password is correct
- Check if connection pooling is enabled in Supabase

### npx command not found
- Install Node.js: https://nodejs.org/
- Restart your terminal/Claude Code

### Permission denied
- Make sure you're using the **service_role** key, not the anon key
- Check your Supabase project's RLS policies

## Security Notes

⚠️ **IMPORTANT:**
- Never commit `.claude/mcp.json` with real credentials to Git
- The service role key bypasses Row Level Security (RLS)
- Only use this in development, not in production apps
- Keep your credentials secure

---

Need help? Check the [Supabase Documentation](https://supabase.com/docs) or [MCP Documentation](https://modelcontextprotocol.io/).
