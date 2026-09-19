-- ============================================
-- BemEstar - Tabelas Supabase
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- Tabela de consultas
CREATE TABLE IF NOT EXISTS consultas (
  id TEXT PRIMARY KEY,
  paciente TEXT NOT NULL,
  data TEXT NOT NULL,
  horario_inicio_hour INTEGER NOT NULL,
  horario_inicio_minute INTEGER NOT NULL,
  horario_fim_hour INTEGER NOT NULL,
  horario_fim_minute INTEGER NOT NULL,
  modalidade TEXT NOT NULL DEFAULT 'Presencial',
  telefone TEXT DEFAULT '',
  queixas JSONB DEFAULT '[]',
  confirmada BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela de configurações (1 linha por usuário)
CREATE TABLE IF NOT EXISTS configuracoes (
  id TEXT PRIMARY KEY DEFAULT 'default',
  nome TEXT DEFAULT 'Dra. Psicanalista',
  email TEXT DEFAULT 'psicanalista@email.com',
  notificacoes BOOLEAN DEFAULT true,
  sons BOOLEAN DEFAULT true,
  vibracao BOOLEAN DEFAULT true,
  animacoes BOOLEAN DEFAULT true,
  tamanho_fonte DOUBLE PRECISION DEFAULT 1.0,
  lembrete_minutos INTEGER DEFAULT 30,
  idioma TEXT DEFAULT 'pt_BR',
  numero_psicologa TEXT DEFAULT '',
  mensagem_formulario TEXT DEFAULT 'Olá {nome}! Por favor, preencha o formulário de avaliação antes da nossa consulta:\n\n{link}\n\nAguardo seu retorno!',
  link_formulario TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS (Row Level Security) - acesso anônimo para este app
ALTER TABLE consultas ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

-- Policies: acesso total para usuários anônimos (app single-user)
CREATE POLICY "Acesso total consultas" ON consultas
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Acesso total configuracoes" ON configuracoes
  FOR ALL USING (true) WITH CHECK (true);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_consultas_data ON consultas(data);
CREATE INDEX IF NOT EXISTS idx_consultas_paciente ON consultas(paciente);
