# test/federated/application_test.exs
defmodule Federated.ApplicationTest do
  use ExUnit.Case, async: false

  setup do
    # Verificar que la aplicación está corriendo, si no, reiniciarla
    unless Process.whereis(Federated.Supervisor) do
      # Reiniciar la aplicación manualmente
      children = [
        {Registry, keys: :unique, name: Federated.Registry}
      ]
      opts = [strategy: :one_for_one, name: Federated.Supervisor]
      Supervisor.start_link(children, opts)
      
      # Dar tiempo a que el supervisor y registry se inicialicen completamente
      Process.sleep(100)
    end

    :ok
  end

  describe "start/2" do
    test "starts the application supervision tree" do
      supervisor_pid = Process.whereis(Federated.Supervisor)
      assert supervisor_pid != nil
      assert Process.alive?(supervisor_pid)
    end

    test "starts the Registry with correct name" do
      registry_pid = Process.whereis(Federated.Registry)
      assert registry_pid != nil
      assert Process.alive?(registry_pid)
    end

    test "Registry allows registering processes" do
      test_name = "test_process_#{:rand.uniform(100_000)}"
      
      # Registrarse desde el proceso actual
      assert {:ok, _} = Registry.register(Federated.Registry, test_name, nil)
      current_pid = self()
      
      assert [{^current_pid, nil}] = Registry.lookup(Federated.Registry, test_name)
      
      # Limpieza
      Registry.unregister(Federated.Registry, test_name)
    end

    test "Registry uses unique keys strategy" do
      test_name = "unique_test_#{:rand.uniform(100_000)}"
      
      # Registrarse desde el proceso actual
      assert {:ok, _} = Registry.register(Federated.Registry, test_name, nil)
      current_pid = self()
      
      # Intentar registrar desde otro proceso
      task = Task.async(fn ->
        Registry.register(Federated.Registry, test_name, nil)
      end)
      
      assert {:error, {:already_registered, ^current_pid}} = Task.await(task)
      
      # Limpieza
      Registry.unregister(Federated.Registry, test_name)
    end

    test "multiple processes can register with different keys" do
      key1 = "key1_#{:rand.uniform(100_000)}"
      key2 = "key2_#{:rand.uniform(100_000)}"
      
      # Proceso principal registra key1
      assert {:ok, _} = Registry.register(Federated.Registry, key1, :value1)
      
      # Dar tiempo a que el registro se complete
      Process.sleep(50)
      
      # Proceso hijo registra key2 y espera confirmación
      parent = self()
      
      task_pid = spawn(fn ->
        {:ok, _} = Registry.register(Federated.Registry, key2, :value2)
        send(parent, :registered)
        
        # Mantener el proceso vivo hasta que el test termine
        receive do
          :done -> :ok
        after
          5000 -> :ok
        end
      end)
      
      # Esperar a que se registre
      assert_receive :registered, 1000
      
      # Dar tiempo a que el registro del proceso hijo se complete
      Process.sleep(100)
      
      # Verificar que ambos están registrados
      assert [{_, :value1}] = Registry.lookup(Federated.Registry, key1)
      assert [{^task_pid, :value2}] = Registry.lookup(Federated.Registry, key2)
      
      # Limpieza
      send(task_pid, :done)
      Process.sleep(50)
      Registry.unregister(Federated.Registry, key1)
    end
  end

  describe "supervision tree" do
    test "supervisor is running" do
      supervisor_pid = Process.whereis(Federated.Supervisor)
      
      assert supervisor_pid != nil
      assert Process.alive?(supervisor_pid)
    end

    test "supervisor has Registry as child" do
      supervisor_pid = Process.whereis(Federated.Supervisor)
      
      # Obtener los hijos del supervisor
      children = Supervisor.which_children(supervisor_pid)
      
      # Verificar que Registry está en los hijos
      # Registry puede ser :worker o :supervisor dependiendo de la versión
      assert Enum.any?(children, fn
        {Registry, _pid, _type, [Registry]} -> true
        {Federated.Registry, _pid, _type, [Registry]} -> true
        _ -> false
      end)
    end

    test "Registry is configured correctly" do
      registry_pid = Process.whereis(Federated.Registry)
      
      # Verificar que el Registry existe y está vivo
      assert is_pid(registry_pid)
      assert Process.alive?(registry_pid)
      
      # Dar tiempo a que el Registry esté completamente inicializado
      Process.sleep(50)
      
      # Probar que funciona con unique keys
      key = "test_unique_#{:rand.uniform(100_000)}"
      assert {:ok, _} = Registry.register(Federated.Registry, key, nil)
      
      # Dar tiempo antes de intentar registrar de nuevo
      Process.sleep(50)
      
      assert {:error, {:already_registered, _}} = Registry.register(Federated.Registry, key, nil)
      
      Registry.unregister(Federated.Registry, key)
    end
  end

  describe "Registry functionality" do
    test "can register and unregister" do
      key = "test_key_#{:rand.uniform(100_000)}"
      
      assert {:ok, _} = Registry.register(Federated.Registry, key, :my_value)
      assert [{_, :my_value}] = Registry.lookup(Federated.Registry, key)
      
      assert :ok = Registry.unregister(Federated.Registry, key)
      assert [] = Registry.lookup(Federated.Registry, key)
    end

    test "lookup returns empty list for non-existent key" do
      key = "nonexistent_#{:rand.uniform(100_000)}"
      assert [] = Registry.lookup(Federated.Registry, key)
    end

    test "unregister removes process from registry" do
      key = "remove_test_#{:rand.uniform(100_000)}"
      
      {:ok, _} = Registry.register(Federated.Registry, key, nil)
      assert [{_, _}] = Registry.lookup(Federated.Registry, key)
      
      Registry.unregister(Federated.Registry, key)
      assert [] = Registry.lookup(Federated.Registry, key)
    end

    test "process death automatically unregisters" do
      key = "death_test_#{:rand.uniform(100_000)}"
      parent = self()
      
      # Iniciar un proceso temporal que se registra
      pid = spawn(fn ->
        Registry.register(Federated.Registry, key, :temp_value)
        send(parent, :registered)
        
        # Esperar señal para morir
        receive do
          :die -> :ok
        end
      end)
      
      # Esperar a que se registre
      assert_receive :registered, 1000
      
      # Dar tiempo a que el registro se complete
      Process.sleep(100)
      
      # Verificar que está registrado
      assert [{^pid, :temp_value}] = Registry.lookup(Federated.Registry, key)
      
      # Matar el proceso
      send(pid, :die)
      
      # Esperar a que el proceso muera y el Registry limpie la entrada
      Process.sleep(150)
      
      # Verificar que ya no está registrado
      assert [] = Registry.lookup(Federated.Registry, key)
    end
  end
end