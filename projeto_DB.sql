CREATE TABLE ativoSeguranca (
  idativoSeguranca SERIAL  NOT NULL ,
  nome VARCHAR(50)    ,
  descricao VARCHAR(50)    ,
  dataAquisicao DATE      ,
PRIMARY KEY(idativoSeguranca));

CREATE TABLE registroAtividades (
  idregistroAtividades SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  tipoAtividade VARCHAR(100)    ,
  detalhesAtividade VARCHAR(100),
  dataHoraAtividade TIMESTAMP    ,
PRIMARY KEY(idregistroAtividades)  ,
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca));

CREATE INDEX registroAtividades_FKIndex1 ON registroAtividades (idativoSeguranca);

CREATE INDEX IFK_possui ON registroAtividades (idativoSeguranca);

CREATE TABLE Status (
  idstatus SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  estado VARCHAR(20) check (estado in ('ativo', 'inativo', 'manutencao'))    ,
  dataAtualizacao DATE      ,
PRIMARY KEY(idstatus)  ,
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca));

CREATE INDEX Status_FKIndex1 ON Status (idativoSeguranca);

CREATE INDEX IFK_tem ON Status (idativoSeguranca);

CREATE TABLE licencas (
  idlicencas SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  numeroLicenca VARCHAR(20)    ,
  tipoLicenca VARCHAR(30) check (tipolicenca in ('anual', 'mensal', 'perpetua'))    ,
  dataVencimento DATE    ,
  provedor VARCHAR(20)      ,
PRIMARY KEY(idlicencas),
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca));

CREATE INDEX IFK_possui_licencas ON licencas (idativoSeguranca);

CREATE TABLE bloqueioAtivo (
  idbloqueioAtivo SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  motivo VARCHAR(100)    ,
  dataInicio TIMESTAMP    ,
  dataFim TIMESTAMP      ,
PRIMARY KEY(idbloqueioAtivo)  ,
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca));

CREATE INDEX bloqueioAtivo_FKIndex1 ON bloqueioAtivo (idativoSeguranca);
CREATE INDEX IFK_pode_haver ON bloqueioAtivo (idativoSeguranca);

CREATE TABLE configuracoes (
  idconfiguracoes SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  confEspecifica VARCHAR(200)      ,
PRIMARY KEY(idconfiguracoes)  ,
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca));

CREATE INDEX configuracoes_FKIndex1 ON configuracoes (idativoSeguranca);

CREATE INDEX IFK_retem ON configuracoes (idativoSeguranca);

CREATE TABLE auditoria (
  idauditoria SERIAL  NOT NULL ,
  idativoSeguranca INTEGER   NOT NULL ,
  idstatus INTEGER   NOT NULL ,
  dataHora TIMESTAMP    ,
  resultadoAuditoria VARCHAR(50)    ,
  responsavelAuditoria VARCHAR(50)      ,
PRIMARY KEY(idauditoria)    ,
  FOREIGN KEY(idativoSeguranca)
    REFERENCES ativoSeguranca(idativoSeguranca),
  FOREIGN KEY(idstatus)
    REFERENCES Status(idstatus));

CREATE INDEX auditoria_FKIndex1 ON auditoria (idstatus);
CREATE INDEX auditoria_FKIndex2 ON auditoria (idativoSeguranca);

CREATE INDEX IFK_contem ON auditoria (idativoSeguranca);
CREATE INDEX IFK_contem_status ON auditoria (idstatus);

--------------------------------------------------------------------------------------

/* Atualização de Status do ativo  */

CREATE FUNCTION atualizar_status()
RETURNS TRIGGER AS $atualizar_trigger$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado THEN
    UPDATE Status
    SET
      estado = NEW.estado,
      dataAtualizacao = CURRENT_DATE
    WHERE idativoSeguranca = NEW.idativoSeguranca;
  END IF;
  RETURN NEW;
END;
$atualizar_trigger$ LANGUAGE plpgsql;


CREATE TRIGGER atualizar_trigger
AFTER INSERT OR UPDATE ON status
FOR EACH ROW
EXECUTE FUNCTION atualizar_status();



/* Desativação de Licenças Vencidas  */

CREATE FUNCTION desativar_licenca_vencida()
RETURNS TRIGGER AS $desativar_licenca_trigger$
BEGIN
    IF NEW.dataVencimento < CURRENT_DATE THEN
        DELETE FROM Licencas
        WHERE idlicencas = NEW.idlicencas;
		
        INSERT INTO RegistroAtividades (idativoseguranca, tipoAtividade, detalhesAtividade, dataHoraAtividade)
        VALUES (NEW.idlicencas, 'Desativação de Licença', 'Licença vencida desativada automaticamente.', NOW());
    END IF;
    RETURN NEW;
END;
$desativar_licenca_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER desativar_licenca_trigger
AFTER INSERT OR UPDATE ON Licencas
FOR EACH ROW
EXECUTE FUNCTION desativar_licenca_vencida();


