-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  user_type TEXT NOT NULL CHECK (user_type IN ('customer', 'owner')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create owner_details table with user_id as foreign key
CREATE TABLE owner_details (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  headquarters TEXT,
  total_properties INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create contact_messages table
CREATE TABLE contact_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  subject TEXT,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for users table
CREATE POLICY "Allow public insert to users" ON users
  FOR INSERT TO public
  WITH CHECK (true);

CREATE POLICY "Allow users to view own data" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Allow users to update own data" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- Create RLS policies for owner_details table
CREATE POLICY "Allow public insert to owner_details" ON owner_details
  FOR INSERT TO public
  WITH CHECK (true);

CREATE POLICY "Allow owners to view own details" ON owner_details
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Allow owners to update own details" ON owner_details
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Create RLS policies for contact_messages table
CREATE POLICY "Allow public insert to contact_messages" ON contact_messages
  FOR INSERT TO public
  WITH CHECK (true);

-- Create policy for admins to view all contact messages (optional)
CREATE POLICY "Allow admins to view all contact messages" ON contact_messages
  FOR SELECT TO authenticated
  USING (true);

-- First, drop existing policies
DROP POLICY IF EXISTS "Allow public insert to users" ON users;
DROP POLICY IF EXISTS "Allow users to view own data" ON users;
DROP POLICY IF EXISTS "Allow users to update own data" ON users;

-- Create more permissive policies for users table
CREATE POLICY "Enable insert for all" ON users
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Enable select for users" ON users
  FOR SELECT
  USING (true);

CREATE POLICY "Enable update for users" ON users
  FOR UPDATE
  USING (auth.uid() = id);

-- Also update owner_details policies
DROP POLICY IF EXISTS "Allow public insert to owner_details" ON owner_details;
DROP POLICY IF EXISTS "Allow owners to view own details" ON owner_details;
DROP POLICY IF EXISTS "Allow owners to update own details" ON owner_details;

CREATE POLICY "Enable insert for all" ON owner_details
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Enable select for owner_details" ON owner_details
  FOR SELECT
  USING (true);

CREATE POLICY "Enable update for owner_details" ON owner_details
  FOR UPDATE
  USING (auth.uid() = user_id);