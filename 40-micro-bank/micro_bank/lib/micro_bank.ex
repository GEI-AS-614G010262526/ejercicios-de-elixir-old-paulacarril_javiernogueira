defmodule MicroBank do
  use GenServer

  @moduledoc """
    Servidor de micro banco que gestiona cuentas y saldos.
    
    Permite depositar, retirar y consultar saldos de cuentas de clientes.
    Cada cuenta se identifica por el nombre del cliente y almacena su saldo.
  """

  #################
  ## API Pública (Cliente)
  #################

  @doc """
    Inicia el servidor del banco.

    Registra el proceso bajo el nombre `MicroBank` y lo inicializa
    con un mapa vacío para almacenar las cuentas.

    ## Parámetros
      - `opts`: opciones de inicio (no se utilizan actualmente).

    ## Ejemplo
        iex> MicroBank.start_link([])
        {:ok, #PID<0.123.0>}
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
    Detiene el servidor del banco.

    Envía una petición síncrona para detener el servidor de forma ordenada.

    ## Ejemplo
        iex> MicroBank.stop()
        :ok
  """
  @spec stop() :: :ok
  def stop do
    GenServer.stop(__MODULE__)
  end

  @doc """
    Deposita dinero en la cuenta de un cliente.

    Si la cuenta no existe, se crea automáticamente con el saldo depositado.
    Solo se permiten cantidades positivas.

    ## Parámetros
      - `who`: nombre del cliente (string).
      - `amount`: cantidad a depositar (debe ser positiva).

    ## Retorna
      - `{:ok, new_balance}`: operación exitosa, devuelve el nuevo saldo.

    ## Ejemplo
        iex> MicroBank.deposit("Juan", 1000)
        {:ok, 1000}
  """
  @spec deposit(String.t(), number()) :: {:ok, number()}
  def deposit(who, amount) when amount > 0 do
    GenServer.call(__MODULE__, {:deposit, who, amount})
  end

  @doc """
    Consulta el saldo de la cuenta de un cliente.

    Si la cuenta no existe, devuelve 0.

    ## Parámetros
      - `who`: nombre del cliente (string).

    ## Retorna
      - `{:ok, balance}`: saldo actual de la cuenta.

    ## Ejemplo
        iex> MicroBank.ask("Juan")
        {:ok, 1500}
  """
  @spec ask(String.t()) :: {:ok, number()}
  def ask(who) do
    GenServer.call(__MODULE__, {:ask, who})
  end

  @doc """
    Retira dinero de la cuenta de un cliente.

    Solo se permite retirar si hay saldo suficiente.
    Solo se permiten cantidades positivas.

    ## Parámetros
      - `who`: nombre del cliente (string).
      - `amount`: cantidad a retirar (debe ser positiva).

    ## Retorna
      - `{:ok, new_balance}`: operación exitosa, devuelve el nuevo saldo.
      - `{:error, :insufficient_funds}`: saldo insuficiente.

    ## Ejemplo        
        iex> MicroBank.withdraw("Maria", 300)
        {:ok, 700}
  """
  @spec withdraw(String.t(), number()) :: {:ok, number()} | {:error, :insufficient_funds}
  def withdraw(who, amount) when amount > 0 do
    GenServer.call(__MODULE__, {:withdraw, who, amount})
  end

  #################
  ## Callbacks del GenServer (Servidor)
  #################

  @doc false
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @doc false
  @impl true
  def handle_call({:deposit, who, amount}, _from, state) do
    current_balance = Map.get(state, who, 0)
    new_balance = current_balance + amount
    new_state = Map.put(state, who, new_balance)
    {:reply, {:ok, new_balance}, new_state}
  end

  @doc false
  @impl true
  def handle_call({:ask, who}, _from, state) do
    balance = Map.get(state, who, 0)
    {:reply, {:ok, balance}, state}
  end

  @doc false
  @impl true
  def handle_call({:withdraw, who, amount}, _from, state) do
    current_balance = Map.get(state, who, 0)
    if current_balance >= amount do
      new_balance = current_balance - amount
      new_state = Map.put(state, who, new_balance)
      {:reply, {:ok, new_balance}, new_state}
    else
      {:reply, {:error, :insufficient_funds}, state}
    end
  end
end