/* Verificar Licenças Próximas do Vencimento */

CREATE FUNCTION notificar_licenca_proxima_vencimento()
RETURNS TRIGGER AS $notificar_vencimento_trigger$
DECLARE
    dias_antes INTEGER := 7;
    data_limite DATE;
BEGIN
    data_limite := current_date + dias_antes;
    IF NEW.datavencimento <= data_limite THEN
        RAISE NOTICE 'Licença próxima do vencimento para o Ativo de Segurança % em % dias.', NEW.idativoseguranca, dias_antes;
    END IF;
    RETURN NEW;
END;
$notificar_vencimento_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER notificar_vencimento_trigger
AFTER UPDATE OF datavencimento ON Licencas
FOR EACH ROW
EXECUTE FUNCTION notificar_licenca_proxima_vencimento();

/* Auditoria Mal-Sucedida  */

CREATE OR REPLACE FUNCTION RegistrarAuditoria()
RETURNS TRIGGER AS $registrar_auditoria_trigger$
BEGIN
    IF NEW.resultadoAuditoria = 'mal-sucedido' THEN
        INSERT INTO RegistroAtividades (idAtivoseguranca, tipoAtividade, detalhesatividade, datahoraatividade)
        VALUES (NEW.idativoseguranca, 'Auditoria', 'Auditoria mal-sucedida registrada', CURRENT_TIMESTAMP);

        RAISE NOTICE 'Auditoria mal-sucedida no ativo % - Equipe de Segurança notificada.', NEW.idativoseguranca;

        INSERT INTO bloqueioativo (idAtivoseguranca, Motivo, DataInicio, DataFim)
        VALUES (NEW.idAtivoseguranca, 'Auditoria mal-sucedida - Bloqueio Temporário', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day');
	ELSE
        INSERT INTO RegistroAtividades (idAtivoseguranca, tipoAtividade, detalhesatividade, datahoraatividade)
        VALUES (NEW.idAtivoseguranca, 'Auditoria', 'Auditoria bem-sucedida registrada', CURRENT_TIMESTAMP);

        RAISE NOTICE 'Auditoria bem-sucedida no ativo %.', NEW.idAtivoseguranca;
    END IF;

    RETURN NEW;
END;
$registrar_auditoria_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER registrar_auditoria_trigger
AFTER INSERT OR UPDATE ON Auditoria
FOR EACH ROW
EXECUTE FUNCTION RegistrarAuditoria();



---------------------------------------------------------------------

/* AtivoSeguranca */
INSERT INTO AtivoSeguranca (nome, descricao, dataAquisicao) VALUES 
  ('Firewall XYZ', 'Firewall de última geração', '2022-01-01'),
  ('Antivírus ABC', 'Proteção contra malware', '2022-02-15'),
  ('Sistema de Detecção de Intrusões', 'Monitoramento avançado', '2022-03-10');

/* RegistroAtividades */
INSERT INTO RegistroAtividades (idativoSeguranca, tipoAtividade, detalhesAtividade ,dataHoraAtividade) VALUES
  (1, 'Atualização de Configuração', 'Atualização do firewall xyz por detalhe x' , '2022-04-01 10:30:00'),
  (2, 'Auditoria de Segurança', 'Auditoria nos firewall ABC da empresa' , '2022-04-02 15:45:00'),
  (3, 'Alteração de Status', 'Verificação de status do sistema' , '2022-04-03 08:20:00');

/* Statuss */
INSERT INTO Status (idativoSeguranca, estado, dataAtualizacao) VALUES
  (1, 'ativo', '2023-11-29'),
  (2, 'manutencao', '2022-04-02'),
  (3, 'inativo', '2023-04-03');

/* Licencas */
INSERT INTO Licencas (idativoSeguranca, numeroLicenca, tipoLicenca, dataVencimento, provedor) VALUES
  (1, 'LIC123', 'anual', '2023-01-01', 'Fornecedor1'),
  (2, 'LIC456', 'mensal', '2022-05-01', 'Fornecedor2'),
  (3, 'LIC789', 'perpetua', NULL, 'Fornecedor3');

/* Configuracoes */
INSERT INTO Configuracoes (idativoSeguranca, confEspecifica) VALUES
  (1, 'Configuração Específica para Firewall XYZ'),
  (2, 'Configuração Personalizada para Antivírus ABC'),
  (3, 'Configuração Padrão para Sistema de Detecção de Intrusões');

/* Auditoria */
INSERT INTO Auditoria (idativoSeguranca, idstatus, dataHora, resultadoAuditoria, responsavelAuditoria) VALUES
  (1, 1, '2022-04-02 14:00:00', 'Sucesso', 'Auditor1'),
  (2, 3, '2022-04-03 11:30:00', 'Falha', 'Auditor2'),
  (3, 2, '2022-04-04 09:45:00', 'Sucesso', 'Auditor3');