-- Add event-related fields to reports table
-- Phase C: Community events hub integration

ALTER TABLE reports 
ADD COLUMN IF NOT EXISTS event_type TEXT DEFAULT 'cleanup_event',
ADD COLUMN IF NOT EXISTS max_participants INTEGER,
ADD COLUMN IF NOT EXISTS venue TEXT,
ADD COLUMN IF NOT EXISTS participants TEXT[] DEFAULT '{}';

-- Create index on event_date for faster queries
CREATE INDEX IF NOT EXISTS idx_reports_event_date ON reports(event_date) WHERE event_date IS NOT NULL;

-- Create index on event_type for filtering
CREATE INDEX IF NOT EXISTS idx_reports_event_type ON reports(event_type) WHERE event_type IS NOT NULL;
