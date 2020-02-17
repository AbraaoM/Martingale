# Martingale

  Trata-se de uma estratégia de aposta na qual quando há uma perda a próxima aposta é dobrada, para que uma vitória possa compensar as derrotas anteriores, aplicado a negociação em mercados financeiros o princípio de aumentar a posição após uma perda é mantido, mas o aumento da posição e o número de tentativas pode varia.
  O que a EA deve fazer
  O Expert Advisor (EA) deve possibilitar entradas inseridas pelo usuário ao adicionar a EA no gráfico e que podem ser mudadas durante a sua execução, são elas:
    - Sentido em que a entrada automática será feita: Deve ser possível escolher entre a favor ou contra a tendência indicada pelo último candle fechado;
    - O tamanho do lote a ser negociado, em número de contratos;
    - Take profit padrão, em pontos;
    - Stop loss padrão, em pontos;
    - Utilização ou não do trailing stop;
    - Aplicação ou não de breakeven;
    - Aplicação ou não do martingale;
    - Abertura automática da primeira ordem ou manual;
    - Fator que será aplicado ao martingale;
    - Número máximo de aplicações de martingale;
    - Perda máxima, num dia;
    - Ganho máximo, num dia;
    - Horário de início de funcionamento;
    - Horário de fim de funcionamento.

  As entradas automáticas devem ser feitas um segundo antes do fechamento do candle vigente, utilizando esse candle para definição de tendência a ser seguida ou não na entrada da posição. Deve ser também possível a entrada manual, que será feita pelo próprio sistema do Metatrader 5.
  Caso uma operação tenha resultado negativo, o martingale poderá ser ativado, caso nenhum dos limitantes (perda máxima, ganho máximo e número máximo de aplicações de martingale) tenha sido atingido, a ordem martingale deve ser executada faltando um segundo para o fechamento do candle.

# Inicialização

  É inicializado um array buffer para guardar os últimos preços, definindo-o como SetAsSeries, dessa forma a posição 0 do array sempre será correspondente à isenção mais recente.
  As entradas do tipo datetime são convertidas em MqlDateTime.

# A cada tick

  Se não existir nenhuma posição aberta no ativo em que a EA está aplicada e os limites de perdas e ganhos máximos definidos pelo usuário a EA pode abrir uma posição. É verificado se a operação anterior, se existir, resultou em um loss, caso o resultado seja verdadeiro é checado, se o limite de operações martingale, definida pelo usuário, ainda não tenha sido atingido é aberta uma operação martingale; se não houve operação anterior ou ela foi vitoriosa, as negociações automáticas estiverem ativas e estiver dentro do limite de horário de funcionamento uma ordem de operação normal é aberta. 

# Diferenciação entre ordem martingale e normal

  Os dois tipos de ordem são executadas pela mesma função, a diferença entre os dois se dá na entrada recebida pela função:
  ## Operação normal: 

    - Entradas: lote padrão e fator de multiplicação = 1.
  ## Operação martingale: 

    - Entradas: lote da operação anterior e fator de multiplicação inserida pelo usuário.

# Operation()

  Recebe como entradas o tamanho do lote que será negociado e o fator de multiplicação que deve ser aplicado a esse lote.
  Uma entrada é aberta um segundo antes do candle corrente fechar seguindo os parâmetros inseridos pelo usuário sobre a abertura contra ou a favor da tendência.
  O retorno da função é o valor do lote corrigido com o fator aplicado.

 # Trend()

  Calcula a tendência corrente baseada nos preços registrados nos três últimos ticks. 
