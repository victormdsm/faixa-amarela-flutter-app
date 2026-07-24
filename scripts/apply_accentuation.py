#!/usr/bin/env python3
"""Aplica acentuação em strings visíveis de arquivos Dart (exceto gerados)."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / 'lib'

# Mapeamento ordenado: palavras mais longas primeiro para evitar conflitos.
REPLACEMENTS = [
    # Expressões compostas primeiro
    (r'\bnao lida\b', 'não lida'),
    (r'\bNao lida\b', 'Não lida'),
    (r'\bcaixa de selecao\b', 'caixa de seleção'),
    (r'\bCaixa de selecao\b', 'Caixa de seleção'),
    (r'\bnao utilizado\b', 'não utilizado'),
    (r'\bNao utilizado\b', 'Não utilizado'),
    (r'\bnao utilizada\b', 'não utilizada'),
    (r'\bNao utilizada\b', 'Não utilizada'),
    (r'\bnao recomendado\b', 'não recomendado'),
    (r'\bNao recomendado\b', 'Não recomendado'),
    (r'\bnao recomendada\b', 'não recomendada'),
    (r'\bNao recomendada\b', 'Não recomendada'),
    (r'\bem andamento\b', 'em andamento'),  # já correto
    (r'\bA caminho\b', 'A caminho'),  # já correto
    (r'\bponto de partida\b', 'ponto de partida'),
    (r'\bPonto de partida\b', 'Ponto de partida'),
    (r'\bponto de chegada\b', 'ponto de chegada'),
    (r'\bPonto de chegada\b', 'Ponto de chegada'),
    (r'\bponto de encontro\b', 'ponto de encontro'),
    (r'\bPonto de encontro\b', 'Ponto de encontro'),
    (r'\bponto de referencia\b', 'ponto de referência'),
    (r'\bPonto de referencia\b', 'Ponto de referência'),
    (r'\bendereco de origem\b', 'endereço de origem'),
    (r'\bEndereco de origem\b', 'Endereço de origem'),
    (r'\bendereco de destino\b', 'endereço de destino'),
    (r'\bEndereco de destino\b', 'Endereço de destino'),
    (r'\bendereco de entrega\b', 'endereço de entrega'),
    (r'\bEndereco de entrega\b', 'Endereço de entrega'),
    (r'\bendereco de cobranca\b', 'endereço de cobrança'),
    (r'\bEndereco de cobranca\b', 'Endereço de cobrança'),
    (r'\bendereco comercial\b', 'endereço comercial'),
    (r'\bEndereco comercial\b', 'Endereço comercial'),
    (r'\bendereco residencial\b', 'endereço residencial'),
    (r'\bEndereco residencial\b', 'Endereço residencial'),
    (r'\bestado civil\b', 'estado civil'),
    (r'\bEstado civil\b', 'Estado civil'),
    (r'\breconhecimento facial\b', 'reconhecimento facial'),
    (r'\bReconhecimento facial\b', 'Reconhecimento facial'),
    (r'\blogin social\b', 'login social'),
    (r'\bLogin social\b', 'Login social'),
    (r'\bcaso de uso\b', 'caso de uso'),
    (r'\bCaso de uso\b', 'Caso de uso'),
    (r'\bbanco de dados\b', 'banco de dados'),
    (r'\bBanco de dados\b', 'Banco de dados'),
    (r'\bbase de dados\b', 'base de dados'),
    (r'\bBase de dados\b', 'Base de dados'),
    (r'\bsala de espera\b', 'sala de espera'),
    (r'\bSala de espera\b', 'Sala de espera'),
    (r'\bcentro cirurgico\b', 'centro cirúrgico'),
    (r'\bCentro cirurgico\b', 'Centro cirúrgico'),
    (r'\bpronto socorro\b', 'pronto-socorro'),
    (r'\bPronto socorro\b', 'Pronto-socorro'),
    (r'\bdois fatores\b', 'dois fatores'),
    (r'\bDois fatores\b', 'Dois fatores'),
    (r'\bsingle sign-on\b', 'Single Sign-On'),
    (r'\bSingle sign-on\b', 'Single Sign-On'),
    (r'\btela inicial\b', 'tela inicial'),
    (r'\bTela inicial\b', 'Tela inicial'),
    (r'\btela principal\b', 'tela principal'),
    (r'\bTela principal\b', 'Tela principal'),
    (r'\btela de login\b', 'tela de login'),
    (r'\bTela de login\b', 'Tela de login'),
    (r'\btela de cadastro\b', 'tela de cadastro'),
    (r'\bTela de cadastro\b', 'Tela de cadastro'),
    (r'\btela de perfil\b', 'tela de perfil'),
    (r'\bTela de perfil\b', 'Tela de perfil'),
    (r'\btela de configuracoes\b', 'tela de configurações'),
    (r'\bTela de configuracoes\b', 'Tela de configurações'),
    (r'\bmenu principal\b', 'menu principal'),
    (r'\bMenu principal\b', 'Menu principal'),
    (r'\bmenu lateral\b', 'menu lateral'),
    (r'\bMenu lateral\b', 'Menu lateral'),
    (r'\bbarra de progresso\b', 'barra de progresso'),
    (r'\bBarra de progresso\b', 'Barra de progresso'),
    (r'\bdata e hora\b', 'data e hora'),
    (r'\bData e hora\b', 'Data e hora'),
    (r'\bcamera\b', 'câmera'),
    (r'\bCamera\b', 'Câmera'),

    # Palavras simples (maiúsculas e minúsculas separadas)
    (r'\bconfiguracoes\b', 'configurações'),
    (r'\bConfiguracoes\b', 'Configurações'),
    (r'\bconfiguracao\b', 'configuração'),
    (r'\bConfiguracao\b', 'Configuração'),
    (r'\bveiculo\b', 'veículo'),
    (r'\bVeiculo\b', 'Veículo'),
    (r'\bcrianca\b', 'criança'),
    (r'\bCrianca\b', 'Criança'),
    (r'\bresponsavel\b', 'responsável'),
    (r'\bResponsavel\b', 'Responsável'),
    (r'\bendereco\b', 'endereço'),
    (r'\bEndereco\b', 'Endereço'),
    (r'\bcodigo\b', 'código'),
    (r'\bCodigo\b', 'Código'),
    (r'\bmatriculas\b', 'matrículas'),
    (r'\bMatriculas\b', 'Matrículas'),
    (r'\bmatricula\b', 'matrícula'),
    (r'\bMatricula\b', 'Matrícula'),
    (r'\bperiodo\b', 'período'),
    (r'\bPeriodo\b', 'Período'),
    (r'\bnao\b', 'não'),
    (r'\bNao\b', 'Não'),
    (r'\bVoce\b', 'Você'),
    (r'\bvoce\b', 'você'),
    (r'\barea\b', 'área'),
    (r'\bArea\b', 'Área'),
    (r'\bsolicitacao\b', 'solicitação'),
    (r'\bSolicitacao\b', 'Solicitação'),
    (r'\bsolicitacoes\b', 'solicitações'),
    (r'\bSolicitacoes\b', 'Solicitações'),
    (r'\baprovacao\b', 'aprovação'),
    (r'\bAprovacao\b', 'Aprovação'),
    (r'\binformacoes\b', 'informações'),
    (r'\bInformacoes\b', 'Informações'),
    (r'\bedicao\b', 'edição'),
    (r'\bEdicao\b', 'Edição'),
    (r'\balteracoes\b', 'alterações'),
    (r'\bAlteracoes\b', 'Alterações'),
    (r'\bpermissao\b', 'permissão'),
    (r'\bPermissao\b', 'Permissão'),
    (r'\bpermissoes\b', 'permissões'),
    (r'\bPermissoes\b', 'Permissões'),
    (r'\bconexao\b', 'conexão'),
    (r'\bConexao\b', 'Conexão'),
    (r'\brequisicao\b', 'requisição'),
    (r'\bRequisicao\b', 'Requisição'),
    (r'\bcomunicacao\b', 'comunicação'),
    (r'\bComunicacao\b', 'Comunicação'),
    (r'\bindisponivel\b', 'indisponível'),
    (r'\bIndisponivel\b', 'Indisponível'),
    (r'\bnotificacao\b', 'notificação'),
    (r'\bNotificacao\b', 'Notificação'),
    (r'\bnotificacoes\b', 'notificações'),
    (r'\bNotificacoes\b', 'Notificações'),
    (r'\bcomecar\b', 'começar'),
    (r'\bComecar\b', 'Começar'),
    (r'\bproximo\b', 'próximo'),
    (r'\bProximo\b', 'Próximo'),
    (r'\bultima\b', 'última'),
    (r'\bUltima\b', 'Última'),
    (r'\bultimo\b', 'último'),
    (r'\bUltimo\b', 'Último'),
    (r'\brevisao\b', 'revisão'),
    (r'\bRevisao\b', 'Revisão'),
    (r'\bpublicas\b', 'públicas'),
    (r'\bPublicas\b', 'Públicas'),
    (r'\bpublico\b', 'público'),
    (r'\bPublico\b', 'Público'),
    (r'\bpublica\b', 'pública'),
    (r'\bPublica\b', 'Pública'),
    (r'\bdisponiveis\b', 'disponíveis'),
    (r'\bDisponiveis\b', 'Disponíveis'),
    (r'\bcombinacao\b', 'combinação'),
    (r'\bCombinacao\b', 'Combinação'),
    (r'\bdigitos\b', 'dígitos'),
    (r'\bDigitos\b', 'Dígitos'),
    (r'\bvalido\b', 'válido'),
    (r'\bValido\b', 'Válido'),
    (r'\bvalida\b', 'válida'),
    (r'\bValida\b', 'Válida'),
    (r'\bconfirmacao\b', 'confirmação'),
    (r'\bConfirmacao\b', 'Confirmação'),
    (r'\baplicacao\b', 'aplicação'),
    (r'\bAplicacao\b', 'Aplicação'),
    (r'\blocalizacao\b', 'localização'),
    (r'\bLocalizacao\b', 'Localização'),
    (r'\bgenero\b', 'gênero'),
    (r'\bGenero\b', 'Gênero'),
    (r'\braca\b', 'raça'),
    (r'\bRaca\b', 'Raça'),
    (r'\bprofissao\b', 'profissão'),
    (r'\bProfissao\b', 'Profissão'),
    (r'\bocupacao\b', 'ocupação'),
    (r'\bOcupacao\b', 'Ocupação'),
    (r'\bfuncao\b', 'função'),
    (r'\bFuncao\b', 'Função'),
    (r'\borganizacao\b', 'organização'),
    (r'\bOrganizacao\b', 'Organização'),
    (r'\binstituicao\b', 'instituição'),
    (r'\bInstituicao\b', 'Instituição'),
    (r'\bescritorio\b', 'escritório'),
    (r'\bEscritorio\b', 'Escritório'),
    (r'\bguiche\b', 'guichê'),
    (r'\bGuiche\b', 'Guichê'),
    (r'\breclamacao\b', 'reclamação'),
    (r'\bReclamacao\b', 'Reclamação'),
    (r'\bsugestao\b', 'sugestão'),
    (r'\bSugestao\b', 'Sugestão'),
    (r'\bdenuncia\b', 'denúncia'),
    (r'\bDenuncia\b', 'Denúncia'),
    (r'\binternacao\b', 'internação'),
    (r'\bInternacao\b', 'Internação'),
    (r'\bemergencia\b', 'emergência'),
    (r'\bEmergencia\b', 'Emergência'),
    (r'\brecepcao\b', 'recepção'),
    (r'\bRecepcao\b', 'Recepção'),
    (r'\bseguranca\b', 'segurança'),
    (r'\bSeguranca\b', 'Segurança'),
    (r'\blider\b', 'líder'),
    (r'\bLider\b', 'Líder'),
    (r'\bsocio\b', 'sócio'),
    (r'\bSocio\b', 'Sócio'),
    (r'\bsocia\b', 'sócia'),
    (r'\bSocia\b', 'Sócia'),
    (r'\brenovacao\b', 'renovação'),
    (r'\bRenovacao\b', 'Renovação'),
    (r'\bvigencia\b', 'vigência'),
    (r'\bVigencia\b', 'Vigência'),
    (r'\bcondicao\b', 'condição'),
    (r'\bCondicao\b', 'Condição'),
    (r'\bcondicoes\b', 'condições'),
    (r'\bCondicoes\b', 'Condições'),
    (r'\binstrucao\b', 'instrução'),
    (r'\bInstrucao\b', 'Instrução'),
    (r'\bduvida\b', 'dúvida'),
    (r'\bDuvida\b', 'Dúvida'),
    (r'\bnavegacao\b', 'navegação'),
    (r'\bNavegacao\b', 'Navegação'),
    (r'\breferencia\b', 'referência'),
    (r'\bReferencia\b', 'Referência'),
    (r'\bmae\b', 'mãe'),
    (r'\bMae\b', 'Mãe'),
    (r'\birmao\b', 'irmão'),
    (r'\bIrmao\b', 'Irmão'),
    (r'\birma\b', 'irmã'),
    (r'\bIrma\b', 'Irmã'),
    (r'\bconjuge\b', 'cônjuge'),
    (r'\bConjuge\b', 'Cônjuge'),
    (r'\bonibus\b', 'ônibus'),
    (r'\bOnibus\b', 'Ônibus'),
    (r'\bcaminhao\b', 'caminhão'),
    (r'\bCaminhao\b', 'Caminhão'),
    (r'\bpeca\b', 'peça'),
    (r'\bPeca\b', 'Peça'),
    (r'\bacessorio\b', 'acessório'),
    (r'\bAcessorio\b', 'Acessório'),
    (r'\bmidia\b', 'mídia'),
    (r'\bMidia\b', 'Mídia'),
    (r'\bvideo\b', 'vídeo'),
    (r'\bVideo\b', 'Vídeo'),
    (r'\baudio\b', 'áudio'),
    (r'\bAudio\b', 'Áudio'),
    (r'\bsecao\b', 'seção'),
    (r'\bSecao\b', 'Seção'),
    (r'\bsessao\b', 'sessão'),
    (r'\bSessao\b', 'Sessão'),
    (r'\brotulo\b', 'rótulo'),
    (r'\bRotulo\b', 'Rótulo'),
    (r'\bnumero\b', 'número'),
    (r'\bNumero\b', 'Número'),
    (r'\bselecao\b', 'seleção'),
    (r'\bSelecao\b', 'Seleção'),
    (r'\bbotao\b', 'botão'),
    (r'\bBotao\b', 'Botão'),
    (r'\bbotoes\b', 'botões'),
    (r'\bBotoes\b', 'Botões'),
    (r'\bicone\b', 'ícone'),
    (r'\bIcone\b', 'Ícone'),
    (r'\bsimbolo\b', 'símbolo'),
    (r'\bSimbolo\b', 'Símbolo'),
    (r'\bmanutencao\b', 'manutenção'),
    (r'\bManutencao\b', 'Manutenção'),
    (r'\bsolucao\b', 'solução'),
    (r'\bSolucao\b', 'Solução'),
    (r'\bcorrecao\b', 'correção'),
    (r'\bCorrecao\b', 'Correção'),
    (r'\botimizacao\b', 'otimização'),
    (r'\bOtimizacao\b', 'Otimização'),
    (r'\blentidao\b', 'lentidão'),
    (r'\bLentidao\b', 'Lentidão'),
    (r'\bautenticacao\b', 'autenticação'),
    (r'\bAutenticacao\b', 'Autenticação'),
    (r'\bautorizacao\b', 'autorização'),
    (r'\bAutorizacao\b', 'Autorização'),
    (r'\bvalidacao\b', 'validação'),
    (r'\bValidacao\b', 'Validação'),
    (r'\bverificacao\b', 'verificação'),
    (r'\bVerificacao\b', 'Verificação'),
    (r'\brestauracao\b', 'restauração'),
    (r'\bRestauracao\b', 'Restauração'),
    (r'\bsincronizacao\b', 'sincronização'),
    (r'\bSincronizacao\b', 'Sincronização'),
    (r'\breplicacao\b', 'replicação'),
    (r'\bReplicacao\b', 'Replicação'),
    (r'\bmemoria\b', 'memória'),
    (r'\bMemoria\b', 'Memória'),
    (r'\bdiretorio\b', 'diretório'),
    (r'\bDiretorio\b', 'Diretório'),
    (r'\bindice\b', 'índice'),
    (r'\bIndice\b', 'Índice'),
    (r'\btransacao\b', 'transação'),
    (r'\bTransacao\b', 'Transação'),
    (r'\bmigracao\b', 'migração'),
    (r'\bMigracao\b', 'Migração'),
    (r'\brepositorio\b', 'repositório'),
    (r'\bRepositorio\b', 'Repositório'),
    (r'\bservico\b', 'serviço'),
    (r'\bServico\b', 'Serviço'),
    (r'\bpagina\b', 'página'),
    (r'\bPagina\b', 'Página'),
    (r'\bmodulo\b', 'módulo'),
    (r'\bModulo\b', 'Módulo'),
    (r'\bdependencia\b', 'dependência'),
    (r'\bDependencia\b', 'Dependência'),
    (r'\btelefone\b', 'telefone'),
    (r'\bTelefone\b', 'Telefone'),
    (r'\btambem\b', 'também'),
    (r'\bTambem\b', 'Também'),
    (r'\bja\b', 'já'),
    (r'\bJa\b', 'Já'),
    (r'\bate\b', 'até'),
    (r'\bAte\b', 'Até'),
    (r'\bai\b', 'aí'),
    (r'\bAi\b', 'Aí'),
    (r'\bla\b', 'lá'),
    (r'\bLa\b', 'Lá'),
    (r'\bentao\b', 'então'),
    (r'\bEntao\b', 'Então'),
    (r'\bsenao\b', 'senão'),
    (r'\bSenao\b', 'Senão'),
    (r'\batras\b', 'atrás'),
    (r'\bAtras\b', 'Atrás'),
    (r'\bunico\b', 'único'),
    (r'\bUnico\b', 'Único'),
    (r'\bunica\b', 'única'),
    (r'\bUnica\b', 'Única'),
    (r'\bviuvo\b', 'viúvo'),
    (r'\bViuvo\b', 'Viúvo'),
    (r'\bviuva\b', 'viúva'),
    (r'\bViuva\b', 'Viúva'),
    (r'\borientacao\b', 'orientação'),
    (r'\bOrientacao\b', 'Orientação'),
    (r'\bmanifestacao\b', 'manifestação'),
    (r'\bManifestacao\b', 'Manifestação'),
    (r'\bemail\b', 'e-mail'),
    (r'\bEmail\b', 'E-mail'),
    (r'\bpossivel\b', 'possível'),
    (r'\bPossivel\b', 'Possível'),
    (r'\bprovavel\b', 'provável'),
    (r'\bProvavel\b', 'Provável'),
    (r'\bmedio\b', 'médio'),
    (r'\bMedio\b', 'Médio'),
    (r'\bserio\b', 'sério'),
    (r'\bSerio\b', 'Sério'),
    (r'\beconomico\b', 'econômico'),
    (r'\bEconomico\b', 'Econômico'),
    (r'\beconomica\b', 'econômica'),
    (r'\bEconomica\b', 'Econômica'),
    (r'\bpolitico\b', 'político'),
    (r'\bPolitico\b', 'Político'),
    (r'\bpolitica\b', 'política'),
    (r'\bPolitica\b', 'Política'),
    (r'\bjuridico\b', 'jurídico'),
    (r'\bJuridico\b', 'Jurídico'),
    (r'\bjuridica\b', 'jurídica'),
    (r'\bJuridica\b', 'Jurídica'),
    (r'\bmedico\b', 'médico'),
    (r'\bMedico\b', 'Médico'),
    (r'\bmedica\b', 'médica'),
    (r'\bMedica\b', 'Médica'),
    (r'\bhistorico\b', 'histórico'),
    (r'\bHistorico\b', 'Histórico'),
    (r'\bhistorica\b', 'histórica'),
    (r'\bHistorica\b', 'Histórica'),
    (r'\bcritico\b', 'crítico'),
    (r'\bCritico\b', 'Crítico'),
    (r'\bcritica\b', 'crítica'),
    (r'\bCritica\b', 'Crítica'),
    (r'\blogico\b', 'lógico'),
    (r'\bLogico\b', 'Lógico'),
    (r'\blogica\b', 'lógica'),
    (r'\bLogica\b', 'Lógica'),
    (r'\bfisico\b', 'físico'),
    (r'\bFisico\b', 'Físico'),
    (r'\bfisica\b', 'física'),
    (r'\bFisica\b', 'Física'),
    (r'\bmusica\b', 'música'),
    (r'\bMusica\b', 'Música'),
    (r'\btatica\b', 'tática'),
    (r'\bTatica\b', 'Tática'),
    (r'\bpratica\b', 'prática'),
    (r'\bPratica\b', 'Prática'),
    (r'\bteorico\b', 'teórico'),
    (r'\bTeorico\b', 'Teórico'),
    (r'\bteorica\b', 'teórica'),
    (r'\bTeorica\b', 'Teórica'),
    (r'\bbasico\b', 'básico'),
    (r'\bBasico\b', 'Básico'),
    (r'\bbasica\b', 'básica'),
    (r'\bBasica\b', 'Básica'),
    (r'\bclassico\b', 'clássico'),
    (r'\bClassico\b', 'Clássico'),
    (r'\bclassica\b', 'clássica'),
    (r'\bClassica\b', 'Clássica'),
    (r'\bestetico\b', 'estético'),
    (r'\bEstetico\b', 'Estético'),
    (r'\bestetica\b', 'estética'),
    (r'\bEstetica\b', 'Estética'),
    (r'\batomico\b', 'atômico'),
    (r'\bAtomico\b', 'Atômico'),
    (r'\batomica\b', 'atômica'),
    (r'\bAtomica\b', 'Atômica'),
    (r'\batomo\b', 'átomo'),
    (r'\bAtomo\b', 'Átomo'),
    (r'\belectronico\b', 'eletrônico'),
    (r'\bElectronico\b', 'Eletrônico'),
    (r'\belectronica\b', 'eletrônica'),
    (r'\bElectronica\b', 'Eletrônica'),
    (r'\bhidrico\b', 'hídrico'),
    (r'\bHidrico\b', 'Hídrico'),
    (r'\boxigenio\b', 'oxigênio'),
    (r'\bOxigenio\b', 'Oxigênio'),
    (r'\bnitrogenio\b', 'nitrogênio'),
    (r'\bNitrogenio\b', 'Nitrogênio'),
    (r'\bsodio\b', 'sódio'),
    (r'\bSodio\b', 'Sódio'),
    (r'\bcalcio\b', 'cálcio'),
    (r'\bCalcio\b', 'Cálcio'),
    (r'\bpais\b', 'país'),
    (r'\bPais\b', 'País'),
    (r'\brapido\b', 'rápido'),
    (r'\bRapido\b', 'Rápido'),
    (r'\brapida\b', 'rápida'),
    (r'\bRapida\b', 'Rápida'),
    (r'\bfacil\b', 'fácil'),
    (r'\bFacil\b', 'Fácil'),
    (r'\bdificil\b', 'difícil'),
    (r'\bDificil\b', 'Difícil'),
    (r'\butil\b', 'útil'),
    (r'\bUtil\b', 'Útil'),
    (r'\batencao\b', 'atenção'),
    (r'\bAtencao\b', 'Atenção'),
    (r'\bnao\b', 'não'),
    (r'\bNao\b', 'Não'),
]

# Regex que captura strings literais Dart (aspas simples/dupas, incluindo multilinha e raw).
# Ignora comentários de linha para não alterar comentários.
STRING_RE = re.compile(
    r"""
    (?:
        (?P<raw>r)
        (?P<quote>['"])
        (?P<raw_content>.*?)
        (?P=quote)
      |
        (?P<quote2>['"])
        (?P<content>.*?)
        (?P=quote2)
    )
    """,
    re.VERBOSE | re.DOTALL,
)


def is_inside_comment(line_before: str) -> bool:
    """Verifica se a string está em uma linha que já é comentário."""
    stripped = line_before.lstrip()
    return stripped.startswith('//') or stripped.startswith('*')


def should_skip_string(text: str, line_before: str) -> bool:
    """Pula strings que claramente são identificadores técnicos."""
    if is_inside_comment(line_before):
        return True
    # Rotas
    if text.startswith('/'):
        return True
    # Chaves JSON / identificadores snake_case usados em código
    # Se a string for usada como valor de uma chave de mapa, é arriscado.
    # Heurística: se a linha anterior contém "key:" ou "JsonKey" ou similar
    if re.search(r'\bkey\s*:', line_before, re.IGNORECASE):
        return True
    return False


def apply_replacements(text: str) -> str:
    for pattern, replacement in REPLACEMENTS:
        text = re.sub(pattern, replacement, text)
    return text


def process_file(path: Path) -> tuple[int, list[str]]:
    original = path.read_text(encoding='utf-8')
    lines = original.splitlines(keepends=True)
    changes: list[str] = []
    total = 0

    def replace_match(m: re.Match) -> str:
        nonlocal total
        raw = m.group('raw')
        quote = m.group('quote') or m.group('quote2')
        content = m.group('raw_content') if raw else m.group('content')
        start = m.start()
        line_start = original.rfind('\n', 0, start) + 1
        line_before = original[line_start:start]

        if should_skip_string(content, line_before):
            return m.group(0)

        new_content = apply_replacements(content)
        if new_content != content:
            total += 1
            line_no = original[:start].count('\n') + 1
            changes.append(f"  line {line_no}: {content[:60]!r} -> {new_content[:60]!r}")
            prefix = 'r' if raw else ''
            return f"{prefix}{quote}{new_content}{quote}"
        return m.group(0)

    new_text = STRING_RE.sub(replace_match, original)
    if new_text != original:
        path.write_text(new_text, encoding='utf-8')
    return total, changes


def main() -> int:
    files = sorted(
        p
        for p in ROOT.rglob('*.dart')
        if not p.name.endswith('.g.dart') and not p.name.endswith('.freezed.dart')
    )
    changed_files = 0
    total_changes = 0
    for path in files:
        count, changes = process_file(path)
        if count:
            changed_files += 1
            total_changes += count
            print(f"{path.relative_to(ROOT.parent)} ({count} changes)")
            for ch in changes[:10]:
                print(ch)
            if len(changes) > 10:
                print(f"  ... and {len(changes) - 10} more")
    print(f"\nTotal: {changed_files} files, {total_changes} string changes")
    return 0


if __name__ == '__main__':
    sys.exit(main())
