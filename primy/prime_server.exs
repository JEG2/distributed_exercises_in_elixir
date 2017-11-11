defmodule Fermat do
  require Integer

  def mpow(n, 1, _m), do: n
  def mpow(n, k, m) when Integer.is_even(k) do
    x = mpow(n, div(k, 2), m)
    rem((x * x), m)
  end
  def mpow(n, k, m) when Integer.is_odd(k) do
    x = mpow(n, k - 1, m)
    rem((x * n), m)
  end

  def fermat(1), do: true
  def fermat(p) do
    r = :rand.uniform(p - 1)
    t = mpow(r, p - 1, p)
    t == 1
  end

  def test(_p, 0), do: true
  def test(p, n) do
    case fermat(p) do
      true  -> test(p, n - 1)
      false -> false
    end
  end
end

defmodule PrimeServer do
  use GenServer

  defstruct ~w[prime next_test]a

  def start_link(prime) do
    GenServer.start_link(__MODULE__, {prime}, name: {:global, __MODULE__})
  end

  def work do
    GenServer.call({:global, __MODULE__}, :work)
  end

  def add_prime(prime) do
    GenServer.call({:global, __MODULE__}, {:add_prime, prime})
  end

  def highest_prime do
    GenServer.call({:global, __MODULE__}, :highest_prime)
  end

  def init({prime}) do
    {:ok, %__MODULE__{prime: prime, next_test: prime + 1}}
  end

  def handle_call(:work, _from, state = %__MODULE__{next_test: next_test}) do
    {:reply, next_test, %__MODULE__{state | next_test: next_test + 1}}
  end

  def handle_call({:add_prime, new_prime}, _from, state = %__MODULE__{prime: old_prime})
  when new_prime > old_prime do
    {:reply, :ok, %__MODULE__{state | prime: new_prime, next_test: new_prime + 1}}
  end
  def handle_call({:add_prime, _new_prime}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(:highest_prime, _from, state = %__MODULE__{prime: prime}) do
    {:reply, prime, state}
  end
end

defmodule PrimeWorker do
  def run do
    Task.async(fn ->
      test(3)
    end)
  end

  defp test(tries) do
    number = PrimeServer.work

    if Fermat.test(number, tries) do
      PrimeServer.add_prime(number)
    end

    test(tries)
  end
end
