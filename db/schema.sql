-- NoteMind database schema
-- Run once in the Neon SQL Editor, top to bottom.
-- Structure: users ──< notebooks ──< notes ──< note_chunks

-- 1. Extensions: enable pgvector so we can store and search embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Tables (parents before children, because children reference parents)

CREATE TABLE users(
    id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A notebook = a client, subject, case... whatever the user's work needs
CREATE TABLE notebooks(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notes(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notebook_id UUID NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    note_date DATE NOT NULL DEFAULT CURRENT_DATE,  -- when the session/lecture happened
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Each note is split into small pieces; each piece gets its own embedding.
-- These rows are derived from notes: on note edit, delete its chunks and rebuild them.
CREATE TABLE note_chunks(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notebook_id UUID NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768) NOT NULL,  -- must match gemini-embedding-001 with outputDimensionality = 768
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (note_id, chunk_index)
);

-- 3. Indexes (Postgres does NOT auto-index foreign keys)

CREATE INDEX notebooks_user_id_idx ON notebooks(user_id);
CREATE INDEX notes_notebook_id_idx ON notes(notebook_id);
CREATE INDEX note_chunks_user_id_idx ON note_chunks(user_id);
CREATE INDEX note_chunks_note_id_idx ON note_chunks(note_id);

-- HNSW = fast approximate nearest-neighbour search; cosine matches how we compare meaning
CREATE INDEX note_chunks_embedding_idx ON note_chunks USING hnsw (embedding vector_cosine_ops);
