-- Migration: Add cleanup event columns to reports table
-- Date: 2026-08-08
-- Description: Add support for structured cleanup events with RSVP functionality

-- Add nullable columns for cleanup events
ALTER TABLE reports 
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS event_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS participants_count INTEGER DEFAULT 0;

-- Add comment to describe the new columns
COMMENT ON COLUMN reports.title IS 'Event title for cleanup_event type reports';
COMMENT ON COLUMN reports.description IS 'Event description for cleanup_event type reports';
COMMENT ON COLUMN reports.event_date IS 'Scheduled date/time for cleanup_event type reports';
COMMENT ON COLUMN reports.participants_count IS 'Number of participants who have RSVPed to cleanup_event';

-- Create function to increment participants count
CREATE OR REPLACE FUNCTION increment_participants(event_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE reports
    SET participants_count = participants_count + 1
    WHERE id = event_id::UUID;
END;
$$ LANGUAGE plpgsql;
