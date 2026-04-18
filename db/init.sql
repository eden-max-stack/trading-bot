CREATE TABLE container_state (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    strategy_name VARCHAR(50) UNIQUE NOT NULL,
    initial_allocation DECIMAL(12, 2) NOT NULL,
    current_balance DECIMAL(12, 2) NOT NULL,
    minimum_threshold DECIMAL(12, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    -- prevent ledger from ever recording a negative balance 
    CONSTRAINT check_positive_balance CHECK (current_balance >= 0)
);

-- defininng strict order types
CREATE TYPE trade_action AS ENUM ('BUY', 'SELL', 'HOLD_REJECTED');

CREATE TABLE trade_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_id UUID REFERENCES container_state(id) ON DELETE CASCADE,
    asset_symbol VARCHAR(15) NOT NULL,
    action trade_action NOT NULL,
    quantity DECIMAL(10, 4) NOT NULL,
    execution_price DECIMAL(12, 2) NOT NULL,
    total_value DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * execution_price) STORED,
    
    -- to store data of diff types
    ai_reasoning JSONB NOT NULL, 
    
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE log_level AS ENUM ('INFO', 'WARNING', 'ERROR', 'CRITICAL');

CREATE TABLE system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    level log_level NOT NULL,
    service_module VARCHAR(50) NOT NULL, -- "news ingestion" | "broker api" | etc.
    event_message TEXT NOT NULL,
    api_response_dump JSONB, -- storing raw broker errors
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- idxing for fast time-srs queries
CREATE INDEX idx_trade_history_executed_at ON trade_history(executed_at);

-- idx for quickly pulling up recent errors
CREATE INDEX idx_system_logs_level_time ON system_logs(level, logged_at);