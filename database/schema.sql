CREATE TABLE companies (id UUID PRIMARY KEY, name VARCHAR(200) NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE users (id UUID PRIMARY KEY, company_id UUID NOT NULL REFERENCES companies(id), name VARCHAR(200) NOT NULL, email VARCHAR(320) NOT NULL, password_hash TEXT NOT NULL, role VARCHAR(40) NOT NULL DEFAULT 'VIEWER', created_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(company_id,email));
CREATE TABLE customers (id UUID PRIMARY KEY, company_id UUID NOT NULL REFERENCES companies(id), name VARCHAR(200) NOT NULL, phone VARCHAR(50), email VARCHAR(320), status VARCHAR(40) NOT NULL DEFAULT 'LEAD', assigned_to UUID REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX idx_customers_company_created ON customers(company_id, created_at);
CREATE TABLE opportunities (id UUID PRIMARY KEY, company_id UUID NOT NULL REFERENCES companies(id), customer_id UUID NOT NULL REFERENCES customers(id), title VARCHAR(250) NOT NULL, value NUMERIC(18,2) NOT NULL DEFAULT 0, currency VARCHAR(10) NOT NULL DEFAULT 'YER', stage VARCHAR(60) NOT NULL, probability NUMERIC(5,2) NOT NULL DEFAULT 0, assigned_to UUID REFERENCES users(id), expected_close_date DATE, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX idx_opportunities_company_stage ON opportunities(company_id, stage);
CREATE TABLE tasks (id UUID PRIMARY KEY, company_id UUID NOT NULL REFERENCES companies(id), customer_id UUID REFERENCES customers(id), opportunity_id UUID REFERENCES opportunities(id), assigned_to UUID REFERENCES users(id), title VARCHAR(250) NOT NULL, priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM', status VARCHAR(30) NOT NULL DEFAULT 'TODO', due_date TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE activities (id UUID PRIMARY KEY, company_id UUID NOT NULL REFERENCES companies(id), user_id UUID REFERENCES users(id), customer_id UUID REFERENCES customers(id), opportunity_id UUID REFERENCES opportunities(id), activity_type VARCHAR(30) NOT NULL, description TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE role_permissions (
  id UUID PRIMARY KEY,
  role VARCHAR(40) NOT NULL,
  permission VARCHAR(120) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(role, permission)
);
CREATE INDEX idx_role_permissions_role ON role_permissions(role);
