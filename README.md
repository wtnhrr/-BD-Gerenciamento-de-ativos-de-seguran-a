## Gerenciamento de Ativos de Segurança

### Sobre


Este sistema foi planejado e criado com atenção para atender às necessidades atuais de guardar e acessar dados. Utilizamos estratégias como views e triggers para melhorar a organização e recuperação de informações. Ao longo deste relato, vamos explicar o Diagrama de Entidade-Relacionamento (DER), mostrando como o banco de dados foi estruturado e por que cada parte é importante. Além de descrever a complexidade do sistema, também vamos compartilhar os desafios que enfrentamos durante o desenvolvimento, proporcionando uma compreensão mais clara da administração de dados em ambientes acadêmicos e profissionais.

### Requisitos

- Apresentar um banco de dados composto por no mínimo 6  tabelas (entidades).
- Todas as regras de negócio devem ser implementadas através de funções e gatilhos (triggers).
- As consultas mais relevantes deverão ser implementadas através de visões (views simples ou materializadas). É obrigatório a implementação de pelomenos quatro views.

### Modelo de Entidade Relacional

[MDR]()

O Diagrama de Entidade-Relacionamento (DER) do nosso sistema de banco de dados reflete a estrutura para a gestão de ativos de segurança. A principal entidade central é "Ativo de Segurança", que é identificada de forma única por um número sequencial (idativosegurança). Essa entidade está relacionada a outras entidades essenciais, como "Status", "Licenças", "Bloqueio de Ativo", "Configurações", "Auditoria", e "Registro de Atividades".A entidade "Status" indica o estado atual do ativo (ativo, inativo, em manutenção) e data/hora atualizada, enquanto "Licenças" registra as informações pertinentes às licenças associadas a cada ativo. "Bloqueio de Ativo" gerencia situações em que o ativo precisa ser temporariamente desativado, incluindo motivos e períodos específicos.
As entidades "Configurações" e "Auditoria" capturam detalhes cruciais relacionados à configuração do ativo e auditorias realizadas. Por fim, "Registro de Atividades" mantém um histórico das ações realizadas, oferecendo uma visão abrangente das operações passadas.

### Views

No sistema, as views foram escolhidas como não materializadas. Essa decisão foi baseada na necessidade de garantir a atualização em tempo real das informações, evitando o potencial descompasso entre os dados armazenados nas views e na fonte original. A abordagem não materializada proporciona uma visão dinâmica e precisa do estado atual do sistema, alinhando-se com as demandas de agilidade e consistência na gestão de ativos de segurança.

As views desempenham um papel crucial ao proporcionar perspectivas específicas e otimizadas dos dados armazenados. A "detalhes_ativos" oferece uma visão consolidada dos ativos de segurança, incluindo nome, descrição, data de aquisição e estado atual. A "historico_bloqueios" fornece um histórico completo de bloqueios de ativos, incluindo o motivo e as datas relevantes. A "licencas_vencidas" identifica os ativos com licenças expiradas, apresentando detalhes sobre essas licenças. Por fim, a "config_criticas" destaca configurações críticas de cada ativo, contribuindo para a identificação rápida e eficiente de áreas sensíveis.

### Triggers

Diversos tipos de triggers foram implementados para garantir a integridade e a consistência dos dados. A "atualizar_configuracoes" é acionada quando há alterações nas configurações críticas de um ativo, notificando imediatamente a equipe de segurança e registrando a alteração no histórico de atividades. As triggers relacionadas à "Atualização de Status", "Desativação de Licenças Vencidas" e "Verificar Licenças Próximas do Vencimento" asseguram que o sistema responde automaticamente a eventos específicos, mantendo os dados atualizados e em conformidade.
