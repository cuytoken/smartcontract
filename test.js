/**
 * Proceso de MINADO a admin, PRÉSTAMO a prestatario y PAGO DE PRÉSTAMO por prestatario:
 * 
 * 1. A crédito es aprobado para un usuario. En ese momento se llama la función 'lend':
 * 
 * function lend(
        address account,
        string memory idClient,
        string memory idBusiness,
        uint256 amountCuy,
        uint256 amountFiat,
        uint256 interest
    )  public whenNotPaused onlyAdmin returns (bool);

    * Antes de llamar lend, se verifica que el que deployó el contrato sea el único que puede llamarlo. Este 'admin' (msg.sender) es registrado cuando se deploya 'owned.sol'

    2. Se usa 'mint' (dentro de 'lend') para crear tokens para 'msg.sender', es decir, la misma cuenta del 'admin' añadida anteriormente. 'mint' solo es llamada por un 'admin'.
    
    PREGUNTA: Se deberia entender que '_initialAccount' es la misma cuenta que 'msg.sender' cuando se llaman la función 'lend'?

    3. Se llama 'loanAdd' usando la cuenta del prestatario:
    function loanAdd(
        address account,
        string memory idClient,
        string memory idBusiness,
        uint256 amountCuy,
        uint256 amountFiat,
        uint256 interest
    ) internal onlyAdmin loanStatus(account, false, LOAN_NOT_PAID_CODE);

    * Esta función guarda la información del prestatario en 'debtors[account]' (mapping) usando el struct 'LoanInfo'.
    * Se observa que el prestatario no recibe ningún token.
    
    4. Se emite el evento 'Lend(account, amountCuy)'

    5. Cuando el prestatario cancelará su préstamo se llama 'Pay':
    function Pay(
        address account,
        uint256 amountFiat,
        uint256 amountCuy
    ) internal;

    PREGUNTA: la llamada a 'Pay' no está restringida para 'admin'. Es decir, cualquier cuenta lo puede llamar sin necesidad de hacer el pago. En qué lugar se verifica que el pago se hizo?
    
    'Pay'
    ** Verificar la visibilidad de la función
    ** Cuenta cuente son saldo en cuytokens

    6. 'loanPay' (llamado dentro de 'Pay') es llamado. Se entiende que puede ser llamado multiples veces porque el prestatario pagará en cuotas:

    function loanPay(
        address account,
        uint256 amountFiat,
        uint256 amountCuy
    ) internal loanStatus(account, true, LOAN_PAID_CODE);

    * Cuando se llama 'loanPay', se resta de dos balances: 'amountFiat' y 'amountCuyt':
    debtors[account].balanceFiat = debtors[account].balanceFiat - amountFiat;
    debtors[account].balanceCuy = debtors[account].balanceCuy - amountCuy;

    PREGUNTA: el 'balanceFiat' es una cantidad fija que se devolverá en su integridad a través de cuotas. Sin embargo, 'balanceCuy' no siempre tendrá el mismo precio. Por lo tanto, si al inicio se le asignan 100 tokens, puede ser que devuelva 200 tokens o 50 tokens dado que el precio del mismo ha variado. Ello podría hacer que su balance de 'balanceCuy' no llegue a ser 0. Del mismo modo se afectaría 'Burn' haciendo que no se queme la cantidad exacta de tokens tomados por el prestatario.

    PREGUNTA: 
    if (debtors[account].balanceFiat >= debtors[account].amountFiat)
    En este condicional, no se verifica que el 'balanceFiat' sea 0 para señalar que no tiene ninguna deuda. Explicar 'amountFiat' dentro de 'loanPay'. 'balanceFiat' es siempre mayor que 'amountFiat'. El condicional se hace 'true' la primera vez que lo llamas.
    ** está bien si paga más. puede haber un tema de mora

    PREGUNTA: No podría darse el caso en el que lo que se paga en fiat sea menor a lo que se debe? Si es así o bien se añade un 'require' o se le devuelve el dinero a favor.

 */

/**
 * Proceso de TRANSFERENCIA directa de tokens. De 'admin' a comprador de token.
 * 
 *  1. Se utilizará la función 'transfer' en batches para realizar la transferencia de tokens a los que compraron:
 * 
 * function transfer(address to, uint256 value)
        public
        override
        verify(msg.sender, to, value)
        whenNotPaused
        returns (bool success)
 * 
 *  PREGUNTA: dónde se registrará a los compradores: off-chain
 *  PREGUNTA: no es una función de solo admin? Es para que ellos se transfiera tokens entre ellos
 *  PREGUNTA: se asume que la cantidad de tokens es fija. Por lo tanto el precio del token se asume fija mientras se venden el primer lote de tokens? Si el precio del token cambia, se podrían necesitar más o menos tokens, los tokens de balance no serán suficientes.
 * * EL minado se hace en el momento en el que se tiene el fondeo total del préstamo
 * 
 *  * Se llama 'verify' (dentro de 'transfer') que valida que el destinatario haya sido agreagado al 'whitelist' mapping.
 * 
 *   PREGUNTA: En qué momento se añade a los destinatarios dentro del mapping 'whitelist'?
 * * NO hay whitelist
 */

/**
 * Proceso de TRANSFERENCIA del sistema y entre poseedores de tokens
 * 
 * Orden de venta. tokens no se transfieren aun. se da solamente permiso
 * 1. 'approve' es llamado por el que quiere transferir tokens. Le da el permiso a que otra cuenta, 'spender', sea el que pueda manejar sus tokens.
 * 
 * function approve(address spender, uint256 value)
        public
        override
        returns (bool);
 * 
 * 
 * 2. 'transferFrom' es llamado por aquel que se le ha permitido transferir token en nombre de otro actor. Llama esta función para dismiuir el balance de tokens del que lo permitió. Los tokens se suman al que se está enviando. El que llama el contrato tiene que ser al que se le permitió mover los tokens.
 * 
 */

/**
 * Fees?
 * incluir las funciones increaseAllowance y decreaseAllowance

 */