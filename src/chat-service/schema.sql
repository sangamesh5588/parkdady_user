-- Chat Sessions Table
CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    category TEXT,
    escalated_to_agent BOOLEAN DEFAULT FALSE,
    agent_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Chat Messages Table
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON public.chat_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_status ON public.chat_sessions(status);
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON public.chat_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON public.chat_messages(timestamp);

-- Enable Row Level Security (RLS)
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_sessions
-- Users can only read their own chat sessions
CREATE POLICY "Users can view own chat sessions"
ON public.chat_sessions
FOR SELECT
TO authenticated
USING (user_id = auth.uid()::TEXT);

-- Service role can access all (for backend operations)
CREATE POLICY "Service role full access to chat_sessions"
ON public.chat_sessions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- RLS Policies for chat_messages
-- Users can only read messages from their chat sessions
CREATE POLICY "Users can view own chat messages"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (
    chat_id IN (
        SELECT id FROM public.chat_sessions WHERE user_id = auth.uid()::TEXT
    )
);

-- Service role can access all (for backend operations)
CREATE POLICY "Service role full access to chat_messages"
ON public.chat_messages
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_chat_sessions_updated_at
BEFORE UPDATE ON public.chat_sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE public.chat_sessions IS 'Stores chat session data for the parking app support system';
COMMENT ON TABLE public.chat_messages IS 'Stores individual messages within chat sessions';
COMMENT ON COLUMN public.chat_sessions.status IS 'Session status: active, resolved, escalated';
COMMENT ON COLUMN public.chat_sessions.category IS 'Query category: booking, payment, vehicle, account, technical, general';
COMMENT ON COLUMN public.chat_messages.message_type IS 'Message type: user, bot, agent';
